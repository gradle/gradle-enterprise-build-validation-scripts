#!/usr/bin/env bash

make_experiment_dir() {
  mkdir -p "${EXP_DIR}"
  cd "${EXP_DIR}"
  rm -f "${BUILD_SCAN_FILE}"
}

generate_run_id() {
  printf '%x' "$(date +%s)"
}

# Init common constants
readonly EXP_DIR="${SCRIPT_DIR}/.data/${SCRIPT_NAME%.*}/$(date +"%Y%m%dT%H%M%S")-${RUN_ID}"
readonly RECEIPT_FILE="${EXP_DIR}/${EXP_SCAN_TAG}-$(date +"%Y%m%dT%H%M%S").receipt"
readonly BUILD_SCAN_FILE="${EXP_DIR}/build-scans.csv"
readonly BUILD_CACHE_DIR="${EXP_DIR}/build-cache"

if [[ "${BUILD_TOOL}" == "Gradle" ]]; then
  readonly BUILD_TOOL_TASK="task"
elif [[ "${BUILD_TOOL}" == "Gradle" ]]; then
  readonly BUILD_TOOL_TASK="goal"
fi
