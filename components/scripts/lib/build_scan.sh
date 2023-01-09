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

    if [[ "$_arg_debug" == "on" ]]; then
      debug "Raw Build Scan metadata (build-scans.csv)"
      debug "---------------------------"
      debug "${build_scan_metadata}"
      debug ""
    fi

    while IFS=, read -r field_1 field_2 field_3; do
       base_urls+=("$field_1")
       build_scan_urls+=("$field_2")
       build_scan_ids+=("$field_3")
    done <<< "${build_scan_metadata}"
  fi
}

read_build_data_from_current_dir() {
  git_repos+=("$(git_get_remote_url)")
  git_branches+=("${git_branch:-$(git_get_branch)}")
  git_commit_ids+=("$(git_get_commit_id)")
  requested_tasks+=("${tasks}")
}

fetch_and_read_build_scan_data() {
  local build_cache_metrics_only="$1"
  shift

  local args=()

  if [[ "$_arg_debug" == "on" ]]; then
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

detect_warnings_from_build_scans() {
  local unknown_values=false
  for (( i=0; i<2; i++ )); do
    if [ -z "${project_names[i]}" ] ||
       [ -z "${git_repos[i]}" ] ||
       [ -z "${git_branches[i]}" ] ||
       [ -z "${git_commit_ids[i]}" ] ||
       [ -z "${requested_tasks[i]}" ]; then
      unknown_values=true
    fi
    if [ -z "${build_outcomes[i]}" ]; then
      warnings+=("Failed to fetch build scan data for the ${ORDINALS[i]} build.")
    fi
  done

  local value_mismatch=false
  if [[ "${project_names[0]}" != "${project_names[1]}" ]] ||
     [[ "${git_repos[0]}" != "${git_repos[1]}" ]] ||
     [[ "${git_branches[0]}" != "${git_branches[1]}" ]] ||
     [[ "${git_commit_ids[0]}" != "${git_commit_ids[1]}" ]] ||
     [[ "${requested_tasks[0]}" != "${requested_tasks[1]}" ]]; then
    value_mismatch=true
  fi

  if [[ "${value_mismatch}" == "true" ]]; then
    warnings+=("Differences were detected between the two builds. This may skew the outcome of the experiment.")
  fi
  if [[ "${unknown_values}" == "true" ]]; then
    warnings+=("Some of the build properties could not be determined. This makes it uncertain if the experiment has run correctly.")
  fi
}
