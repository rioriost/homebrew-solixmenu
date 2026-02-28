# Handoff

## Current goal
Added release automation script to build zip and generate Homebrew cask; fixed verify for bash 3.2 compatibility.

## Decisions
Generate cask from git tag and repo URL; use zip artifacts and optional tap path.

## Changes since last session
- Added scripts/release.sh for build/zip/cask generation.
- Updated .zed/scripts/verify to avoid mapfile on bash 3.2.

## Verification status
repo_verify: OK (xcodebuild SolixMenu Debug).

## Risks
Cask URL depends on APP_REPO detection; set APP_REPO if origin is missing.

## Next actions
Run scripts/release.sh after tagging; upload zip and commit cask in homebrew-solixmenu.
