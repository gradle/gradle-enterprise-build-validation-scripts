#!/usr/bin/env bash

invoke_gradle() {
  local args
  args=()

  pushd "${project_dir}" > /dev/null 2>&1 || die "ERROR: The subdirectory ${project_dir} (set with --project-dir) does not exist in ${project_name}." 3

  # The gradle --init-script flag only accepts a relative directory path. ¯\_(ツ)_/¯
  local lib_dir_rel
  lib_dir_rel="$(relative_lib_path)"

  if [ "$enable_ge" == "on" ]; then
    args+=(--init-script "${lib_dir_rel}/gradle/enable-gradle-enterprise.gradle")
  fi

  args+=(--init-script "${lib_dir_rel}/gradle/configure-gradle-enterprise.gradle")
  args+=(--init-script "${lib_dir_rel}/gradle/capture-published-build-scan.gradle")

  if [ -n "${ge_server}" ]; then
    args+=("-Pcom.gradle.enterprise.build_validation.server=${ge_server}")
  fi

  args+=(-Pcom.gradle.enterprise.build_validation.experimentDir="${EXP_DIR}")
  args+=(-Pcom.gradle.enterprise.build_validation.expId="${EXP_SCAN_TAG}")
  args+=(-Pcom.gradle.enterprise.build_validation.runId="${RUN_ID}")
  args+=(-Dscan.capture-task-input-files)

  # shellcheck disable=SC2206
  args+=(${extra_args})
  args+=("$@")

  rm -f "${EXP_DIR}/build-scan-publish-error.txt"

  debug ./gradlew "${args[@]}"

  if ./gradlew "${args[@]}"; then
      build_outcomes+=("SUCCESSFUL")
  else
      build_outcomes+=("FAILED")
  fi

  if [ -f "${EXP_DIR}/build-scan-publish-error.txt" ]; then
    die "ERROR: The experiment cannot continue because publishing the build scan failed." 2
  fi

  # defined in build_scan.sh
  read_build_data_from_current_dir

  #shellcheck disable=SC2164  # This is extremely unlikely to fail. and if it does, nothing really terrible will happen
  popd > /dev/null 2>&1
}

make_local_cache_dir() {
  rm -rf "${BUILD_CACHE_DIR}"
  mkdir -p "${BUILD_CACHE_DIR}"
}
