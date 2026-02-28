# Handoff

## Current goal
Defaulted release flow to notarize and publish; Makefile notes defaults and publish skip.

## Decisions
Set NOTARIZE=1 and PUBLISH=1 by default and automate GitHub release + tap push.

## Changes since last session
- scripts/release.sh: default notarize/publish; auto-create/upload GitHub release; commit/push tap.
- Makefile: document defaults and publish skip.

## Verification status
repo_verify: OK (no tests detected; shellcheck not installed).

## Risks
Release automation will fail without gh auth or a git remote in the tap repo.

## Next actions
Ensure gh CLI is authenticated, SIGN_IDENTITY/NOTARY_PROFILE are set, and CASK_TAP_PATH points to homebrew-solixmenu before running make release.
