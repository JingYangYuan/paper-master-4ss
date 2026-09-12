#!/usr/bin/env python3
"""One-shot local sink that receives a page's `document.cookie` string.

Used by the CNKI kns8s closed loop: the browser page cannot write files, and
copying cookies back through the agent transcript leaks session credentials
into logs. The page POSTs `document.cookie` to this loopback sink instead; the
file is written with mode 0600 and the process exits after the first accepted
payload (or on timeout).

Usage:
    python3 cookie_sink.py --out /tmp/cnki_cookie.txt
    python3 cookie_sink.py --out /tmp/cnki_cookie.txt --port 17399 --timeout 180

Page side (any backend):
    fetch('http://127.0.0.1:17399/c', {method: 'POST', body: document.cookie})

Exit codes: 0 written, 2 timeout, 3 invalid payload.
"""

from __future__ import annotations

import argparse
import json
import os
import sys
import threading
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

MAX_BYTES = 64 * 1024
DEFAULT_PORT = 17399
ALLOWED_PATH = "/c"


class Sink(BaseHTTPRequestHandler):
    server_version = "cnki-cookie-sink"
    protocol_version = "HTTP/1.1"

    def _cors(self) -> None:
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Headers", "*")
        self.send_header("Access-Control-Allow-Methods", "POST, OPTIONS")

    def do_OPTIONS(self) -> None:  # noqa: N802 (BaseHTTPRequestHandler API)
        self.send_response(204)
        self._cors()
        self.send_header("Content-Length", "0")
        self.end_headers()

    def do_POST(self) -> None:  # noqa: N802
        state = self.server.state  # type: ignore[attr-defined]
        if self.path.split("?")[0] != ALLOWED_PATH:
            self._reply(404, "not-found")
            return
        try:
            length = int(self.headers.get("Content-Length") or 0)
        except ValueError:
            self._reply(400, "bad-length")
            return
        if length <= 0 or length > MAX_BYTES:
            self._reply(400, "bad-length")
            return
        body = self.rfile.read(length).decode("utf-8", "replace")
        if "\r" in body or "\n" in body:
            state["status"] = "invalid"
            self._reply(400, "invalid")
            state["server"].shutdown()
            return
        if "=" not in body:
            state["status"] = "invalid"
            self._reply(400, "invalid")
            state["server"].shutdown()
            return
        out = Path(state["out"])
        out.parent.mkdir(parents=True, exist_ok=True)
        tmp = out.with_suffix(out.suffix + ".part")
        with open(os.open(tmp, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600), "w", encoding="utf-8") as fh:
            fh.write(body)
        tmp.replace(out)
        state["status"] = "written"
        state["bytes"] = len(body.encode("utf-8"))
        state["pairs"] = body.count("=")
        self._reply(200, "ok")
        state["server"].shutdown()

    def _reply(self, code: int, text: str) -> None:
        payload = text.encode("utf-8")
        self.send_response(code)
        self._cors()
        self.send_header("Content-Type", "text/plain; charset=utf-8")
        self.send_header("Content-Length", str(len(payload)))
        self.end_headers()
        self.wfile.write(payload)

    def log_message(self, fmt: str, *args: object) -> None:  # silence stderr noise
        return


def main() -> int:
    parser = argparse.ArgumentParser(description="接收页面 document.cookie 的一次性本地端口")
    parser.add_argument("--out", required=True, help="cookie 落盘路径（写入时权限 0600）")
    parser.add_argument("--port", type=int, default=DEFAULT_PORT)
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--timeout", type=float, default=180.0, help="等待页面 POST 的秒数")
    args = parser.parse_args()

    out = Path(args.out).expanduser()
    if out.exists():
        out.unlink()

    server = ThreadingHTTPServer((args.host, args.port), Sink)
    server.state = {  # type: ignore[attr-defined]
        "server": server,
        "out": str(out),
        "status": "timeout",
        "bytes": 0,
        "pairs": 0,
    }
    # `server.timeout` only bounds a request's socket read; the wait deadline needs
    # its own watchdog, otherwise the process would idle forever with no POST.
    watchdog = threading.Timer(args.timeout, server.shutdown)
    watchdog.daemon = True
    watchdog.start()
    print(json.dumps({"status": "listening", "url": f"http://{args.host}:{args.port}{ALLOWED_PATH}", "out": str(out)}, ensure_ascii=False), flush=True)
    try:
        server.serve_forever(poll_interval=0.2)
    except KeyboardInterrupt:
        pass
    finally:
        watchdog.cancel()
        server.server_close()

    state = server.state  # type: ignore[attr-defined]
    result = {"status": state["status"], "out": state["out"], "bytes": state["bytes"], "pairs": state["pairs"]}
    print(json.dumps(result, ensure_ascii=False), flush=True)
    if state["status"] == "written":
        return 0
    return 2 if state["status"] == "timeout" else 3


if __name__ == "__main__":
    sys.exit(main())
