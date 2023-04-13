#!/usr/bin/env bash

readonly FETCH_BUILD_SCAN_DATA_JAR="${LIB_DIR}/export-api-clients/fetch-build-scan-data-cmdline-tool-${SCRIPT_VERSION}-all.jar"

# This is a helper function for the common pattern of reading Build Scan metadata
# from the build-scans.csv file, then retrieving build metrics using the Gradle
# Enterprise API.
process_build_scan_data_online() {
  read_build_scan_metadata
  fetch_build_scans_and_build_time_metrics 'brief_logging' "${build_scan_urls[@]}"
}

read_build_scan_metadata() {
  # This isn't the most robust way to read a CSV,
  # but we control the CSV so we don't have to worry about various CSV edge cases
  if [ -f "${BUILD_SCAN_FILE}" ]; then
    local build_scan_metadata
    build_scan_metadata=$(< "${BUILD_SCAN_FILE}")

    if [[ "${debug_mode}" == "on" ]]; then
      debug "Raw Build Scan metadata (build-scans.csv)"
      debug "---------------------------"
      debug "${build_scan_metadata}"
      debug ""
    fi

    while IFS=, read -r run_num field_1 field_2 field_3; do
       base_urls[$run_num]="$field_1"
       build_scan_urls[$run_num]="$field_2"
       build_scan_ids[$run_num]="$field_3"
    done <<< "${build_scan_metadata}"
  fi
}

is_build_scan_metadata_missing() {
  if [ ! -f "${BUILD_SCAN_FILE}" ]; then
    return 0
  fi
  while IFS=, read -r run_num field_1 field_2 field_3; do
    if [[ "$run_num" == "$1"  ]]; then
      return 1
    fi
  done < "${BUILD_SCAN_FILE}"
  return 0
}

fetch_single_build_scan() {
  local build_scan_url="$1"

  local build_scan_data
  build_scan_data="$(fetch_build_scan_data 'verbose_logging' "${build_scan_url}")"

  parse_single_build_scan "${build_scan_data}"
}

# The value of logging_level should be either 'brief_logging' or
# 'verbose_logging'
fetch_build_scans_and_build_time_metrics() {
  local logging_level="$1"
  shift
  local build_scan_urls=("$@")

  if [[ "${logging_level}" == 'verbose_logging' ]]; then
    info "Fetching build scan data"
  fi

  local build_scan_data
  build_scan_data="$(fetch_build_scan_data "${logging_level}" "${build_scan_urls[@]}")"

  parse_build_scans_and_build_time_metrics "${build_scan_data}"
}

# Note: Callers of this function require stdout to be clean. No logging can be
#       done inside this function.
fetch_build_scan_data() {
  local logging_level="$1"
  shift
  local build_scan_urls=("$@")

  if [[ "${debug_mode}" == "on" ]]; then
    args+=("--debug")
  fi

  if [ -n "${mapping_file}" ]; then
    args+=("--mapping-file" "${mapping_file}")
  fi

  if [ -f "${SCRIPT_DIR}/network.settings" ]; then
    args+=("--network-settings-file" "${SCRIPT_DIR}/network.settings")
  fi

  if [[ "${logging_level}" == "brief_logging" ]]; then
    args+=("--brief-logging")
  fi

  for run_num in "${!build_scan_urls[@]}"; do
    args+=( "${run_num},${build_scan_urls[run_num]}" )
  done

  invoke_java "${FETCH_BUILD_SCAN_DATA_JAR}" "${args[@]}"
}
