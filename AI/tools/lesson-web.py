#!/usr/bin/env python3
"""Daily lesson, in the browser: read it, answer Track B, watch Track A tick over.

Deliberately not a database. The 09:00 loop run grades by reading the lesson
markdown's "My answer" block and rustlings' own state file, so those two files
stay the only source of truth -- this page is a view over them that can write
one block back. A SQLite copy would be a second truth the loop can't see.

  python3 lesson-web.py [--port 7331] [--open]

ponytail: pandoc does the markdown (already installed); stdlib does the rest.
"""
import argparse
import html
import json
import os
import re
import subprocess
import sys
import webbrowser
from datetime import date
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from secrets import token_urlsafe

# ponytail: out of ~/Documents on purpose — macOS TCC blocks launchd-run
# processes there, which is what killed the 2026-08-03 lesson run (EPERM).
ROOT = Path("/Users/tamnm/code/personal")
LESSONS = ROOT / "loopany/daily-lesson/lessons"
STATE = ROOT / "rustlings/.rustlings-state.txt"
TOTAL = 94

# Anything with a body must carry this, so a random page in another tab can't
# POST over today's answer. Regenerated every server start.
CSRF = token_urlsafe(16)

ANSWER_RE = re.compile(r"(^#{2,3} My answer\s*\n)(.*?)(?=^#{1,3} )", re.S | re.M)
PLACEHOLDER = "<!-- write here -->"


def lesson_path():
    today = LESSONS / f"{date.today():%Y-%m-%d}.md"
    if today.exists():
        return today
    files = sorted(LESSONS.glob("*.md"))
    return files[-1] if files else None


def read_answer(text):
    m = ANSWER_RE.search(text)
    if not m:
        return ""
    return m.group(2).replace(PLACEHOLDER, "").strip()


def write_answer(path, answer):
    text = path.read_text()
    if not ANSWER_RE.search(text):
        return False
    body = answer.strip() or PLACEHOLDER
    path.write_text(ANSWER_RE.sub(lambda m: f"{m.group(1)}\n{body}\n\n", text, count=1))
    return True


def rustlings_status(lesson_text):
    """Current exercise + done list, straight from rustlings' own state file."""
    try:
        names = [l.strip() for l in STATE.read_text().splitlines() if l.strip()][1:]
    except OSError:
        return {"ok": False, "current": None, "done": 0, "total": TOTAL, "target": None,
                "target_done": False}
    current, done = (names[0] if names else None), names[1:]
    # The lesson always names its exercise in a `rustlings run <name>` line.
    m = re.search(r"rustlings run (\w+)", lesson_text or "")
    target = m.group(1) if m else None
    return {"ok": True, "current": current, "done": len(done), "total": TOTAL,
            "target": target, "target_done": bool(target and target in done)}


def render(md):
    """Markdown -> HTML. Raw <details> passes through, so the worked answer
    stays collapsed -- the one thing the terminal version couldn't do."""
    try:
        r = subprocess.run(["pandoc", "-f", "gfm", "-t", "html"], input=md,
                           capture_output=True, text=True, timeout=20)
        if r.returncode == 0:
            return r.stdout
        body = r.stderr
    except (OSError, subprocess.SubprocessError) as e:
        body = str(e)
    return f"<pre>{html.escape(md)}</pre><p style='color:#c00'>pandoc failed: {html.escape(body)}</p>"


