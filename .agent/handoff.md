# Handoff

## Current goal
Added Makefile release target to call scripts/release.sh.

## Decisions
Expose release workflow via make release for convenience.

## Changes since last session
- Makefile: added release phony target.

## Verification status
repo_verify: OK (no tests detected).

## Risks
Release target relies on scripts/release.sh and configured env vars.

## Next actions
Use make release (optionally with NOTARIZE=1 and env vars) for release automation.
