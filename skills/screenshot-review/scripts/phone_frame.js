// Phone-frame capture: run in the browser tab of the app itself (same origin, so the
// signed-in session carries into the frames). Replaces the page with one or more phones
// side by side, each loading a path of the app at 390px wide, with a caption above.
// Then screenshot or zoom the region: every mobile shot goes out in a phone frame.
//
//   window.PHONES = [{ path: '/rw/console/me?org=kabisa', label: 'My Work · Operator' }]
//
// Set PHONES, then paste this file. Give the frames ~8–10 s to load before capturing.
(() => {
  const PHONES = window.PHONES || [{ path: location.pathname + location.search, label: '' }];
  const W = 390, H = 844, BEZEL = 12, STATUS = 44, HOME = 22;
  const css = `
    body{margin:0;background:#e7e5e4;font:600 13px system-ui,sans-serif;color:#1c1917}
    .row{display:flex;gap:36px;padding:24px 28px;align-items:flex-start;flex-wrap:wrap}
    .cap{width:${W + BEZEL * 2}px;margin:0 0 10px;text-align:center;min-height:18px}
    .phone{width:${W}px;height:${H}px;padding:${BEZEL}px;border-radius:54px;background:#111;
      box-shadow:0 0 0 2px #3f3f46,0 16px 36px rgba(0,0,0,.22)}
    .screen{width:100%;height:100%;border-radius:${54 - BEZEL}px;overflow:hidden;background:#fff;
      display:flex;flex-direction:column}
    .status{height:${STATUS}px;flex:none;display:flex;align-items:center;justify-content:space-between;
      padding:0 30px;font:600 15px system-ui,sans-serif;color:#000;background:#fff;position:relative}
    .status i{position:absolute;left:50%;top:10px;transform:translateX(-50%);width:108px;height:30px;
      border-radius:20px;background:#000}
    .status b{font-weight:600;letter-spacing:-.01em}
    iframe{border:0;width:${W}px;flex:1;display:block}
    .home{height:${HOME}px;flex:none;display:flex;align-items:center;justify-content:center;background:#fff}
    .home span{width:130px;height:5px;border-radius:3px;background:#111}`;
  document.head.innerHTML = `<meta name="viewport" content="width=device-width"><style>${css}</style>`;
  const esc = (s) => String(s || '').replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));
  document.body.innerHTML = `<div class="row">${PHONES.map((p, i) => `
    <div><p class="cap">${esc(p.label)}</p><div class="phone"><div class="screen">
      <div class="status"><b>9:41</b><i></i><b>●●● ▮</b></div>
      <iframe id="phone${i}" src="${esc(p.path)}"></iframe>
      <div class="home"><span></span></div></div></div></div>`).join('')}</div>`;
  return `${PHONES.length} phone(s); app area ${W}x${H - BEZEL * 2 - STATUS - HOME}`;
})();
