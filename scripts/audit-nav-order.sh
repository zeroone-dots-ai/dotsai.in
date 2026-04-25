#!/usr/bin/env bash
#
# audit-nav-order.sh
# ──────────────────
# Enforces invariant: <a class="nav-link" href="#X"> declaration order in the
# .nav-pill must match the on-page scroll order of <section id="X"> targets.
#
# Why: the .nav-pill-indicator slides between adjacent <a> elements based on
# scroll position. If nav declaration order drifts from section scroll order,
# the indicator jumps backwards and the active-link state desyncs from where
# the user actually is on the page — silent UX bug, no console error, no
# layout shift, just broken trust.
#
# Run:    bash scripts/audit-nav-order.sh
# Exits:  0 = order matches | 1 = mismatch (with diff)
#
# Wired into .github/workflows/deploy.yml — fails the build on mismatch
# so this class of bug cannot reach production again.
#

set -euo pipefail

FILE="${1:-public/index.html}"
[ -f "$FILE" ] || { echo "audit-nav-order: $FILE not found" >&2; exit 2; }

# Extract nav-link href targets in declaration order
nav_order() {
  python3 - "$FILE" <<'PY'
import re, sys
t = open(sys.argv[1]).read()
# Capture only links inside the .nav-pill block
m = re.search(r'<div class="nav-pill"[^>]*>(.*?)</div>', t, re.DOTALL)
if not m:
    sys.stderr.write("audit-nav-order: .nav-pill block not found\n"); sys.exit(2)
hrefs = re.findall(r'class="nav-link"\s+href="#([a-zA-Z0-9_-]+)"', m.group(1))
print("\n".join(hrefs))
PY
}

# Extract <section id="..."> values in document (scroll) order
section_order() {
  python3 - "$FILE" <<'PY'
import re, sys
t = open(sys.argv[1]).read()
ids = re.findall(r'<section[^>]+\bid="([a-zA-Z0-9_-]+)"', t)
print("\n".join(ids))
PY
}

NAV=$(nav_order)
SECS=$(section_order)

# Filter sections to only those that nav references — invariant only applies
# to the subset that's in the nav. Pages can have many sections beyond the nav.
NAV_SET=$(echo "$NAV" | sort -u)
SECS_FILTERED=$(echo "$SECS" | grep -Fxf <(echo "$NAV_SET") || true)

if [ "$NAV" = "$SECS_FILTERED" ]; then
  echo "audit-nav-order: OK — nav order matches scroll order"
  echo "  $(echo "$NAV" | tr '\n' ' ')"
  exit 0
fi

echo "audit-nav-order: FAIL — nav declaration order does not match section scroll order"
echo
echo "Nav order (as declared in .nav-pill):"
echo "$NAV" | nl -ba
echo
echo "Section scroll order (only nav-referenced ids):"
echo "$SECS_FILTERED" | nl -ba
echo
echo "Fix: reorder <a class=\"nav-link\"> elements in .nav-pill to match scroll order,"
echo "or move the offending <section> to match nav order. Run this script again to verify."
exit 1
