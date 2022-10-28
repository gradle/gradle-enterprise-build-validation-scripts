#!/usr/bin/env bash

readonly FETCH_BUILD_SCAN_DATA_JAR="${LIB_DIR}/export-api-clients/fetch-build-scan-data-cmdline-tool-${SCRIPT_VERSION}-all.jar"
readonly MOCK_SCAN_DUMP_TO_CSV_JAR="${LIB_DIR}/export-api-clients/mock-scan-dump-to-csv-tool-${SCRIPT_VERSION}-all.jar"

read_build_scan_metadata() {
  # This isn't the most robust way to read a CSV,
  # but we control the CSV so we don't have to worry about various CSV edge cases
  if [ -f "${BUILD_SCAN_FILE}" ]; then
    while IFS=, read -r field_1 field_2 field_3 field_4; do
       project_names+=("$field_1")
       base_urls+=("$field_2")
       build_scan_urls+=("$field_3")
       build_scan_ids+=("$field_4")
    done < "${BUILD_SCAN_FILE}"
  fi
}

read_build_data_from_current_dir() {
  git_repos+=("$(git_get_remote_url)")
  git_branches+=("${git_branch:-$(git_get_branch)}")
  git_commit_ids+=("$(git_get_commit_id)")
  requested_tasks+=("${tasks}")
}

fetch_and_read_build_scan_data() {
  # This isn't the most robust way to read a CSV,
  # but we control the CSV so we don't have to worry about various CSV edge cases
  local args build_cache_metrics_only
  args=()

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

  if [[ "$1" == "build_cache_metrics_only" ]]; then
    build_cache_metrics_only="true"
    args+=("--brief-logging")
    debug "Only using the task metrics found in the build scan data"
  else
      info "Fetching build scan data"
  fi
  shift
  args+=( "$@" )

  raw_build_scan_data="$(invoke_java "$FETCH_BUILD_SCAN_DATA_JAR" "${args[@]}")"
  parse_raw_build_scan_data "$raw_build_scan_data" "$build_cache_metrics_only"
}

read_build_scan_from_scan_dump() {
  raw_build_scan_data="$(invoke_java "$MOCK_SCAN_DUMP_TO_CSV_JAR")"
  parse_raw_build_scan_data "$raw_build_scan_data"
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