CSS = """
:root{--bg:#fbfaf8;--fg:#1c1a17;--dim:#6b6560;--line:#e6e1da;--card:#fff;--accent:#c2410c}
@media(prefers-color-scheme:dark){:root{--bg:#16151a;--fg:#e9e6e1;--dim:#948d85;--line:#2d2b33;--card:#1e1d24;--accent:#fb923c}}
*{box-sizing:border-box}
body{margin:0;background:var(--bg);color:var(--fg);font:16px/1.65 ui-sans-serif,-apple-system,Segoe UI,sans-serif}
.wrap{max-width:760px;margin:0 auto;padding:32px 22px 96px}
h1{font-size:22px;margin:0 0 2px}
.sub{color:var(--dim);font-size:13px;margin:0 0 22px}
.cards{display:flex;gap:10px;flex-wrap:wrap;margin:0 0 28px}
.card{flex:1;min-width:150px;border:1px solid var(--line);border-radius:12px;padding:12px 14px;background:var(--card)}
.k{font-size:10px;letter-spacing:.08em;text-transform:uppercase;color:var(--dim)}
.v{font-size:19px;font-weight:650;margin-top:3px}
.bar{height:5px;border-radius:3px;background:var(--line);margin-top:9px;overflow:hidden}
.bar>i{display:block;height:100%;background:var(--accent);transition:width .4s}
.lesson{border-top:1px solid var(--line);padding-top:24px}
.lesson h1{font-size:20px;margin:28px 0 8px}
.lesson h2{font-size:17px;margin:30px 0 8px;padding-bottom:5px;border-bottom:1px solid var(--line)}
.lesson h3{font-size:14px;margin:22px 0 6px;color:var(--dim);letter-spacing:.03em;text-transform:uppercase}
.lesson pre{background:var(--card);border:1px solid var(--line);border-radius:9px;padding:12px 14px;overflow-x:auto;font-size:13px}
.lesson code{font-size:.9em;background:var(--card);border:1px solid var(--line);border-radius:4px;padding:1px 4px}
.lesson pre code{border:0;background:0;padding:0}
.lesson table{border-collapse:collapse;width:100%;font-size:14px;display:block;overflow-x:auto}
.lesson td,.lesson th{border:1px solid var(--line);padding:6px 10px;text-align:left}
.lesson blockquote{margin:0;padding:2px 16px;border-left:3px solid var(--accent);color:var(--dim)}
.lesson details{border:1px solid var(--line);border-radius:9px;padding:10px 14px;margin:14px 0;background:var(--card)}
.lesson summary{cursor:pointer;font-weight:600;font-size:14px}
.lesson hr{border:0;border-top:1px solid var(--line);margin:34px 0}
.answer{position:sticky;bottom:0;background:var(--bg);border-top:1px solid var(--line);padding:14px 0 18px;margin-top:30px}
textarea{width:100%;min-height:120px;padding:12px 14px;border:1px solid var(--line);border-radius:10px;
  background:var(--card);color:var(--fg);font:14px/1.6 ui-monospace,SFMono-Regular,monospace;resize:vertical}
textarea:focus{outline:2px solid var(--accent);outline-offset:-1px}
.row{display:flex;align-items:center;gap:12px;margin-top:9px}
button{background:var(--accent);color:#fff;border:0;border-radius:8px;padding:8px 18px;font-size:14px;font-weight:600;cursor:pointer}
button:disabled{opacity:.45;cursor:default}
.saved{font-size:13px;color:var(--dim)}
"""

JS = """
const $=s=>document.querySelector(s);
let dirty=false, tid=null;
const ta=$('#a'), btn=$('#save'), note=$('#note');
ta.addEventListener('input',()=>{dirty=true;btn.disabled=false;note.textContent='unsaved';
  clearTimeout(tid);tid=setTimeout(save,1500);});
async function save(){
  if(!dirty) return;
  btn.disabled=true; note.textContent='saving…';
  const r=await fetch('/answer',{method:'POST',headers:{'Content-Type':'application/json'},
    body:JSON.stringify({token:TOKEN,answer:ta.value})});
  if(r.ok){dirty=false;note.textContent='saved to the lesson file';}
  else{note.textContent='save failed';btn.disabled=false;}
}
btn.addEventListener('click',save);
addEventListener('beforeunload',e=>{if(dirty){e.preventDefault();e.returnValue='';}});
// Track A ticks over when rustlings passes it in your editor -- poll, don't reload,
// so whatever is half-typed in the answer box survives.
setInterval(async()=>{
  const s=await (await fetch('/status')).json();
  $('#ra').textContent=s.target_done?'done ✅':(s.target||s.current||'—');
  $('#rd').textContent=s.done; $('#rb').style.width=(100*s.done/s.total)+'%';
},5000);
"""


