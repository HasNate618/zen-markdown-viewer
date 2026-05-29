{
  lib,
  stdenv,
  python3,
  curl,
  xdg-utils,
  makeWrapper,
  src,
  version ? "unstable",
}:

let
  runtimeInputs =
    with lib;
    [ python3 curl ]
    ++ optional stdenv.isLinux xdg-utils;
in

stdenv.mkDerivation {
  pname = "zen-markdown-viewer";
  inherit version src;

  nativeBuildInputs = [ makeWrapper ];

  buildInputs = runtimeInputs;

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/share/zen-markdown-viewer" "$out/bin"
    cp viewer.html "$out/share/zen-markdown-viewer/"
    cp launch.sh "$out/bin/zen-markdown-viewer"
    chmod +x "$out/bin/zen-markdown-viewer"

    wrapProgram "$out/bin/zen-markdown-viewer" \
      --set ZEN_MARKDOWN_VIEWER_DATA_DIR "$out/share/zen-markdown-viewer" \
      --prefix PATH : ${lib.makeBinPath runtimeInputs}

    # Desktop entry (Linux)
    mkdir -p "$out/share/applications"
    cat > "$out/share/applications/zen-markdown-viewer.desktop" <<EOF
[Desktop Entry]
Name=Zen Markdown Viewer
Exec=$out/bin/zen-markdown-viewer %f
Terminal=false
Type=Application
MimeType=text/markdown;text/x-markdown;
Categories=Utility;TextEditor;Viewer;
EOF

    runHook postInstall
  '';

  meta = with lib; {
    description = "Keyboard-first markdown viewer with Mermaid, KaTeX, and syntax highlighting";
    homepage = "https://github.com/HasNate618/zen-markdown-viewer";
    license = licenses.free;
    platforms = platforms.unix;
    mainProgram = "zen-markdown-viewer";
  };
}
