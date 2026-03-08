#!/usr/bin/env bash
set -euo pipefail

SCHEME="${SCHEME:-RetailRewardsRescue}"
RESULT_BUNDLE="${RESULT_BUNDLE:-build/UITests.xcresult}"

if ! command -v xcodegen >/dev/null 2>&1; then
  echo "xcodegen is required. Install from https://github.com/yonaskolb/XcodeGen"
  exit 1
fi

if ! command -v pod >/dev/null 2>&1; then
  echo "CocoaPods is required. Install with: gem install cocoapods"
  exit 1
fi

mkdir -p build
rm -rf "${RESULT_BUNDLE}"

echo "Generating project and installing pods..."
xcodegen generate
pod install --silent

if DESTINATION="$("./scripts/resolve_destination.sh" "${SCHEME}" "RetailRewardsRescue.xcworkspace" "simulator_only")"; then
  echo "Using destination: ${DESTINATION}"
else
  echo "No concrete iOS Simulator runtime found. Skipping UI tests."
  echo "UI tests skipped: iOS Simulator runtime unavailable on this runner." | tee build/ui-tests.log
  exit 0
fi

echo "Running UI smoke and accessibility tests..."
xcodebuild \
  -workspace RetailRewardsRescue.xcworkspace \
  -scheme "${SCHEME}" \
  -destination "${DESTINATION}" \
  -resultBundlePath "${RESULT_BUNDLE}" \
  -only-testing:RetailRewardsRescueUITests \
  test | tee build/ui-tests.log
