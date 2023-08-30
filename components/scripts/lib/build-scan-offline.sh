#!/usr/bin/env bash

readonly READ_BUILD_SCAN_DATA_JAR="${LIB_DIR}/build-scan-clients/build-scan-summary-${SUMMARY_VERSION}.jar"

# Build scan summary exit codes
readonly SUCCESS=0
readonly JVM_VERSION_NOT_SUPPORTED=3

build_scan_dumps=()

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
  local args build_scan_data build_scan_summary_exit_code

  args=(
    "0,file://${build_scan_dumps[0]}"
    "1,file://${build_scan_dumps[1]}"
  )

  echo "Extracting Build Scan data for all builds"
  build_scan_data="$(JAVA_HOME="${CLIENT_JAVA_HOME:-$JAVA_HOME}" invoke_java "$READ_BUILD_SCAN_DATA_JAR" "${args[@]}")"
  build_scan_summary_exit_code="$?"
  if [[ $build_scan_summary_exit_code -eq $JVM_VERSION_NOT_SUPPORTED ]]; then
    die "ERROR: Java 17+ is required when using --disable-build-scan-publishing. Rerun the script with Java 17+ or set the environment variable CLIENT_JAVA_HOME to a Java 17+ installation." "$UNEXPECTED_ERROR"
  elif [[ $build_scan_summary_exit_code -ne $SUCCESS ]]; then
    exit "$UNEXPECTED_ERROR"
  fi
  echo "Finished extracting Build Scan data for all builds"

  parse_build_scans_and_build_time_metrics "$build_scan_data"
}
