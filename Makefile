APP_NAME := BarChaneg
SOURCE := Sources/BarChaneg/main.swift
BUILD_DIR := .build
BINARY := $(BUILD_DIR)/$(APP_NAME)

.PHONY: build run clean

build:
	mkdir -p $(BUILD_DIR)
	swiftc -target arm64-apple-macosx14.0 $(SOURCE) -o $(BINARY) -framework AppKit -framework CoreGraphics

run: build
	$(BINARY)

clean:
	rm -rf $(BUILD_DIR)
