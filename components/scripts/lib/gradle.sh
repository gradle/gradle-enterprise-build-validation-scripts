#!/usr/bin/env bash

init_scripts_path() {
  # The gradle --init-script flag only accepts a relative directory path. ¯\_(ツ)_/¯
  lib_dir_rel="$(relative_lib_path)"
  echo "${lib_dir_rel}/gradle-init-scripts"
}

invoke_gradle() {
  local args
  args=()

  local init_scripts_dir
  init_scripts_dir="$(init_scripts_path)"

  pushd "${project_dir}" > /dev/null 2>&1 || die "ERROR: The subdirectory ${project_dir} (set with --project-dir) does not exist in ${project_name}." "${INVALID_INPUT}"

  if [ "$enable_ge" == "on" ]; then
    args+=(--init-script "${init_scripts_dir}/enable-gradle-enterprise.gradle")
  fi

  if [ "$build_scan_publishing_mode" == "off" ]; then
    args+=("-Dscan.dump")
  fi

  args+=(--init-script "${init_scripts_dir}/configure-gradle-enterprise.gradle")
  args+=(--init-script "${init_scripts_dir}/capture-published-build-scan.gradle")

  if [ -n "${ge_server}" ]; then
    args+=("-Pcom.gradle.enterprise.build_validation.server=${ge_server}")
  fi

  args+=(
    --scan
    -Pcom.gradle.enterprise.build_validation.experimentDir="${EXP_DIR}"
    -Pcom.gradle.enterprise.build_validation.expId="${EXP_SCAN_TAG}"
    -Pcom.gradle.enterprise.build_validation.runId="${RUN_ID}"
    -Dscan.capture-task-input-files=true
  )

  # shellcheck disable=SC2206
  args+=(${extra_args})
  args+=("$@")

  rm -f "${EXP_DIR}/build-scan-publish-error.txt"

  debug "Current directory: $(pwd)"
  debug ./gradlew "${args[@]}"

  if ./gradlew "${args[@]}"; then
      build_outcomes+=("SUCCESSFUL")
  else
      build_outcomes+=("FAILED")
  fi

  if [ -f "${EXP_DIR}/build-scan-publish-error.txt" ] && [[ "${build_scan_publishing_mode}" == "on" ]]; then
    die "ERROR: The experiment cannot continue because publishing the build scan failed."
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
