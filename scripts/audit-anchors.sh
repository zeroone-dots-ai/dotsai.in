#!/usr/bin/env bash
#
# audit-anchors.sh
# ────────────────
# Fails the build if any href="#X" in HTML has no matching id="X" in the same file.
# Catches typos and stale anchors after section ID renames.
#
# Skips: href="#" (no-op), href="#0" (legacy no-op pattern).
#
# Run:    bash scripts/audit-anchors.sh
# Exits:  0 = all anchors resolve | 1 = dead anchors found

set -euo pipefail

ROOT="${ROOT:-public}"
[ -d "$ROOT" ] || { echo "audit-anchors: $ROOT not found" >&2; exit 2; }

python3 - "$ROOT" <<'PY'
import re, sys
from pathlib import Path

root = Path(sys.argv[1])
html_files = list(root.rglob("*.html"))

href_re = re.compile(r'href\s*=\s*"#([^"]+)"', re.IGNORECASE)
id_re   = re.compile(r'\bid\s*=\s*"([^"]+)"', re.IGNORECASE)

dead = []  # (file, anchor)

for html in html_files:
    text = html.read_text()
    ids = set(id_re.findall(text))
    for m in href_re.finditer(text):
        anchor = m.group(1)
        if anchor in ("", "0"): continue
        if anchor not in ids:
            dead.append((str(html.relative_to(root.parent)), anchor))

if not dead:
    print(f"audit-anchors: OK — every href=#X has a matching id=X")
    sys.exit(0)

dead = sorted(set(dead))
print(f"audit-anchors: FAIL — {len(dead)} dead anchor(s)")
for f, a in dead:
    print(f"  {f}  →  href=\"#{a}\"  (no matching id=\"{a}\")")
print()
print("Fix: add id=\"X\" to the target element, or correct/remove the href.")
sys.exit(1)
PY
