#!/usr/bin/env bash
set -euo pipefail

SCHEME="${SCHEME:-RetailRewardsRescue}"

if ! command -v xcodegen >/dev/null 2>&1; then
  echo "xcodegen is required. Install from https://github.com/yonaskolb/XcodeGen"
  exit 1
fi

if ! command -v pod >/dev/null 2>&1; then
  echo "CocoaPods is required. Install with: gem install cocoapods"
  exit 1
fi

mkdir -p build

echo "Generating project and installing pods..."
xcodegen generate
pod install --silent

DESTINATION="$("./scripts/resolve_destination.sh" "${SCHEME}" "RetailRewardsRescue.xcworkspace")"
echo "Using destination: ${DESTINATION}"

echo "Running app unit/snapshot/performance tests..."
xcodebuild \
  -workspace RetailRewardsRescue.xcworkspace \
  -scheme "${SCHEME}" \
  -destination "${DESTINATION}" \
  -only-testing:RetailRewardsRescueTests \
  -only-testing:RetailRewardsRescueSnapshotTests \
  -only-testing:RetailRewardsRescuePerformanceTests \
  test | tee build/app-tests.log
