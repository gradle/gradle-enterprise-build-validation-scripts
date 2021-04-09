#!/usr/bin/env bash

make_experiment_dir() {
  mkdir -p "${experiment_dir}"
  rm -f "${scan_file}"
}

