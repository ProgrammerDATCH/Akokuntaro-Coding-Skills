#!/usr/bin/env python3
"""Screenshot review page: show screenshots on one local page, each with what
it proves, and let David approve, ask for changes or reject each one.

    python3 shot_review.py manifest.json [--port 4777] [--open]

manifest.json:
    {
      "title": "KAB-982 PR screenshots",
      "round": 1,
      "shots": [
        {"id": "tiles", "path": "/abs/path/1.png", "title": "Dashboard tiles",
         "meaning": "Unpaid 8 / Needs info 18 open My Sessions", "status": "approved"}
      ]
    }

"status" is optional (approved | changes | rejected | pending) and pre-fills a
decision carried over from an earlier round.

Decisions are written next to the manifest as <manifest>.decisions.json on every
click, so whoever runs this reads that file. Only 127.0.0.1 is served; only the
images listed in the manifest can be downloaded.
"""
from __future__ import annotations

import argparse
import html
import io
import json
import mimetypes
import sys
import webbrowser
import zipfile
from datetime import datetime, timezone
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import unquote, urlparse

STATUSES = ("pending", "approved", "changes", "rejected")


def load_manifest(path: Path) -> dict:
    data = json.loads(path.read_text())
    shots = data.get("shots") or []
    seen: set[str] = set()
    for i, shot in enumerate(shots):
        shot.setdefault("id", str(i + 1))
        if shot["id"] in seen:
            sys.exit(f"duplicate shot id: {shot['id']}")
        seen.add(shot["id"])
        file = Path(shot["path"]).expanduser()
        if not file.is_absolute():
            file = (path.parent / file).resolve()
        if not file.is_file():
            sys.exit(f"missing image: {file}")
        shot["path"] = str(file)
        if shot.get("status") not in STATUSES:
            shot["status"] = "pending"
    data["shots"] = shots
    data.setdefault("title", "Screenshot review")
    data.setdefault("round", 1)
    return data


def decisions_path(manifest: Path) -> Path:
    return manifest.with_name(manifest.stem + ".decisions.json")


def initial_decisions(manifest: Path, data: dict) -> dict:
    """Decisions already saved for this round win over the manifest's pre-fill."""
    saved = {}
    out = decisions_path(manifest)
    if out.is_file():
        prev = json.loads(out.read_text())
        if prev.get("round") == data["round"]:
            saved = {d["id"]: d for d in prev.get("shots", [])}
    return {
        s["id"]: saved.get(s["id"], {"id": s["id"], "status": s["status"], "note": s.get("note", "")})
        for s in data["shots"]
    }


