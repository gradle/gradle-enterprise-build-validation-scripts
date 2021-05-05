#!/usr/bin/env bash

read_build_scan_metadata() {
  base_url=()
  scan_url=()
  scan_id=()
  # This isn't the most robust way to read a CSV,
  # but we control the CSV so we don't have to worry about various CSV edge cases
  while IFS=, read -r field_1 field_2 field_3; do
     base_url+=("$field_1")
     scan_url+=("$field_2")
     scan_id+=("$field_3")
  done < "${SCAN_FILE}"
}
