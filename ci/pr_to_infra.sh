#!/usr/bin/env bash
set -euo pipefail
svc="$1"      # e.g. favorites-api
sha="$2"      # full commit SHA

branch="update-${svc}-${sha:0:7}"
git clone --depth 1 https://github.com/Sufiyan11919/weather-infra.git
cd weather-infra
git checkout -b "$branch"

# update the tag in infra manifests
./scripts/prod_apply.sh "$svc" "$sha"

git push origin "$branch"

# open the PR labelled “promote-qa”
gh pr create \
  --title "$svc -> $sha" \
  --body "Auto‑promote $svc to QA using tag $sha" \
  --base main \
  --label promote-qa \
  --repo Sufiyan11919/weather-infra
