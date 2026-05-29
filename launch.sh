#!/usr/bin/env bash
# Zen Markdown Viewer launcher — Linux & macOS
# Usage: launch.sh <file>
set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: zen-markdown-viewer <file>" >&2
  exit 1
fi

arg="$1"
if [ $# -gt 1 ]; then
  arg="$*"
fi

# --- helpers -----------------------------------------------------------------

urlencode() {
  python3 - "$1" <<'PY'
import sys, urllib.parse
print(urllib.parse.quote(sys.argv[1], safe=''))
PY
}

realpath_x() {
  python3 -c "import os,sys; print(os.path.realpath(sys.argv[1]))" "$1"
}

if command -v xdg-open >/dev/null 2>&1; then
  OPEN_CMD="xdg-open"
elif command -v open >/dev/null 2>&1; then
  OPEN_CMD="open"
else
  echo "No browser opener found (expected xdg-open on Linux or open on macOS)" >&2
  exit 1
fi

# --- locate viewer -----------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

VIEWER_DIRS=()
if [ -n "${ZEN_MARKDOWN_VIEWER_DATA_DIR:-}" ]; then
  VIEWER_DIRS+=("$ZEN_MARKDOWN_VIEWER_DATA_DIR")
fi
VIEWER_DIRS+=(
  "$SCRIPT_DIR"
  "$HOME/.local/share/zen-markdown-viewer"
  "$HOME/Library/Application Support/zen-markdown-viewer"
)

VIEWER=""
for dir in "${VIEWER_DIRS[@]}"; do
  candidate="$dir/viewer.html"
  if [ -f "$candidate" ]; then
    VIEWER="$candidate"
    break
  fi
done

if [ ! -f "$VIEWER" ]; then
  echo "viewer.html not found. Checked:" >&2
  for dir in "${VIEWER_DIRS[@]}"; do echo "  $dir/viewer.html" >&2; done
  echo "Run install.sh first or launch from the repo directory." >&2
  exit 1
fi

# --- resolve file, set server root -------------------------------------------

case "$arg" in
  http://*|https://*)
    TMPDIR=$(mktemp -d /tmp/zen-md.XXXXXX) || exit 1
    cp -a "$VIEWER" "$TMPDIR/viewer.html" || { rm -rf "$TMPDIR"; exit 1; }
    if command -v curl >/dev/null 2>&1; then
      curl -L --fail --silent --show-error -o "$TMPDIR/doc.md" "$arg" \
        || { rm -rf "$TMPDIR"; exit 1; }
    elif command -v wget >/dev/null 2>&1; then
      wget -q -O "$TMPDIR/doc.md" "$arg" \
        || { rm -rf "$TMPDIR"; exit 1; }
    else
      echo "No curl or wget found" >&2; rm -rf "$TMPDIR"; exit 1
    fi
    SERVE_DIR="$TMPDIR"
    VIEWER_PATH="$TMPDIR/viewer.html"
    ENC_FILE="doc.md"
    ;;
  *)
    [ "$arg" != "${arg#file://}" ] && fp="${arg#file://}" || fp="$arg"
    fp="$(realpath_x "$fp")"
    SERVE_DIR="$(dirname "$fp")"
    VIEWER_PATH="$VIEWER"
    BASENAME="$(basename "$fp")"
    ENC_FILE=$(urlencode "$BASENAME")
    ;;
esac

# --- find a free port --------------------------------------------------------

PORT=$(python3 - <<'PY'
import socket
s = socket.socket()
s.bind(("127.0.0.1", 0))
print(s.getsockname()[1])
s.close()
PY
)

# --- start custom HTTP server ------------------------------------------------

nohup python3 - "$VIEWER_PATH" "$SERVE_DIR" "$PORT" <<'PYTHON' >/dev/null 2>&1 &
import http.server
import os
import sys
import urllib.parse

viewer_path = os.path.realpath(sys.argv[1])
serve_dir = os.path.realpath(sys.argv[2])
port = int(sys.argv[3])

class ZenHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=serve_dir, **kwargs)

    def translate_path(self, path):
        if urllib.parse.urlparse(path).path == '/.zv':
            return viewer_path
        return super().translate_path(path)

    def log_message(self, fmt, *args):
        sys.stderr.write("[zen-md] %s\n" % (fmt % args))

with http.server.HTTPServer(("127.0.0.1", port), ZenHandler) as httpd:
    httpd.serve_forever()
PYTHON

SERVER_PID=$!

# --- wait for server to be ready ---------------------------------------------

ready=0
for _ in $(seq 1 30); do
  if curl -fsS "http://127.0.0.1:$PORT/.zv" >/dev/null 2>&1; then
    ready=1; break
  fi
  sleep 0.1
done

if [ "$ready" -ne 1 ]; then
  echo "Server did not start in time" >&2
  exit 1
fi

# --- open browser ------------------------------------------------------------

URL="http://127.0.0.1:$PORT/.zv?file=$ENC_FILE"

$OPEN_CMD "$URL" >/dev/null 2>&1 &
printf 'Zen Markdown viewer: %s  (server pid %s)\n' "$URL" "$SERVER_PID" >&2
exit 0
