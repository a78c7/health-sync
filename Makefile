# Everyday commands. Everything here ships with Xcode; nothing to install.

PROJECT = HealthSync.xcodeproj
SCHEME = HealthSync
SIMULATOR ?= iPhone 17
SOURCES = HealthSync HealthSyncTests

.PHONY: build test lint format

build:
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) -destination 'generic/platform=iOS Simulator' build

test:
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) -destination 'platform=iOS Simulator,name=$(SIMULATOR)' test

lint:
	xcrun swift-format lint --strict --recursive --parallel $(SOURCES)

format:
	xcrun swift-format format --in-place --recursive --parallel $(SOURCES)
