#!/usr/bin/env bash
set -euo pipefail

SCHEME="${1:-RetailRewardsRescue}"
WORKSPACE="${2:-RetailRewardsRescue.xcworkspace}"

if [[ -n "${DESTINATION:-}" ]]; then
  echo "${DESTINATION}"
  exit 0
fi

destinations_output="$(
  xcodebuild \
    -workspace "${WORKSPACE}" \
    -scheme "${SCHEME}" \
    -showdestinations 2>/dev/null || true
)"

if [[ -z "${destinations_output}" ]]; then
  echo "Unable to query available destinations via xcodebuild." >&2
  exit 1
fi

parsed_destinations="$(
  printf "%s\n" "${destinations_output}" | awk -F',' '
    /platform:iOS Simulator/ && /id:/ && /name:/ {
      id = ""
      name = ""

      for (i = 1; i <= NF; i++) {
        token = $i
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", token)
        gsub(/[{}]/, "", token)

        if (token ~ /^id:/) {
          sub(/^id:[[:space:]]*/, "", token)
          id = token
        } else if (token ~ /^name:/) {
          sub(/^name:[[:space:]]*/, "", token)
          name = token
        }
      }

      if (id != "" && id !~ /^dvtdevice-/) {
        print id "|" name
      }
    }
  '
)"

if [[ -z "${parsed_destinations}" ]]; then
  echo "No usable iOS Simulator destination found for scheme ${SCHEME}." >&2
  echo "${destinations_output}" >&2
  exit 1
fi

selected_id="$(
  printf "%s\n" "${parsed_destinations}" | awk -F'|' '$2 ~ /^iPhone / { print $1; exit }'
)"

if [[ -z "${selected_id}" ]]; then
  selected_id="$(printf "%s\n" "${parsed_destinations}" | head -n 1 | cut -d'|' -f1)"
fi

echo "id=${selected_id}"
