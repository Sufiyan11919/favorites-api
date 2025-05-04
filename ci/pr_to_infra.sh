#!/usr/bin/env bash
set -euo pipefail

# 1) parameters
svc="$1"
sha="$2"

# 2) who owns the infra repo? (assumes same org/user)
OWNER="${GITHUB_REPOSITORY%%/*}"

# 3) clone using the PAT we passed in as GITHUB_TOKEN
git clone --depth=1 \
  "https://x-access-token:${GITHUB_TOKEN}@github.com/${OWNER}/weather-infra.git"
cd weather-infra

# 4) create your branch
branch="update-${svc}-${sha::7}"
git checkout -b "$branch"

# 5) ensure scripts are executable
chmod +x scripts/*.sh

# 6) bump the image tag in k8s/base
./scripts/prod_apply.sh "$svc" "$sha"

# 7) push back to infra repo
git push --set-upstream origin "$branch"

# 8) open the PR pointing at main with the label to kick off QA
gh pr create \
  --repo "${OWNER}/weather-infra" \
  --head "${OWNER}:${branch}" \
  --base main \
  --title  "Promote ${svc}:${sha::7}" \
  --body   "auto‐promote ${svc} → ${sha::7}" \
  --label  promote-qa
