#!/usr/bin/env bash

readonly READ_BUILD_SCAN_DATA_JAR="${LIB_DIR}/build-scan-clients/build-scan-data-tool-${SUMMARY_VERSION}.jar"

build_scan_dumps=()

verify_offline_mode_required_files_exist() {
  if [ ! -f "$READ_BUILD_SCAN_DATA_JAR" ]; then
    die "ERROR: Missing required file to read the build scan data" "${INVALID_INPUT}"
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
  local build_scan_data args
  args=()

  args+=(
      "extract"
      "0,${build_scan_dumps[0]}"
      "1,${build_scan_dumps[1]}"
  )

  echo "Extracting Build Scan data for all builds"
  if ! build_scan_data="$(JAVA_HOME="${CLIENT_JAVA_HOME:-$JAVA_HOME}" invoke_java "$READ_BUILD_SCAN_DATA_JAR" "${args[@]}")"; then
    exit "$UNEXPECTED_ERROR"
  fi
  echo "Finished extracting Build Scan data for all builds"

  parse_build_scans_and_build_time_metrics "$build_scan_data"
}
