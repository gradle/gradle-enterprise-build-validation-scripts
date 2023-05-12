#!/usr/bin/env bash

readonly GRADLE_ENTERPRISE_LICENSE="${SCRIPT_DIR}/gradle-enterprise.license"
readonly BUILD_SCAN_DUMP_READER_JAR="${LIB_DIR}/build-scan-clients/build-scan-dump-reader.jar"

build_scan_dumps=()

verify_offline_mode_required_files_exist() {
  if [ ! -f "$GRADLE_ENTERPRISE_LICENSE" ]; then
    die "ERROR: Missing required file gradle-enterprise.license in the root folder of the build validation scripts" "${INVALID_INPUT}"
  fi
  if [ ! -f "$BUILD_SCAN_DUMP_READER_JAR" ]; then
    die "ERROR: Missing required file to read the Build Scan data" "${INVALID_INPUT}"
  fi
}

find_and_read_build_scan_dumps() {
  find_build_scan_dumps
  read_build_scan_dumps
}

find_build_scan_dumps() {
  find_build_scan_dump "first"
  find_build_scan_dump "second"
}

find_build_scan_dump() {
  local build_name="$1"
  local build_dir="${EXP_DIR}/$build_name-build_${project_name}"
  if [ -n "${project_dir}" ]; then
    build_dir="$build_dir/$project_dir"
  fi
  build_scan_dump="$(find "$build_dir" -maxdepth 1 -type f -regex '^.*build-scan-.*-.*-.*-.*\.scan' | sort | tail -n 1)"
  if [ -z "$build_scan_dump" ]; then
    die "ERROR: No Build Scan dump found for the $build_name build"
  fi
  build_scan_dumps+=("${build_scan_dump}")
}

read_build_scan_dumps() {
  local build_scan_data build_scan_dump_urls
  build_scan_dump_urls=()

  for run_num in "${!build_scan_dumps[@]}"; do
    build_scan_dump_urls+=( "file://${build_scan_dumps[run_num]}" )
  done

  echo "Extracting Build Scan data for all builds"
  if ! build_scan_data="$(fetch_build_scan_data 'brief_logging' "${build_scan_dump_urls[@]}")"; then
    exit "$UNEXPECTED_ERROR"
  fi
  echo "Finished extracting Build Scan data for all builds"

  parse_build_scans_and_build_time_metrics "$build_scan_data"
}
