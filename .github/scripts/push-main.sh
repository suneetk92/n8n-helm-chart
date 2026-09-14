#!/usr/bin/env bash

# Fast-forwards main to HEAD, but only after CI has genuinely passed on that commit.
#
# main requires the lint-test check, and the requirement is evaluated against the commit being
# pushed. A commit built inside a job has no check runs yet, so the push is rejected with GH013. The
# way through is to publish the commit to a release/** branch first, where ci.yml runs the real
# lint-test against that exact SHA. Check runs belong to the commit rather than the branch, so once it
# passes, the same SHA satisfies main's requirement — no bypass actor is needed by anyone, and the
# required check keeps its plain meaning of "CI ran on this commit".
#
# Everything here runs on GITHUB_TOKEN, no PAT. A GITHUB_TOKEN push creates no workflow run, so the
# branch push alone would never start CI — but workflow_dispatch is the documented exception to that
# rule, so the run is requested explicitly instead. Pushing main with GITHUB_TOKEN is also what keeps
# the release commit from re-triggering chart-version.yml.

set -euo pipefail

SHA=$(git rev-parse HEAD)
TMP="release/run-${GITHUB_RUN_ID}"
TIMEOUT="${CI_WAIT_TIMEOUT:-2400}"

# Drop the branch even when the push to main fails, so a rejected release leaves no refs behind.
trap 'git push -q origin --delete "${TMP}" 2>/dev/null || true' EXIT

echo "Publishing ${SHA} to ${TMP} for validation."
git push -q origin "HEAD:refs/heads/${TMP}"
gh workflow run ci.yml --ref "${TMP}"

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
    echo "::error::lint-test concluded ${conclusion} for ${SHA}; refusing to push to main."
    exit 1
  fi

  if [ "${SECONDS}" -ge "${deadline}" ]; then
    echo "::error::lint-test did not complete within ${TIMEOUT}s (last status: ${status})."
    exit 1
  fi

  sleep 20
done

echo "lint-test passed for ${SHA}; fast-forwarding main."
git push origin HEAD:main
