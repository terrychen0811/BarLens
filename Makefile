APP_NAME := BarChaneg
SOURCE := Sources/BarChaneg/main.swift
BUILD_DIR := .build
BINARY := $(BUILD_DIR)/$(APP_NAME)
VERSION ?= 0.1.0
RELEASE_DIR := $(BUILD_DIR)/release
APP_BUNDLE := $(RELEASE_DIR)/$(APP_NAME).app
ZIP := $(RELEASE_DIR)/$(APP_NAME)-$(VERSION)-macOS.zip

.PHONY: build bundle package run clean

build:
	mkdir -p $(BUILD_DIR)
	swiftc -O -target arm64-apple-macosx14.0 $(SOURCE) -o $(BINARY) -framework AppKit -framework CoreGraphics

bundle: build
	rm -rf $(APP_BUNDLE)
	mkdir -p $(APP_BUNDLE)/Contents/MacOS
	cp $(BINARY) $(APP_BUNDLE)/Contents/MacOS/$(APP_NAME)
	cp Resources/Info.plist $(APP_BUNDLE)/Contents/Info.plist
	plutil -replace CFBundleShortVersionString -string $(VERSION) $(APP_BUNDLE)/Contents/Info.plist
	plutil -replace CFBundleVersion -string $(VERSION) $(APP_BUNDLE)/Contents/Info.plist
	codesign --force --sign - $(APP_BUNDLE)

package: bundle
	rm -f $(ZIP)
	ditto -c -k --sequesterRsrc --keepParent $(APP_BUNDLE) $(ZIP)
	@echo $(ZIP)

run: build
	$(BINARY)

clean:
	rm -rf $(BUILD_DIR)
