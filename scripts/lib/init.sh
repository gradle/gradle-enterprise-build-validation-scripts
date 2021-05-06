#!/usr/bin/env bash

make_experiment_dir() {
  mkdir -p "${EXP_DIR}"
  rm -f "${BUILD_SCAN_FILE}"
}

generate_run_id() {
  printf '%x' "$(date +%s)"
}

# Init common constants
readonly RUN_ID=$(generate_run_id)
readonly EXP_DIR="${SCRIPT_DIR}/.data/${SCRIPT_NAME%.*}/$(date +"%Y-%m-%dT%H_%M_%S")-${RUN_ID}"
readonly RECEIPT_FILE="${EXP_DIR}/$(date +"%Y-%m-%dT%H_%M_%S")-${RUN_ID}.receipt"
readonly BUILD_SCAN_FILE="${EXP_DIR}/build-scans.csv"
readonly BUILD_CACHE_DIR="${EXP_DIR}/build-cache"
