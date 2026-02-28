# Handoff

## Current goal
Added notarization automation script for signing, zipping, notarizing, and stapling.

## Decisions
Use notarytool with keychain profile or Apple ID env vars; derive tag from git.

## Changes since last session
- Added scripts/notarize.sh for notarization automation.

## Verification status
repo_verify: OK (no tests detected; shellcheck not installed).

## Risks
Notarization requires Developer ID and app-specific password; signing identity must be set via SIGN_IDENTITY.

## Next actions
Configure notary credentials (NOTARY_PROFILE or APPLE_ID/TEAM_ID/APP_PASSWORD) and run scripts/notarize.sh after tagging.
