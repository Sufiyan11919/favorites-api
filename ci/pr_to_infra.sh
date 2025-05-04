#!/usr/bin/env bash
set -euo pipefail

svc="$1" 
sha="$2"

# Who owns infra
OWNER="${GITHUB_REPOSITORY%%/*}"

# Clone infra using your PAT
git clone --depth=1 \
  "https://x-access-token:${GITHUB_TOKEN}@github.com/${OWNER}/weather-infra.git"
cd weather-infra

# New branch
branch="update-${svc}-${sha::7}"
git checkout -b "$branch"

# Make sure our prod helper is executable
chmod +x scripts/*.sh

# Bump the image tag in k8s/base
./scripts/prod_apply.sh "$svc" "$sha"

# Force‑push that branch back to origin (overwriting any stale branch)
git push --force-with-lease --set-upstream origin "$branch"

# Create the PR and explicitly pass --head so GH CLI knows what branch to use
gh pr create \
  --repo "${OWNER}/weather-infra" \
  --title "Promote ${svc}:${sha::7}" \
  --body "auto‑promote ${svc} → ${sha}" \
  --base main \
  --head "$branch" \
  --label promote-qa
