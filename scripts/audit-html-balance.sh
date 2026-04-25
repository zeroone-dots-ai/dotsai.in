#!/usr/bin/env bash
#
# audit-html-balance.sh
# ─────────────────────
# Fails the build if structural HTML tags don't balance (open count != close count).
# Catches the kind of bug where a section move accidentally drops a </div>.
#
# Checks: section, div, article, nav, header, footer, ul, ol, li, button, dialog,
#         template, details, summary, table, tr, td.
# Skips void elements (img, br, input, etc.) — they don't have closers.
# Strips HTML comments before counting (so commented-out tags don't count).
#
# Run:    bash scripts/audit-html-balance.sh
# Exits:  0 = balanced | 1 = imbalance found

set -euo pipefail

ROOT="${ROOT:-public}"
[ -d "$ROOT" ] || { echo "audit-html-balance: $ROOT not found" >&2; exit 2; }

python3 - "$ROOT" <<'PY'
import re, sys
from pathlib import Path

root = Path(sys.argv[1])
html_files = list(root.rglob("*.html"))

TAGS = ["section","div","article","nav","header","footer","ul","ol","li",
        "button","dialog","template","details","summary","table","tr","td"]

comment_re = re.compile(r"<!--.*?-->", re.DOTALL)
# Strip <script> and <style> blocks too — their content (JS/CSS) often contains
# "<dialog>"/"<details>" inside string literals or /* comments */ that would
# otherwise produce false positives in tag counts.
script_re  = re.compile(r"<script\b[^>]*>.*?</script>", re.DOTALL | re.IGNORECASE)
style_re   = re.compile(r"<style\b[^>]*>.*?</style>",   re.DOTALL | re.IGNORECASE)

failed = False
for html in html_files:
    text = html.read_text()
    text = comment_re.sub("", text)
    text = script_re.sub("", text)
    text = style_re.sub("", text)

    rel = str(html.relative_to(root.parent))
    file_failed = False

    for tag in TAGS:
        opens  = len(re.findall(rf"<{tag}\b", text, re.IGNORECASE))
        closes = len(re.findall(rf"</{tag}\s*>", text, re.IGNORECASE))
        if opens != closes:
            if not file_failed:
                print(f"audit-html-balance: FAIL — {rel}")
                file_failed = True
                failed = True
            print(f"  <{tag}>: {opens} open, {closes} close  (delta {opens-closes:+d})")

if failed:
    print()
    print("Fix: find the missing or extra closing tag. Often caused by a copy/paste")
    print("section move that didn't include the trailing </section>.")
    sys.exit(1)

print(f"audit-html-balance: OK — all major tags balanced in {len(html_files)} file(s)")
PY
