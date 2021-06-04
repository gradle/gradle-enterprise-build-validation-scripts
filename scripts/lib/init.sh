#!/usr/bin/env bash

make_experiment_dir() {
  mkdir -p "${EXP_DIR}"
  cd "${EXP_DIR}" || die "Unable to access the experiment dir (${EXP_DIR})." 2
  rm -f "${BUILD_SCAN_FILE}"
}

generate_run_id() {
  printf '%x' "$(date +%s)"
}

# Init common constants
RUN_ID=$(generate_run_id)
readonly RUN_ID
EXP_DIR="${SCRIPT_DIR}/.data/${SCRIPT_NAME%.*}/$(date +"%Y%m%dT%H%M%S")-${RUN_ID}"
readonly EXP_DIR
RECEIPT_FILE="${EXP_DIR}/${EXP_SCAN_TAG}-$(date +"%Y%m%dT%H%M%S").receipt"
readonly RECEIPT_FILE
BUILD_SCAN_FILE="${EXP_DIR}/build-scans.csv"
readonly BUILD_SCAN_FILE
BUILD_CACHE_DIR="${EXP_DIR}/build-cache"
readonly BUILD_CACHE_DIR

if [[ "${BUILD_TOOL}" == "Gradle" ]]; then
  BUILD_TOOL_TASK="task"
elif [[ "${BUILD_TOOL}" == "Gradle" ]]; then
  BUILD_TOOL_TASK="goal"
fi
readonly BUILD_TOOL_TASK
