#!/usr/bin/env bash
set -euo pipefail

svc="$1"
sha="$2"

# who owns the repo?
OWNER="${GITHUB_REPOSITORY%%/*}"

# 1) clone the infra repo
git clone --depth=1 \
  "https://x-access-token:${GITHUB_TOKEN}@github.com/${OWNER}/weather-infra.git"
cd weather-infra

# 2) create & switch to the branch
branch="update-${svc}-${sha:0:7}"
git checkout -b "$branch"

# 3) bump the image tag
chmod +x scripts/*.sh
./scripts/prod_apply.sh "$svc" "$sha"

# 4) push the new branch
git push --force-with-lease --set-upstream origin "$branch"

# 5) open the PR (no --json, no --jq)
gh pr create \
  --repo "${OWNER}/weather-infra" \
  --title "Promote ${svc}:${sha:0:7}" \
  --body "auto‑promote ${svc} → ${sha}" \
  --base main \
  --head "$branch"

echo "✅ PR opened for update-${svc}-${sha:0:7}. Now add the 'promote-qa' label to trigger QA."
