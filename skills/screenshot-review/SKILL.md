---
name: screenshot-review
description: >-
  Akokuntaro Coding Skills — show David screenshots for approval on one local web page. Use whenever
  screenshots, GIFs or recordings are prepared for a PR, a Slack QA proof post, a ticket or a
  report and need his yes before they are used: each image with what it proves, Approve / Request
  change / Reject per image with a note, download one or all approved, and a Confirm step. His
  decisions land in a JSON file you read back. Works in any project.
---

# Screenshot review page

Never paste a batch of screenshots into chat for approval. Put them on the review page, give
David the link, and read his decisions from the file. Nothing is used (PR, Slack, ticket) until
the round is **confirmed**.

## 1. Write a manifest

One JSON file per batch, in the session scratchpad (never inside a repo):

```json
{
  "title": "KAB-982 PR screenshots",
  "round": 1,
  "shots": [
    { "id": "tiles", "path": "/abs/path/1-tiles.jpg",
      "title": "Operator Dashboard: Unpaid and Needs info tiles",
      "meaning": "Unpaid 8 and Needs info 18 match the lists they open" }
  ]
}
```

- `title`: what the screen is. `meaning`: what this shot proves, in one plain sentence.
- Name image files by what they show (`3-needs-info-tab-390.png`), not by timestamp.
- Before adding a shot, hide or blur anything personal (emails, phones, a real location).

## 2. Serve it

```bash
python3 ~/.claude/skills/screenshot-review/scripts/shot_review.py /path/manifest.json --port 4777
```

Run it in the background. It serves 127.0.0.1 only and prints the page link and the decisions file
(`<manifest>.decisions.json`, next to the manifest). Give David the link
`http://127.0.0.1:4777/` and stop; don't wait in a loop. If 4777 is taken, use another port.

On the page he can, per image: Approve, Request change (with a note), Reject, Download, and click
to zoom. At the top: Download approved (zip), Download all (zip), and **Confirm all approved**,
which only works once every shot is approved. Every click is saved to the decisions file.

## 3. Read the decisions and do the next round

When David says he has reviewed, read `<manifest>.decisions.json`:

- `approved`: keep the image unchanged.
- `changes`: redo the shot as the note says.
- `rejected`: drop it, unless the note asks for a replacement.

Then write the next manifest: same ids, `round` + 1, new paths for redone shots, and
`"status": "approved"` on the ones he already approved, so he only looks at what changed. Serve it
again and send the link. Repeat until `"confirmed": true`.

## 4. Use them

Only after `"confirmed": true`:
- PRs: GitHub's CLI can't upload images, so give David the approved files (Download approved, or
  `SendUserFile`) to drop into the PR's Screenshots section, or attach them where a tool allows it.
- Slack QA proof (gokabisa-habits): David posts the approved images in the project channel.

Stop the server when the round is confirmed.
