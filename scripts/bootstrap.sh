#!/usr/bin/env bash
set -euo pipefail

if ! command -v xcodegen >/dev/null 2>&1; then
  echo "xcodegen is required. Install from https://github.com/yonaskolb/XcodeGen"
  exit 1
fi

if ! command -v pod >/dev/null 2>&1; then
  echo "CocoaPods is required. Install with: gem install cocoapods"
  exit 1
fi

echo "Generating Xcode project..."
xcodegen generate

echo "Installing CocoaPods dependencies..."
pod install

echo "Resolving Swift Package dependencies..."
swift package resolve

echo "Bootstrap complete. Open RetailRewardsRescue.xcworkspace"