def page(path):
    md = path.read_text()
    st = rustlings_status(md)
    front = re.match(r"^---\n(.*?)\n---\n", md, re.S)
    title = "Daily lesson"
    if front:
        t = re.search(r'^title:\s*"?(.*?)"?\s*$', front.group(1), re.M)
        if t:
            title = t.group(1)
        md = md[front.end():]
    # The answer box owns that block, so don't render a second copy of it above.
    md = ANSWER_RE.sub(lambda m: "", md, count=1)

    pct = 100 * st["done"] / st["total"]
    trk_a = "done ✅" if st["target_done"] else (st["target"] or st["current"] or "—")
    return f"""<!doctype html><html><head><meta charset=utf-8>
<meta name=viewport content="width=device-width,initial-scale=1">
<title>{html.escape(title)}</title><style>{CSS}</style></head><body><div class=wrap>
<h1>{html.escape(title)}</h1>
<p class=sub>{path.stem} &middot; Track A ~8 min &middot; Track B ~7 min</p>
<div class=cards>
  <div class=card><div class=k>Track A &middot; next exercise</div><div class=v id=ra>{html.escape(trk_a)}</div>
    <div class=bar><i id=rb style="width:{pct:.1f}%"></i></div>
    <div class=k style="margin-top:6px"><span id=rd>{st['done']}</span> / {st['total']} rustlings done</div></div>
  <div class=card><div class=k>Track B &middot; answer</div><div class=v>write it below</div>
    <div class=k style="margin-top:14px">graded by tomorrow's 09:00 run</div></div>
</div>
<div class=lesson>{render(md)}</div>
<div class=answer>
  <div class=k>My answer &mdash; Track B</div>
  <textarea id=a placeholder="One line per question: the Big-O, and in a few words why.">{html.escape(read_answer(path.read_text()))}</textarea>
  <div class=row><button id=save disabled>Save</button><span class=saved id=note>saved to the lesson file</span></div>
</div>
</div><script>const TOKEN={json.dumps(CSRF)};{JS}</script></body></html>"""


class Handler(BaseHTTPRequestHandler):
    def _send(self, code, body, ctype="text/html; charset=utf-8"):
        b = body.encode()
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(b)))
        self.end_headers()
        self.wfile.write(b)

    def do_GET(self):
        path = lesson_path()
        if self.path == "/status":
            md = path.read_text() if path else ""
            return self._send(200, json.dumps(rustlings_status(md)), "application/json")
        if self.path != "/":
            return self._send(404, "not found", "text/plain")
        if not path:
            return self._send(200, f"<p>No lesson files in {LESSONS}</p>")
        self._send(200, page(path))

    def do_POST(self):
        if self.path != "/answer":
            return self._send(404, "not found", "text/plain")
        try:
            n = int(self.headers.get("Content-Length", 0))
            data = json.loads(self.rfile.read(n) or b"{}")
        except (ValueError, OSError):
            return self._send(400, "bad request", "text/plain")
        # Local page only: a drive-by POST from another origin won't know the token.
        if data.get("token") != CSRF:
            return self._send(403, "forbidden", "text/plain")
        answer = data.get("answer", "")
        if not isinstance(answer, str) or len(answer) > 20000:
            return self._send(400, "bad answer", "text/plain")
        path = lesson_path()
        if not path or not write_answer(path, answer):
            return self._send(500, "no My answer block to write into", "text/plain")
        self._send(200, json.dumps({"ok": True}), "application/json")

    def log_message(self, *a):
        pass


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--port", type=int, default=7331)
    ap.add_argument("--open", action="store_true", help="open a browser at startup")
    args = ap.parse_args()
    url = f"http://127.0.0.1:{args.port}/"
    try:
        srv = ThreadingHTTPServer(("127.0.0.1", args.port), Handler)
    except OSError:
        # Already serving (the 09:00 run is idempotent) -- just surface the page.
        if args.open:
            webbrowser.open(url)
        print(f"already running at {url}", file=sys.stderr)
        return 0
    print(f"lesson at {url}", file=sys.stderr)
    if args.open:
        webbrowser.open(url)
    try:
        srv.serve_forever()
    except KeyboardInterrupt:
        pass
    return 0


if __name__ == "__main__":
    sys.exit(main())
