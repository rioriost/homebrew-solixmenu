#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

APP_NAME="${APP_NAME:-SolixMenu}"
SCHEME="${SCHEME:-SolixMenu}"
CONFIGURATION="${CONFIGURATION:-Release}"
TAG="${1:-${TAG:-}}"

if [[ -z "$TAG" ]]; then
  TAG="$(git describe --tags --abbrev=0)"
fi

if [[ -z "$TAG" ]]; then
  echo "ERROR: No git tag found. Pass a tag as an argument or set TAG env."
  exit 1
fi

VERSION="${TAG#v}"

DERIVED_DATA="${DERIVED_DATA:-$ROOT_DIR/build/DerivedData}"
BUILD_PRODUCTS="$DERIVED_DATA/Build/Products/$CONFIGURATION"
APP_PATH="$BUILD_PRODUCTS/$APP_NAME.app"

ZIP_NAME="${APP_NAME}-${TAG}.zip"
ZIP_PATH="${ZIP_PATH:-$ROOT_DIR/build/$ZIP_NAME}"
NOTARIZE="${NOTARIZE:-1}"
PUBLISH="${PUBLISH:-1}"

echo "==> Building $APP_NAME ($CONFIGURATION)"
xcodebuild \
  -project "$ROOT_DIR/$APP_NAME.xcodeproj" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -derivedDataPath "$DERIVED_DATA" \
  build

if [[ ! -d "$APP_PATH" ]]; then
  echo "ERROR: App not found at $APP_PATH"
  exit 1
fi

if [[ "$NOTARIZE" == "1" ]]; then
  echo "==> Notarizing (scripts/notarize.sh)"
  ZIP_NAME="$ZIP_NAME" ZIP_PATH="$ZIP_PATH" CONFIGURATION="$CONFIGURATION" DERIVED_DATA="$DERIVED_DATA" \
    scripts/notarize.sh "$TAG"
else
  echo "==> Creating zip: $ZIP_PATH"
  mkdir -p "$(dirname "$ZIP_PATH")"
  rm -f "$ZIP_PATH"
  ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$ZIP_PATH"
fi

if [[ ! -f "$ZIP_PATH" ]]; then
  echo "ERROR: Zip not found at $ZIP_PATH"
  exit 1
fi

SHA256="$(shasum -a 256 "$ZIP_PATH" | awk '{print $1}')"

APP_REPO="${APP_REPO:-}"
if [[ -z "$APP_REPO" ]]; then
  ORIGIN_URL="$(git remote get-url origin 2>/dev/null || true)"
  if [[ "$ORIGIN_URL" =~ github.com[:/](.+)/(.+)\.git$ ]]; then
    APP_REPO="${BASH_REMATCH[1]}/${BASH_REMATCH[2]}"
  elif [[ "$ORIGIN_URL" =~ github.com[:/](.+)/(.+)$ ]]; then
    APP_REPO="${BASH_REMATCH[1]}/${BASH_REMATCH[2]}"
  fi
fi

if [[ -z "$APP_REPO" ]]; then
  echo "ERROR: APP_REPO not set and origin URL not detected."
  echo "Set APP_REPO in the form: owner/repo"
  exit 1
fi

HOMEPAGE="${HOMEPAGE:-https://github.com/$APP_REPO}"
CASK_TAP_PATH="${CASK_TAP_PATH:-$ROOT_DIR/../homebrew-solixmenu}"
CASKS_DIR="$CASK_TAP_PATH/Casks"
CASK_FILE="$CASKS_DIR/solixmenu.rb"
CASK_REL="Casks/solixmenu.rb"

URL="https://github.com/${APP_REPO}/releases/download/${TAG}/${ZIP_NAME}"

echo "==> Writing cask: $CASK_FILE"
mkdir -p "$CASKS_DIR"
cat > "$CASK_FILE" <<EOF
cask "solixmenu" do
  version "$VERSION"
  sha256 "$SHA256"

  url "$URL"
  name "SolixMenu"
  desc "Lightweight macOS menu bar app for monitoring Anker Solix devices"
  homepage "$HOMEPAGE"

  app "${APP_NAME}.app"
end
EOF

if [[ "$PUBLISH" == "1" ]]; then
  if ! command -v gh >/dev/null 2>&1; then
    echo "ERROR: gh CLI not installed. Install it or set PUBLISH=0."
    exit 1
  fi

  echo "==> Publishing GitHub release: $TAG"
  if gh release view "$TAG" >/dev/null 2>&1; then
    gh release upload "$TAG" "$ZIP_PATH" --clobber
  else
    if [[ -n "${RELEASE_NOTES:-}" ]]; then
      gh release create "$TAG" "$ZIP_PATH" --notes "$RELEASE_NOTES"
    else
      gh release create "$TAG" "$ZIP_PATH" --generate-notes
    fi
  fi

  echo "==> Committing Homebrew cask"
  if [[ ! -d "$CASK_TAP_PATH/.git" ]]; then
    echo "ERROR: CASK_TAP_PATH is not a git repo: $CASK_TAP_PATH"
    exit 1
  fi
  git -C "$CASK_TAP_PATH" add "$CASK_REL"
  if ! git -C "$CASK_TAP_PATH" diff --cached --quiet; then
    TAP_COMMIT_MESSAGE="${TAP_COMMIT_MESSAGE:-solixmenu $VERSION}"
    git -C "$CASK_TAP_PATH" commit -m "$TAP_COMMIT_MESSAGE"
  fi
  git -C "$CASK_TAP_PATH" push
fi

cat <<INFO

Release artifacts:
- Tag: $TAG
- Version: $VERSION
- Zip: $ZIP_PATH
- SHA256: $SHA256
- Cask: $CASK_FILE
- Notarize: $NOTARIZE
- Publish: $PUBLISH

INFO
