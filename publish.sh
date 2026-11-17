#!/bin/bash
# Publishes this folder to GitHub using the gh CLI.
set -e
cd "$(dirname "$0")"
REPO="${1:-ritual-trackers}"
command -v gh >/dev/null || { echo "gh is not installed. Install with: brew install gh"; exit 1; }
gh auth status >/dev/null 2>&1 || { echo "Not logged in. Run: gh auth login"; exit 1; }
[ -d .git ] || git init -b main
git add .
git commit -m "Update" || true
if git remote get-url origin >/dev/null 2>&1; then
  git push -u origin main
else
  gh repo create "$REPO" --public --source=. --remote=origin --push
fi
echo "✅ Published to GitHub."
