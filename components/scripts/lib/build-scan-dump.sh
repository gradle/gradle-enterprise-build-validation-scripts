#!/usr/bin/env bash

readonly SCANS_SUPPORT_TOOLS_JAR="${SCRIPT_DIR}/scans-support-tools.jar"

build_scan_dumps=()

verify_scans_support_tools() {
  if [ ! -f "$SCANS_SUPPORT_TOOLS_JAR" ]; then
    die "ERROR: scans-support-tools.jar is required when running with --disable-build-scan-publishing."
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
  build_scan_dump="$(find "$build_dir" -maxdepth 1 -type f -regex '^.*build-scan-.*-.*-.*-.*\.scan' | sort | tail -n 1)"
  if [ -z "$build_scan_dump" ]; then
    die "ERROR: No Build Scan dump found for the $build_name build"
  fi
  build_scan_dumps+=("${build_scan_dump}")
}

read_build_scan_dumps() {
  local build_scan_csv
  echo -n "Extracting build scan data"
  build_scan_csv="$(invoke_java "$SCANS_SUPPORT_TOOLS_JAR" extract "${build_scan_dumps[0]}"  "${build_scan_dumps[1]}")"
  parse_build_scan_csv "$build_scan_csv"
  echo ", done."
}
