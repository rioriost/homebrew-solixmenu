.PHONY: build test release

build:
	xcodebuild -scheme TestTicket19CLI -configuration Debug -destination "platform=macOS,arch=arm64" -quiet build

test:
	direnv exec . sh -lc 'SOLIX_EMAIL="$$SOLIX_EMAIL" SOLIX_PASSWORD="$$SOLIX_PASSWORD" SOLIX_COUNTRY="EU" SOLIX_REQUEST_TIMEOUT=60 \
	~/Library/Developer/Xcode/DerivedData/SolixMenu-*/Build/Products/Debug/TestTicket19CLI'

release:
	# Uses latest git tag for version (or pass TAG)
	./scripts/release.sh
	@echo "Tip: TAG=v1.0.0 make release"
	@echo "Tip: NOTARIZE=1 SIGN_IDENTITY=... NOTARY_PROFILE=... make release"
