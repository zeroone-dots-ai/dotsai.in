#!/usr/bin/env bash
#
# audit-all.sh
# ────────────
# Runs every audit-*.sh in scripts/ and exits non-zero if any fails.
# Wired into .github/workflows/deploy.yml as the pre-deploy gate.
#
# To add a new audit: drop another scripts/audit-*.sh — this runner picks it up.
# Skip audits via SKIP="name1,name2" env var (e.g., SKIP="js-blocking").
#
# Run:    bash scripts/audit-all.sh
# Exits:  0 = all pass | 1 = at least one failure

set -uo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
SKIP="${SKIP:-}"

# Collect all audit scripts except this runner (portable: no mapfile, works on bash 3.2)
scripts=()
while IFS= read -r line; do scripts+=("$line"); done < <(
  find "$DIR" -maxdepth 1 -type f -name "audit-*.sh" ! -name "audit-all.sh" | sort
)

if [ ${#scripts[@]} -eq 0 ]; then
  echo "audit-all: no audit-*.sh found in $DIR" >&2
  exit 2
fi

failed=0
total=${#scripts[@]}
ran=0

echo "audit-all: running $total audit(s)"
echo "─────────────────────────────────────────────────────────────"

for s in "${scripts[@]}"; do
  name="$(basename "$s" .sh | sed 's/^audit-//')"

  # Honor SKIP list
  if [[ ",$SKIP," == *",$name,"* ]]; then
    echo "▷ $name  [SKIPPED via SKIP env]"
    continue
  fi

  ran=$((ran+1))
  echo "▷ $name"
  if bash "$s"; then :; else
    failed=$((failed+1))
    echo "  ↑ $name FAILED"
  fi
  echo
done

echo "─────────────────────────────────────────────────────────────"
if [ "$failed" -gt 0 ]; then
  echo "audit-all: $failed of $ran audit(s) FAILED"
  exit 1
fi
echo "audit-all: all $ran audit(s) passed"
