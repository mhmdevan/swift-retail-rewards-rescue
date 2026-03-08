#!/usr/bin/env bash
set -euo pipefail

SCHEME="${1:-RetailRewardsRescue}"
WORKSPACE="${2:-RetailRewardsRescue.xcworkspace}"
MODE="${3:-simulator_or_mymac}"

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

simulator_candidates="$(
  printf "%s\n" "${destinations_output}" | sed -nE \
    's/.*platform:iOS Simulator.*id:([^,}]+).*name:([^,}]+).*/\1|\2/p' | \
    awk -F'|' '
      {
        id = $1
        name = $2
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", id)
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", name)
        if (id != "" && id !~ /^dvtdevice-/) {
          print id "|" name
        }
      }
    '
)"

if [[ -n "${simulator_candidates}" ]]; then
  selected_simulator_id="$(
    printf "%s\n" "${simulator_candidates}" | awk -F'|' '$2 ~ /^iPhone / { print $1; exit }'
  )"

  if [[ -z "${selected_simulator_id}" ]]; then
    selected_simulator_id="$(printf "%s\n" "${simulator_candidates}" | head -n 1 | cut -d'|' -f1)"
  fi

  echo "id=${selected_simulator_id}"
  exit 0
fi

if [[ "${MODE}" == "simulator_only" ]]; then
  echo "No usable iOS Simulator destination found for scheme ${SCHEME}." >&2
  echo "${destinations_output}" >&2
  exit 1
fi

if [[ "${MODE}" == "simulator_or_mymac" ]]; then
  mac_fallback_id="$(
    printf "%s\n" "${destinations_output}" | sed -nE \
      's/.*platform:macOS.*variant:Designed for \[iPad,iPhone\].*id:([^,}]+).*/\1/p' | \
      head -n 1 | xargs
  )"

  if [[ -n "${mac_fallback_id}" ]]; then
    echo "id=${mac_fallback_id}"
    exit 0
  fi
fi

echo "No usable destination found for scheme ${SCHEME} (mode=${MODE})." >&2
echo "${destinations_output}" >&2
exit 1