PAGE = """<!doctype html>
<html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>__TITLE__</title>
<style>
:root{--bg:#f5f5f4;--card:#fff;--text:#1c1917;--muted:#78716c;--line:#e7e5e4;
--ok:#15803d;--warn:#b45309;--err:#b91c1c;--accent:#2d5bff}
@media (prefers-color-scheme:dark){:root{--bg:#0c0a09;--card:#1c1917;--text:#f5f5f4;
--muted:#a8a29e;--line:#292524;--ok:#4ade80;--warn:#fbbf24;--err:#f87171;--accent:#7c9cff}}
*{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--text);
font:15px/1.45 system-ui,-apple-system,sans-serif}
header{position:sticky;top:0;z-index:5;background:var(--bg);border-bottom:1px solid var(--line);
padding:12px 16px;display:flex;flex-wrap:wrap;gap:8px 16px;align-items:center}
h1{font-size:17px;margin:0;flex:1 1 auto}.sum{color:var(--muted);font-size:13px}
.btn{border:1px solid var(--line);background:var(--card);color:var(--text);border-radius:8px;
padding:7px 12px;font:inherit;font-size:13px;cursor:pointer;text-decoration:none;white-space:nowrap}
.btn:hover{border-color:var(--muted)}.btn.primary{background:var(--accent);border-color:var(--accent);color:#fff}
.btn[disabled]{opacity:.45;cursor:not-allowed}
main{padding:16px;display:grid;gap:16px;grid-template-columns:repeat(auto-fill,minmax(min(100%,420px),1fr))}
.card{background:var(--card);border:2px solid var(--line);border-radius:12px;overflow:hidden;display:flex;flex-direction:column}
.card[data-status=approved]{border-color:var(--ok)}.card[data-status=changes]{border-color:var(--warn)}
.card[data-status=rejected]{border-color:var(--err)}
.shot{background:repeating-conic-gradient(var(--line) 0 25%,transparent 0 50%) 0 0/16px 16px;
display:flex;justify-content:center;max-height:520px;overflow:hidden;cursor:zoom-in}
.shot img{max-width:100%;max-height:520px;object-fit:contain;display:block}
.body{padding:12px 14px;display:flex;flex-direction:column;gap:8px;flex:1}
.n{color:var(--muted);font-size:12px}.t{font-weight:600}.m{color:var(--muted);font-size:14px}
.row{display:flex;flex-wrap:wrap;gap:6px;align-items:center;margin-top:auto}
.dec .btn[aria-pressed=true][data-v=approved]{background:var(--ok);border-color:var(--ok);color:#fff}
.dec .btn[aria-pressed=true][data-v=changes]{background:var(--warn);border-color:var(--warn);color:#fff}
.dec .btn[aria-pressed=true][data-v=rejected]{background:var(--err);border-color:var(--err);color:#fff}
textarea{width:100%;min-height:58px;border:1px solid var(--line);border-radius:8px;padding:8px;
background:var(--bg);color:var(--text);font:inherit;font-size:14px;resize:vertical}
.saved{font-size:12px;color:var(--muted)}
dialog{border:0;padding:0;background:transparent;max-width:96vw;max-height:96vh}
dialog::backdrop{background:rgba(0,0,0,.8)}dialog img{max-width:96vw;max-height:96vh;display:block}
.banner{margin:16px 16px 0;padding:12px 14px;border-radius:10px;background:var(--card);border:2px solid var(--ok);display:none}
</style></head><body>
<header><h1>__TITLE__ <span class="sum">· round __ROUND__</span></h1>
<span class="sum" id="sum"></span>
<a class="btn" href="/download/approved.zip" id="dlApproved">Download approved</a>
<a class="btn" href="/download/all.zip">Download all</a>
<button class="btn primary" id="confirm" disabled>Confirm all approved</button></header>
<div class="banner" id="banner">Confirmed. These screenshots can be used.</div>
<main id="grid"></main>
<dialog id="zoom"><img alt=""></dialog>
<script>
const SHOTS = __SHOTS__;
let DEC = __DECISIONS__;
let CONFIRMED = __CONFIRMED__;
const grid = document.getElementById('grid');
const labels = {approved:'Approve', changes:'Request change', rejected:'Reject'};
function esc(s){return String(s??'').replace(/[&<>"]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c]))}
function render(){
  grid.innerHTML = SHOTS.map((s,i)=>{const d=DEC[s.id]; return `
  <article class="card" data-status="${d.status}" id="c-${esc(s.id)}">
    <div class="shot" data-src="/img/${encodeURIComponent(s.id)}"><img loading="lazy" src="/img/${encodeURIComponent(s.id)}" alt="${esc(s.title)}"></div>
    <div class="body"><span class="n">${i+1} / ${SHOTS.length}</span>
      <span class="t">${esc(s.title)}</span><span class="m">${esc(s.meaning)}</span>
      <textarea placeholder="What should change? (optional for approve)" data-id="${esc(s.id)}" ${CONFIRMED?'disabled':''}>${esc(d.note)}</textarea>
      <div class="row dec">${Object.keys(labels).map(v=>`<button class="btn" data-id="${esc(s.id)}" data-v="${v}" aria-pressed="${d.status===v}" ${CONFIRMED?'disabled':''}>${labels[v]}</button>`).join('')}
      <a class="btn" href="/download/one/${encodeURIComponent(s.id)}">Download</a></div>
    </div></article>`}).join('');
  const c = SHOTS.map(s=>DEC[s.id].status).reduce((a,v)=>(a[v]=(a[v]||0)+1,a),{});
  document.getElementById('sum').textContent =
    `${c.approved||0} approved · ${c.changes||0} changes · ${c.rejected||0} rejected · ${c.pending||0} pending`;
  const allOk = SHOTS.every(s=>DEC[s.id].status==='approved');
  document.getElementById('confirm').disabled = CONFIRMED || !allOk;
  document.getElementById('banner').style.display = CONFIRMED ? 'block' : 'none';
}
async function save(extra={}){
  const r = await fetch('/decisions',{method:'POST',headers:{'Content-Type':'application/json'},
    body:JSON.stringify({shots:Object.values(DEC),...extra})});
  if(!r.ok) alert('Could not save: '+r.status);
}
grid.addEventListener('click',e=>{
  const b=e.target.closest('button[data-v]'); if(b){const d=DEC[b.dataset.id];
    d.status = d.status===b.dataset.v ? 'pending' : b.dataset.v; render(); save(); return;}
  const s=e.target.closest('.shot'); if(s){const z=document.getElementById('zoom');
    z.querySelector('img').src=s.dataset.src; z.showModal();}
});
grid.addEventListener('change',e=>{if(e.target.matches('textarea')){DEC[e.target.dataset.id].note=e.target.value; save();}});
document.getElementById('zoom').addEventListener('click',e=>e.currentTarget.close());
document.getElementById('confirm').addEventListener('click',async()=>{CONFIRMED=true; render(); await save({confirmed:true});});
render();
</script></body></html>"""


