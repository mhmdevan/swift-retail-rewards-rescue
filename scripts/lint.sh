#!/usr/bin/env bash
set -euo pipefail

if ! command -v swiftlint >/dev/null 2>&1; then
  echo "swiftlint is required. Install from https://github.com/realm/SwiftLint"
  exit 1
fi

swiftlint lint --strict
