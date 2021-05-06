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
readonly BUILD_SCAN_FILE="${EXP_DIR}/build-scans.csv"
