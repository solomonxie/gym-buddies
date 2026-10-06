.PHONY: help check test build device release screenshots capture

.DEFAULT_GOAL := help

# App Store region baked into Info.plist AppStoreRegion: make device STORE=cn
STORE ?= us
export STORE

help:
	@echo "make test         Core tests (~1 s, no simulator)"
	@echo "make check        tests + a device build"
	@echo "make device       Debug build onto the paired iPhone (upgrades in place; STORE=us|cn)"
	@echo "make release      check, then archive + upload to App Store Connect"
	@echo "make release BUILD=202609261830   same, with the build number pinned"
	@echo "make capture      store screenshots from the paired iPhone (demo data)"
	@echo "make screenshots  SHOTS=<dir>  resize to the App Store slots"

test:
	cd Core && swift test

build:
	xcodegen generate
	xcodebuild -project GymBuddy.xcodeproj -scheme GymBuddy -destination 'generic/platform=iOS' \
	  -derivedDataPath build -allowProvisioningUpdates -quiet APP_STORE_REGION=$(STORE) build

check: test build

device: build
	xcrun devicectl device install app --device "$$(xcrun devicectl list devices | grep physical | grep -oE '[0-9A-F]{8}-[0-9A-F]{16}' | head -1)" \
	  build/Build/Products/Debug-iphoneos/GymBuddy.app

# Archive, sign for the App Store and upload — no Xcode Organizer.
# Needs Local.xcconfig (Team ID) and the app record in App Store Connect.
release: check
	@git diff --quiet HEAD -- || echo "warning: uncommitted changes are going into this build"
	scripts/release-ios.sh $(BUILD)

capture:
	scripts/capture-screens.sh $(SHOTS)

screenshots:
	scripts/store-screenshots.sh $(SHOTS)
