# AGENT OPERATING GUIDE

## Purpose
Zen Markdown Viewer is a local, keyboard-centric markdown viewer built from a single viewer page plus a lightweight launcher script.
The layout is intentionally minimal so agents should avoid introducing complex build chains or unnecessary dependencies.
This guide keeps attention on viewer.html's HTML, CSS, and embedded JavaScript as the primary editing surface.
Treat the README as the narrative for humans; the AGENTS file is for future agents that need practical guardrails.

## Workspace layout
viewer.html is the single UI entry point and holds the CSS, DOM skeleton, and event wiring for the viewer.
README.md is the orientation reference; keep it up to date with any workflow changes you introduce.
The launcher helper lives outside git but the README describes how to install it under ~/.local/bin/zen-markdown-viewer.
Any new assets should live in a dedicated folder (suggested: vendor/ or assets/) so the repo stays organized.
Support files generated during runtime live in /tmp and must never be committed back into this repository.

## Commands
- Nix package: `nix run . -- test.md` or `nix develop` for a dev shell with python3/curl.
- Start the local HTTP preview server: `python3 -m http.server 8000 --bind 127.0.0.1` from the repo root.
- Use the launcher for integration: `./launch.sh /path/to/file.md` from the repo root.
- Reload the viewer via `xdg-open http://127.0.0.1:8000/viewer.html?file=test.md` when testing manual tweaks.
- There is no build or lint pipeline, so keep tooling lightweight and document any new scripts you add.
- Install as default md handler: `./install.sh` from the repo root.

## Single-test flow
- Run `python3 -m http.server 8765 --bind 127.0.0.1` so the repo is served locally.
- Open a browser and hit `http://127.0.0.1:8765/viewer.html?file=test.md`.
- Verify the page renders: headings, text formatting, code blocks, tables, blockquotes.
- Verify KaTeX math renders both inline ($...$) and display ($$...$$) correctly.
- Verify Mermaid diagrams render (flowcharts, sequence diagrams, gantt).
- Verify checkboxes render with styled appearance.
- Test keyboard shortcuts: g/G for scroll, j/k for direction, Tab for heading nav, Space for TOC.
- Test b key toggles background transparency, t key toggles text color.
- Wait 3+ seconds and confirm auto-refresh shows "Loaded" in the status indicator.
- Watch for console errors related to CDN fetch or library loading.
- This flow counts as the single automated-ish test; capture any flakiness you see in the README.

## JavaScript style guidelines
- Prefer `const` for variables that never reassign and `let` for values that do; avoid `var` entirely.
- Wrap helper functions in the IIFE scope that already wraps the entire viewer.
- Keep indentation at two spaces.
- Avoid module bundlers; keep the code inside viewer.html as a single script tag.
- Use descriptive names for state keys and keep the `state` object centralized.
- Minimize DOM queries by caching frequently used elements.

## CSS and layout guidelines
- Keep the global theme embedded in `<style>` so the viewer remains a single-file experience.
- Use `:root` and body styles sparingly to preserve the transparent background.
- Favor `display:flex` or CSS grid for adaptive layouts.
- Round borders subtly (6px) per existing styles.
- Use backdrop-filter and rgba for overlay depth, but be conservative to keep performance sane.

## Naming conventions
- lowerCamelCase for functions and variables.
- CSS class names follow kebab-case.
- IDs should clearly map to singletons.
- Constants use camelCase and should be grouped near the top of the script.

## Error handling and logging
- Wrap remote operations (fetch, CDN calls) in try/catch and show user-facing messages.
- When catching exceptions, log to the console only once so devtools stay readable.
- Guard optional APIs before calling them.
- Avoid swallowing errors silently; if you must ignore an exception, add a short comment explaining why.

## Math rendering notes
- Inline math `$...$` and display math `$$...$$` are pre-processed before marked.js parses the document.
- Code blocks are temporarily extracted and restored around math processing to prevent false matches.
- If KaTeX CDN fails, math blocks fall back to plain pre/code elements.

## Mermaid rendering notes
- Code blocks with language "mermaid" are replaced with `<div class="mermaid">` after marked parsing.
- Mermaid is initialized with a dark theme matching the GitHub Dark syntax highlighting.
- If mermaid CDN fails, the original code blocks remain visible.

## Final notes
Respect the minimal layout and keyboard-first ethos; when you add UI, keep it inline and consistent with the aesthetic.
Before submitting changes, re-run the single-test flow described above and update README/AGENTS accordingly.
