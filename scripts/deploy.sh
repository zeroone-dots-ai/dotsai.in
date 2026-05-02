#!/usr/bin/env bash
# deploy.sh — safe deploy helper for dotsai.in
# Stages ALL public/ changes, commits with a summary message, pushes to trigger CI/CD.
#
# Usage:
#   bash scripts/deploy.sh                      # auto-message from changed files
#   bash scripts/deploy.sh "feat: my message"   # custom commit message

set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

MSG="${1:-}"

# Stage everything in public/
CHANGED=$(git status --short public/ 2>/dev/null || true)
if [ -z "$CHANGED" ]; then
  echo "deploy: nothing changed in public/ — nothing to deploy"
  exit 0
fi

git add public/

# Build commit message if not provided
if [ -z "$MSG" ]; then
  ADDED=$(git diff --cached --name-only --diff-filter=A public/ | wc -l | tr -d ' ')
  MODIFIED=$(git diff --cached --name-only --diff-filter=M public/ | wc -l | tr -d ' ')
  DELETED=$(git diff --cached --name-only --diff-filter=D public/ | wc -l | tr -d ' ')
  MSG="chore(deploy): sync public/ — +${ADDED} ~${MODIFIED} -${DELETED} files"
fi

echo "Staged files:"
git diff --cached --name-only public/ | sed 's/^/  /'
echo ""
echo "Committing: $MSG"
git commit -m "$MSG"

echo ""
echo "Pushing to origin main → deploy pipeline starting..."
git push origin main
echo ""
echo "Done. Watch: https://github.com/zeroone-dots-ai/dotsai.in/actions"