def make_handler(manifest: Path, data: dict, state: dict):
    shots = {s["id"]: s for s in data["shots"]}

    class Handler(BaseHTTPRequestHandler):
        def log_message(self, *_args) -> None:
            pass

        def _send(self, code: int, body: bytes, ctype: str, extra: dict | None = None) -> None:
            self.send_response(code)
            self.send_header("Content-Type", ctype)
            self.send_header("Content-Length", str(len(body)))
            self.send_header("Cache-Control", "no-store")
            for k, v in (extra or {}).items():
                self.send_header(k, v)
            self.end_headers()
            self.wfile.write(body)

        def _zip(self, ids: list[str], name: str) -> None:
            buf = io.BytesIO()
            with zipfile.ZipFile(buf, "w", zipfile.ZIP_DEFLATED) as z:
                for i in ids:
                    p = Path(shots[i]["path"])
                    z.write(p, arcname=p.name)
            self._send(200, buf.getvalue(), "application/zip",
                       {"Content-Disposition": f'attachment; filename="{name}"'})

        def do_GET(self) -> None:
            path = unquote(urlparse(self.path).path)
            if path == "/":
                page = (PAGE.replace("__TITLE__", html.escape(data["title"]))
                        .replace("__ROUND__", str(data["round"]))
                        .replace("__SHOTS__", json.dumps([
                            {"id": s["id"], "title": s.get("title", ""), "meaning": s.get("meaning", "")}
                            for s in data["shots"]]).replace("</", "<\\/"))
                        .replace("__DECISIONS__", json.dumps(state["decisions"]).replace("</", "<\\/"))
                        .replace("__CONFIRMED__", "true" if state["confirmed"] else "false"))
                return self._send(200, page.encode(), "text/html; charset=utf-8")
            if path.startswith("/img/") or path.startswith("/download/one/"):
                sid = path.rsplit("/", 1)[-1]
                if sid not in shots:
                    return self._send(404, b"not found", "text/plain")
                p = Path(shots[sid]["path"])
                extra = {"Content-Disposition": f'attachment; filename="{p.name}"'} if "/download/" in path else None
                return self._send(200, p.read_bytes(), mimetypes.guess_type(p.name)[0] or "application/octet-stream", extra)
            if path == "/download/approved.zip":
                ids = [i for i, d in state["decisions"].items() if d["status"] == "approved"]
                return self._zip(ids, "approved-screenshots.zip")
            if path == "/download/all.zip":
                return self._zip(list(shots), "screenshots.zip")
            self._send(404, b"not found", "text/plain")

        def do_POST(self) -> None:
            if urlparse(self.path).path != "/decisions":
                return self._send(404, b"not found", "text/plain")
            body = json.loads(self.rfile.read(int(self.headers.get("Content-Length", 0))) or b"{}")
            for d in body.get("shots", []):
                if d.get("id") in shots and d.get("status") in STATUSES:
                    state["decisions"][d["id"]] = {"id": d["id"], "status": d["status"], "note": str(d.get("note", ""))[:4000]}
            if body.get("confirmed") and all(d["status"] == "approved" for d in state["decisions"].values()):
                state["confirmed"] = True
            out = {
                "title": data["title"],
                "round": data["round"],
                "confirmed": state["confirmed"],
                "updatedAt": datetime.now(timezone.utc).isoformat(timespec="seconds"),
                "shots": [{**state["decisions"][s["id"]], "path": s["path"], "title": s.get("title", "")} for s in data["shots"]],
            }
            decisions_path(manifest).write_text(json.dumps(out, indent=2))
            self._send(200, b'{"ok":true}', "application/json")

    return Handler


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("manifest", type=Path)
    ap.add_argument("--port", type=int, default=4777)
    ap.add_argument("--open", action="store_true", help="open the page in the default browser")
    args = ap.parse_args()
    manifest = args.manifest.resolve()
    data = load_manifest(manifest)
    prev = decisions_path(manifest)
    confirmed = False
    if prev.is_file():
        p = json.loads(prev.read_text())
        confirmed = bool(p.get("confirmed")) and p.get("round") == data["round"]
    state = {"decisions": initial_decisions(manifest, data), "confirmed": confirmed}
    server = ThreadingHTTPServer(("127.0.0.1", args.port), make_handler(manifest, data, state))
    url = f"http://127.0.0.1:{args.port}/"
    print(f"Review page: {url}\nDecisions:   {prev}", flush=True)
    if args.open:
        webbrowser.open(url)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass


if __name__ == "__main__":
    main()
