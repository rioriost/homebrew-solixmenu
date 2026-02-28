# Handoff

## Current goal
Enhanced release script with preflight checks and clearer error messages.

## Decisions
Fail fast on missing env/commands and provide actionable hints.

## Changes since last session
- scripts/release.sh: added require_cmd/require_env helpers and improved validation messages.

## Verification status
repo_verify: OK (shellcheck not installed; no tests detected).

## Risks
Release flow will stop early if credentials or gh auth are missing.

## Next actions
Ensure SIGN_IDENTITY, NOTARY_PROFILE (or APPLE_ID/TEAM_ID/APP_PASSWORD), gh auth, and CASK_TAP_PATH are set before make release.
