#!/usr/bin/env bash

readonly FETCH_BUILD_SCAN_DATA_JAR="${LIB_DIR}/export-api-clients/fetch-build-scan-data-cmdline-tool-${SCRIPT_VERSION}-all.jar"

# This is a helper function for the common pattern of reading Build Scan metadata
# from the build-scans.csv file, then retrieving build metrics using the Gradle
# Enterprise API.
process_build_scan_data_online() {
  read_build_scan_metadata
  fetch_and_read_build_scan_data build_cache_metrics_only "${build_scan_urls[@]}"
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

fetch_and_read_build_scan_data() {
  local build_cache_metrics_only="$1"
  shift

  local args=()

  if [[ "${debug_mode}" == "on" ]]; then
    args+=("--debug")
  fi

  #shellcheck disable=SC2154 #not all scripts set this value...which is fine, we're checking for it before using it
  if [ -n "${mapping_file}" ]; then
    args+=("--mapping-file" "${mapping_file}")
  fi

  if [ -f "${SCRIPT_DIR}/network.settings" ]; then
    args+=("--network-settings-file" "${SCRIPT_DIR}/network.settings")
  fi

  if [[ "$build_cache_metrics_only" == "build_cache_metrics_only" ]]; then
    args+=("--brief-logging")
    debug "Only using the task metrics found in the build scan data"
  else
    info "Fetching build scan data"
  fi
  args+=( "$@" )

  build_scan_csv="$(invoke_java "$FETCH_BUILD_SCAN_DATA_JAR" "${args[@]}")"
  parse_build_scan_csv "$build_scan_csv" "$build_cache_metrics_only"
}
