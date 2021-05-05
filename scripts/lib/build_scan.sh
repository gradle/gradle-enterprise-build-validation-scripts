#!/usr/bin/env bash

read_build_scan_metadata() {
  base_urls=()
  build_scan_urls=()
  build_scan_ids=()
  # This isn't the most robust way to read a CSV,
  # but we control the CSV so we don't have to worry about various CSV edge cases
  while IFS=, read -r field_1 field_2 field_3; do
     base_urls+=("$field_1")
     build_scan_urls+=("$field_2")
     build_scan_ids+=("$field_3")
  done < "${BUILD_SCAN_FILE}"
}
