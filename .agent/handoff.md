# Handoff

## Current goal
Integrated optional notarization step into release script via NOTARIZE=1 flag.

## Decisions
Reuse scripts/notarize.sh to sign, zip, notarize, and staple before generating cask.

## Changes since last session
- scripts/release.sh: added NOTARIZE flag to run scripts/notarize.sh and validate zip before cask.

## Verification status
repo_verify: OK (no tests detected; shellcheck not installed).

## Risks
Notarization still requires configured credentials and Developer ID identity.

## Next actions
Run scripts/release.sh with NOTARIZE=1 and notarization env vars to produce stapled zip and cask.
