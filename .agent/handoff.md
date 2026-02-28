# Handoff

## Current goal
Added env var reference comment block to release.sh.

## Decisions
Document required/optional env vars inline to reduce setup confusion.

## Changes since last session
- scripts/release.sh: added env var list comment block.

## Verification status
repo_verify: OK (shellcheck not installed; no tests detected).

## Risks
Release flow still depends on external credentials and gh auth.

## Next actions
Run make release after setting SIGN_IDENTITY/NOTARY_PROFILE and gh auth.
