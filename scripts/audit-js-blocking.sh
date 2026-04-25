#!/usr/bin/env bash
#
# audit-js-blocking.sh
# ────────────────────
# Fails the build if any <script> in <head> is render-blocking:
#   - External script with src= and no async/defer/type=module attribute
# Warns (does not fail) if:
#   - Inline <script> in <head> exceeds 1024 bytes (large logic in head delays paint)
#
# Allowed in head without warning:
#   - type="application/ld+json" (SEO data, never executed)
#   - type="application/json", "text/template", etc. (non-executable)
#   - Tiny inline init shims (<1024 bytes)
#   - External scripts with async or defer
#
# Run:    bash scripts/audit-js-blocking.sh
# Exits:  0 = no blockers | 1 = render-blocking script in head

set -euo pipefail

ROOT="${ROOT:-public}"
[ -d "$ROOT" ] || { echo "audit-js-blocking: $ROOT not found" >&2; exit 2; }

python3 - "$ROOT" <<'PY'
import re, sys
from pathlib import Path

root = Path(sys.argv[1])
html_files = list(root.rglob("*.html"))

head_re   = re.compile(r"<head\b[^>]*>(.*?)</head>", re.DOTALL | re.IGNORECASE)
# Match each <script ...>...</script> with its inner content (non-greedy)
script_re = re.compile(r"<script\b([^>]*)>(.*?)</script>", re.DOTALL | re.IGNORECASE)

NON_EXEC_TYPES = ("application/ld+json", "application/json", "text/template",
                  "text/html", "text/x-template")

INLINE_WARN_BYTES = 1024

errors = []
warnings = []

for html in html_files:
    text = html.read_text()
    rel = str(html.relative_to(root.parent))
    h = head_re.search(text)
    if not h: continue
    head = h.group(1)

    for m in script_re.finditer(head):
        attrs = m.group(1).lower()
        body  = m.group(2)
        has_src     = bool(re.search(r'\bsrc\s*=', attrs))
        has_async   = " async" in attrs or attrs.endswith("async") or 'async="' in attrs or "async " in attrs
        has_defer   = " defer" in attrs or attrs.endswith("defer") or 'defer="' in attrs or "defer " in attrs
        type_match  = re.search(r'\btype\s*=\s*"([^"]+)"', attrs)
        script_type = (type_match.group(1) if type_match else "").lower()
        is_module   = script_type == "module"
        is_nonexec  = script_type in NON_EXEC_TYPES

        if is_nonexec:
            continue  # inert data/template — fine

        if has_src:
            if not (has_async or has_defer or is_module):
                errors.append((rel, f"<script src=...> in <head> without async/defer/module"))
        else:
            # Inline script in head
            size = len(body.encode("utf-8"))
            if size > INLINE_WARN_BYTES:
                warnings.append((rel, f"inline <script> in <head> is {size} bytes (>{INLINE_WARN_BYTES})"))

if errors:
    print(f"audit-js-blocking: FAIL — {len(errors)} render-blocking script(s) in <head>")
    for f, msg in errors: print(f"  {f}: {msg}")
    print()
    print("Fix: add 'defer' or 'async' to the <script> tag, or move it to end of <body>.")
    sys.exit(1)

if warnings:
    print(f"audit-js-blocking: WARN — {len(warnings)} large inline script(s) in <head>")
    for f, msg in warnings: print(f"  {f}: {msg}")
    print(f"audit-js-blocking: OK — no render-blocking external scripts in <head>")
    sys.exit(0)

print(f"audit-js-blocking: OK — all scripts in <head> are non-blocking")
PY
