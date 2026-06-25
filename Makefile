APP_NAME := BarLens
SOURCE := Sources/BarLens/main.swift
BUILD_DIR := .build
BINARY := $(BUILD_DIR)/$(APP_NAME)
VERSION ?= 0.2.0
RELEASE_DIR := $(BUILD_DIR)/release
APP_BUNDLE := $(RELEASE_DIR)/$(APP_NAME).app
ZIP := $(RELEASE_DIR)/$(APP_NAME)-$(VERSION)-macOS.zip

.PHONY: build bundle package icon run clean

build:
	mkdir -p $(BUILD_DIR)
	swiftc -O -target arm64-apple-macosx14.0 $(SOURCE) -o $(BINARY) -framework AppKit -framework CoreGraphics

icon:
	swift Tools/generate_app_icon.swift

bundle: build icon
	rm -rf $(APP_BUNDLE)
	mkdir -p $(APP_BUNDLE)/Contents/MacOS $(APP_BUNDLE)/Contents/Resources
	cp $(BINARY) $(APP_BUNDLE)/Contents/MacOS/$(APP_NAME)
	cp Resources/Info.plist $(APP_BUNDLE)/Contents/Info.plist
	cp Resources/AppIcon.icns $(APP_BUNDLE)/Contents/Resources/AppIcon.icns
	cp Resources/PrivacyInfo.xcprivacy $(APP_BUNDLE)/Contents/Resources/PrivacyInfo.xcprivacy
	plutil -replace CFBundleShortVersionString -string $(VERSION) $(APP_BUNDLE)/Contents/Info.plist
	plutil -replace CFBundleVersion -string $(VERSION) $(APP_BUNDLE)/Contents/Info.plist
	codesign --force --sign - --entitlements Resources/BarLens.entitlements $(APP_BUNDLE)

package: bundle
	rm -f $(ZIP)
	ditto -c -k --sequesterRsrc --keepParent $(APP_BUNDLE) $(ZIP)
	@echo $(ZIP)

run: build
	$(BINARY)

clean:
	rm -rf $(BUILD_DIR)
