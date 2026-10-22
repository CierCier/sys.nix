#!/usr/bin/env python3
"""Warm Indra OCR for the screenshot helper: the service holds the loaded
models and reads one image per connection, so Win+T does not pay the model
load.  Framing: a 4-byte big-endian image size, then the image bytes; the
reply is "ok\\n" plus the text (like ``indra-ocr --format text``), or
"error\\n" plus the reason.  ``--request PATH`` runs the client half against
the running service; the helper falls back to the one-shot indra-ocr CLI when
the service is not reachable.
"""

from __future__ import annotations

import argparse
import os
import socket
import struct
import sys
import tempfile
import time
from pathlib import Path

MAX_IMAGE_BYTES = 64 * 1024 * 1024
SOCKET_NAME = "indra-ocr.sock"
OK = b"ok\n"
ERROR = b"error\n"


def socket_path() -> Path:
    runtime = os.environ.get("XDG_RUNTIME_DIR")
    if not runtime:
        raise RuntimeError("XDG_RUNTIME_DIR is not set")
    return Path(runtime) / SOCKET_NAME


def recv_exact(conn: socket.socket, size: int) -> bytes:
    buf = bytearray()
    while len(buf) < size:
        chunk = conn.recv(min(65536, size - len(buf)))
        if not chunk:
            raise ConnectionError("connection closed early")
        buf += chunk
    return bytes(buf)


def read_text(conv, image: bytes) -> tuple[str, float]:
    """The text one image yields, like ``indra-ocr --format text``, and the
    OCR milliseconds."""
    with tempfile.NamedTemporaryFile(suffix=".png") as tmp:
        tmp.write(image)
        tmp.flush()
        t0 = time.perf_counter()
        chunks = []
        for _, page in conv.convert(tmp.name):
            if page.source == "error":
                raise RuntimeError(page.note)
            chunks.append(page.text)
        ms = 1000 * (time.perf_counter() - t0)
    return "\n\n".join(chunks) + "\n", ms


def request(image: Path) -> int:
    """One OCR through the running service: 0 ok (text on stdout), 1 the
    service read the request and failed, 2 the service was unreachable or the
    exchange broke (the caller may fall back)."""
    try:
        data = image.read_bytes()
        target = socket_path()
    except (OSError, RuntimeError) as e:
        print(f"ocr-daemon: {e}", file=sys.stderr)
        return 2
    sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    try:
        with sock:
            sock.connect(str(target))
            sock.sendall(struct.pack(">I", len(data)) + data)
            sock.shutdown(socket.SHUT_WR)
            reply = bytearray()
            while chunk := sock.recv(65536):
                reply += chunk
    except OSError as e:
        print(f"ocr-daemon: cannot reach the service: {e}", file=sys.stderr)
        return 2
    if reply.startswith(OK):
        sys.stdout.write(bytes(reply)[len(OK):].decode("utf-8"))
        return 0
    if reply.startswith(ERROR):
        reason = bytes(reply)[len(ERROR):].decode("utf-8", "replace").strip()
        print(f"ocr-daemon: {reason}", file=sys.stderr)
        return 1
    print("ocr-daemon: empty or malformed reply from the service", file=sys.stderr)
    return 1


def serve(threads: int) -> int:
    from indra_ocr import load

    target = socket_path()
    print(f"loading the models (threads={threads})", flush=True)
    conv = load(threads=threads, mode="ocr")  # what the helper's CLI flags select
    target.unlink(missing_ok=True)
    server = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    server.bind(str(target))
    os.chmod(target, 0o600)
    server.listen(8)
    print(f"ready: {target}", flush=True)
    while True:
        conn, _ = server.accept()
        with conn:
            conn.settimeout(60)
            try:
                (size,) = struct.unpack(">I", recv_exact(conn, 4))
                if size > MAX_IMAGE_BYTES:
                    raise ValueError(f"image too large: {size} bytes")
                text, ms = read_text(conv, recv_exact(conn, size))
                reply = OK + text.encode("utf-8")
                print(f"read {len(text)} chars in {ms:.0f} ms", flush=True)
            except Exception as e:  # one bad request must not end the service
                print(f"request failed: {type(e).__name__}: {e}", file=sys.stderr, flush=True)
                reply = ERROR + f"{type(e).__name__}: {e}\n".encode("utf-8")
            try:
                conn.sendall(reply)
            except OSError as e:
                print(f"reply failed: {e}", file=sys.stderr, flush=True)


def main() -> int:
    ap = argparse.ArgumentParser(prog="ocr-daemon", description=__doc__)
    ap.add_argument(
        "--request", type=Path, metavar="IMAGE", help="OCR one image through the running service"
    )
    ap.add_argument("--threads", type=int, default=4, help="ONNX Runtime threads (default: 4)")
    a = ap.parse_args()
    if a.request:
        return request(a.request)
    return serve(a.threads)


if __name__ == "__main__":
    sys.exit(main())
