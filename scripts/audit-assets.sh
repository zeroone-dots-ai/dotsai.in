#!/usr/bin/env bash
#
# audit-assets.sh
# ───────────────
# Fails the build if any local href= or src= reference in HTML points to a
# file/directory that doesn't exist on disk in public/.
#
# Skips: http(s)://, mailto:, tel:, data:, javascript:, and bare "#".
# Strips: query strings (?v=2) and hash fragments (style.css#x) before checking.
# Directory refs (/case-studies/) match either a directory or an index.html.
#
# Run:    bash scripts/audit-assets.sh
# Exits:  0 = all refs resolve | 1 = missing assets

set -euo pipefail

ROOT="${ROOT:-public}"
[ -d "$ROOT" ] || { echo "audit-assets: $ROOT not found" >&2; exit 2; }

python3 - "$ROOT" <<'PY'
import os, re, sys
from pathlib import Path

root = Path(sys.argv[1])
html_files = list(root.rglob("*.html"))
if not html_files:
    print("audit-assets: no HTML files found"); sys.exit(0)

# Patterns to skip — external, non-file, or in-page anchors
SKIP_PREFIXES = ("http://", "https://", "//", "mailto:", "tel:", "data:", "javascript:")

# Pull href= and src= values from each HTML file
attr_re = re.compile(r'(?:href|src)\s*=\s*"([^"]+)"', re.IGNORECASE)

missing = []  # list of (file, ref)

for html in html_files:
    text = html.read_text()
    for m in attr_re.finditer(text):
        ref = m.group(1).strip()
        if not ref or ref.startswith("#"): continue
        if ref.startswith(SKIP_PREFIXES): continue

        # Strip query string and fragment
        clean = ref.split("?", 1)[0].split("#", 1)[0]
        if not clean: continue

        # Resolve relative to public/ root (./ and / both anchor at root for our static site)
        rel = clean.lstrip("./").lstrip("/")
        target = root / rel

        # Directory references — match the dir or the dir/index.html
        if clean.endswith("/"):
            if target.is_dir() or (target / "index.html").is_file(): continue
            missing.append((str(html.relative_to(root.parent)), ref)); continue

        if target.exists(): continue

        # Try as directory + index.html (handles /case-studies without trailing slash)
        if target.is_dir() or (target.parent / target.name / "index.html").is_file(): continue

        missing.append((str(html.relative_to(root.parent)), ref))

if not missing:
    print(f"audit-assets: OK — all local references resolve in {root}/")
    sys.exit(0)

# Dedupe and sort
missing = sorted(set(missing))
print(f"audit-assets: FAIL — {len(missing)} missing reference(s)")
for f, r in missing:
    print(f"  {f}  →  {r}")
print()
print("Fix: add the missing file(s) to public/, or remove/correct the reference.")
sys.exit(1)
PY
