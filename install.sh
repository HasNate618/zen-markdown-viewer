#!/usr/bin/env bash
# Install Zen Markdown Viewer as the default .md handler
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DOC_DIR="${XDG_DATA_HOME:-$HOME/.local/share}"
BIN_DIR="${XDG_BIN_HOME:-$HOME/.local/bin}"
APP_DIR="$DOC_DIR/applications"
MIME_DIR="$DOC_DIR/mime/packages"

# --- copy viewer for offline access ---
VIEWER_DIR="$DOC_DIR/zen-markdown-viewer"
mkdir -p "$VIEWER_DIR"
cp "$SCRIPT_DIR/viewer.html" "$VIEWER_DIR/"
echo "Installed viewer to $VIEWER_DIR/viewer.html"

# --- install launcher ---
mkdir -p "$BIN_DIR"
cp "$SCRIPT_DIR/launch.sh" "$BIN_DIR/zen-markdown-viewer"
chmod +x "$BIN_DIR/zen-markdown-viewer"
echo "Installed launcher to $BIN_DIR/zen-markdown-viewer"

# --- ensure .md is recognised as text/markdown ---
mkdir -p "$MIME_DIR"
cat > "$MIME_DIR/zen-markdown-viewer.xml" << XEOF
<?xml version="1.0" encoding="UTF-8"?>
<mime-info xmlns="http://www.freedesktop.org/standards/shared-mime-info">
  <mime-type type="text/markdown">
    <comment>Markdown document</comment>
    <glob pattern="*.md"/>
    <glob pattern="*.markdown"/>
  </mime-type>
</mime-info>
XEOF

# --- desktop entry ---
mkdir -p "$APP_DIR"
cat > "$APP_DIR/zen-markdown-viewer.desktop" << XEOF
[Desktop Entry]
Name=Zen Markdown Viewer
Exec=$BIN_DIR/zen-markdown-viewer %f
Terminal=false
Type=Application
MimeType=text/markdown;text/x-markdown;
Categories=Utility;TextEditor;
StartupNotify=false
XEOF

echo "Created desktop entry: $APP_DIR/zen-markdown-viewer.desktop"

# --- update MIME and desktop databases ---
if command -v update-mime-database >/dev/null 2>&1; then
  update-mime-database "$DOC_DIR/mime" 2>/dev/null || true
fi

for mime in text/markdown text/x-markdown; do
  if command -v xdg-mime >/dev/null 2>&1; then
    xdg-mime default zen-markdown-viewer.desktop "$mime" 2>/dev/null || true
  fi
done

if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database "$APP_DIR" 2>/dev/null || true
fi

echo ""
echo "Registered as default handler for .md files."
echo "Test it:  zen-markdown-viewer $SCRIPT_DIR/test.md"
