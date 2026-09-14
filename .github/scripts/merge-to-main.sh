#!/usr/bin/env bash

# Lands HEAD on main through a pull request, blocking until it is merged.
#
# main requires the lint-test check and has no bypass actors, and a direct push cannot satisfy that.
# The requirement is evaluated against the commit being pushed, and a check run produced by a check
# suite on another branch does not count — verified the hard way: six rejections over 2.5 minutes with
# a green lint-test present on the exact SHA with the right app id. Pull request merges are evaluated
# against the PR's own checks, so this is the only route that works with the bypass list empty.
#
# The branch push and the PR both use RELEASE_TOKEN, and that is not incidental: a PR opened by
# GITHUB_TOKEN triggers no pull_request run, so lint-test would never report and the PR would never
# become mergeable. The merge itself uses GITHUB_TOKEN, which keeps the squashed commit from
# re-triggering chart-version.yml.
#
# Usage: merge-to-main.sh <title> [body]
#
# The title becomes the squashed commit subject on main. On success origin/main is left up to date,
# because the merged commit is a squash of HEAD rather than HEAD itself — anything tagging the release
# must tag origin/main, not the local commit this was handed.

set -euo pipefail

TITLE="$1"
BODY="${2:-}"

: "${RELEASE_TOKEN:?not set. The release PR must be opened by a PAT: a PR opened with GITHUB_TOKEN triggers no CI, so the required lint-test check would never report. Add a fine-grained PAT with contents:write and pull-requests:write as the RELEASE_TOKEN secret.}"

SHA=$(git rev-parse HEAD)
BRANCH="release/run-${GITHUB_RUN_ID}"
TIMEOUT="${CI_WAIT_TIMEOUT:-2400}"

echo "Pushing ${SHA} to ${BRANCH}."
git push -q "https://x-access-token:${RELEASE_TOKEN}@github.com/${GITHUB_REPOSITORY}.git" \
  "HEAD:refs/heads/${BRANCH}"

PR=$(GH_TOKEN="${RELEASE_TOKEN}" gh pr create \
  --base main \
  --head "${BRANCH}" \
  --title "${TITLE}" \
  --body "Opened by chart-version.yml (run ${GITHUB_RUN_ID}); merges itself once lint-test passes.

${BODY}")
echo "Opened ${PR}"

echo "Waiting up to ${TIMEOUT}s for lint-test on ${SHA}."
deadline=$((SECONDS + TIMEOUT))
while :; do
  # An empty check_runs array yields "queued", which is also the honest answer before CI starts.
  read -r status conclusion <<<"$(gh api \
    "/repos/${GITHUB_REPOSITORY}/commits/${SHA}/check-runs?check_name=lint-test" \
    --jq '.check_runs[0] | "\(.status // "queued") \(.conclusion // "")"')"

  if [ "${status}" = "completed" ]; then
    if [ "${conclusion}" = "success" ]; then
      break
    fi
    # Deliberately left open: a failed release is worth looking at, and the branch name is unique per
    # run so nothing collides with the next attempt.
    echo "::error::lint-test concluded ${conclusion} for ${SHA}. Leaving ${PR} open for inspection."
    exit 1
  fi

  if [ "${SECONDS}" -ge "${deadline}" ]; then
    echo "::error::lint-test did not complete within ${TIMEOUT}s (last status: ${status}). Leaving ${PR} open."
    exit 1
  fi

  sleep 20
done

echo "lint-test passed; merging ${PR}."
if [ -n "${BODY}" ]; then
  gh pr merge "${PR}" --squash --delete-branch --subject "${TITLE}" --body "${BODY}"
else
  gh pr merge "${PR}" --squash --delete-branch --subject "${TITLE}"
fi

git fetch -q origin main
echo "Merged ${PR}; main is now $(git rev-parse --short origin/main)."
