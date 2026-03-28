#!/usr/bin/env bash
# health-check.sh — E2E hub health check for dotsai.in ecosystem
# Usage: bash scripts/health-check.sh
#   Optional: bash scripts/health-check.sh --ssh (also checks docker containers on VPS)

set -euo pipefail

PASS=0
FAIL=0
RESULTS=""

check() {
  local name="$1"
  local cmd="$2"
  if (set +o pipefail; eval "$cmd") > /dev/null 2>&1; then
    RESULTS+="  PASS  $name\n"
    ((PASS++)) || true
  else
    RESULTS+="  FAIL  $name\n"
    ((FAIL++)) || true
  fi
}

echo ""
echo "=== dotsai.in Hub Health Check ==="
echo "    $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
echo ""

# 1. api.dotsai.in health endpoint
check "api.dotsai.in/health" "curl -sf --max-time 10 https://api.dotsai.in/health"

# 2. meet.dotsai.in loads
check "meet.dotsai.in (HTTP 200)" "curl -sf --max-time 10 -o /dev/null -w '%{http_code}' https://meet.dotsai.in | grep -q 200"

# 3. meet.dotsai.in has SSL
check "meet.dotsai.in (valid SSL)" "curl -sf --max-time 10 https://meet.dotsai.in -o /dev/null"

# 4. dotsai.in loads
check "dotsai.in (HTTP 200)" "curl -sf --max-time 10 -o /dev/null https://dotsai.in"

# 5. dotsai.in gateway section exists
check "dotsai.in gateway section" "curl -sf --max-time 10 https://dotsai.in | grep -q 'id=\"gateway\"'"

# 6. dotsai.in analytics snippet
check "dotsai.in analytics snippet" "curl -sf --max-time 10 https://dotsai.in | grep -q 'dotsTrack'"

# 7. meet.dotsai.in has Book a Call link
check "meet.dotsai.in cal.com link" "curl -sf --max-time 10 https://meet.dotsai.in | grep -q 'cal.com/meetdeshani'"

# SSH checks (optional — only if --ssh flag passed)
if [[ "${1:-}" == "--ssh" ]]; then
  echo "--- VPS Container Checks (via SSH) ---"
  check "postgres container healthy" "ssh -o ConnectTimeout=10 root@72.62.229.16 'docker ps --filter name=postgres --format \"{{.Status}}\"' | grep -q healthy"
  check "analytics container running" "ssh -o ConnectTimeout=10 root@72.62.229.16 'docker ps --filter name=analytics --format \"{{.Status}}\"' | grep -q Up"
  check "nginx container running" "ssh -o ConnectTimeout=10 root@72.62.229.16 'docker ps --filter name=nginx --format \"{{.Status}}\"' | grep -q Up"
fi

echo -e "$RESULTS"
echo "=== Results: $PASS passed, $FAIL failed ==="
echo ""

if [[ $FAIL -gt 0 ]]; then
  echo "STATUS: FAIL"
  exit 1
else
  echo "STATUS: PASS"
  exit 0
fi
