#!/usr/bin/env bash

make_experiment_dir() {
  mkdir -p "${EXPERIMENT_DIR}"
  rm -f "${SCAN_FILE}"
}

generate_run_id() {
  printf '%x' $(date +%s)
}
