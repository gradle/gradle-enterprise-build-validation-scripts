#!/usr/bin/env bash

invoke_gradle() {
  local run_num args
  args=()
  run_num=$1
  shift

  local original_dir
  if [ -n "${project_dir}" ]; then
    original_dir="$(pwd)"
    cd "${project_dir}" > /dev/null 2>&1 || die "ERROR: The subdirectory ${project_dir} (set with --project-dir) does not exist in ${project_name}." "${INVALID_INPUT}"
  fi

  args+=(--init-script "${INIT_SCRIPTS_DIR}/configure-gradle-enterprise.gradle")

  if [ "$enable_ge" == "on" ]; then
    args+=("-Dcom.gradle.enterprise.build_validation.gradle.plugin-repository.url=https://plugins.gradle.org/m2")
    args+=("-Dcom.gradle.enterprise.build_validation.gradle-enterprise.plugin.version=3.12.4")
    args+=("-Dcom.gradle.enterprise.build_validation.ccud.plugin.version=1.9")
  fi

  if [ -n "${ge_server}" ]; then
    args+=("-Dcom.gradle.enterprise.build_validation.gradle-enterprise.url=${ge_server}")
    args+=("-Dcom.gradle.enterprise.build_validation.gradle-enterprise.allow-untrusted-server=false")
  fi

  if [[ "${build_scan_publishing_mode}" == "off" ]]; then
    args+=("-Dscan.dump")
  fi

  args+=(
    -Dcom.gradle.enterprise.build_validation.experimentDir="${EXP_DIR}"
    -Dcom.gradle.enterprise.build_validation.expId="${EXP_SCAN_TAG}"
    -Dcom.gradle.enterprise.build_validation.runId="${RUN_ID}"
    -Dcom.gradle.enterprise.build_validation.runNum="${run_num}"
    -Dscan.capture-task-input-files=true
  )

  # https://stackoverflow.com/a/31485948
  while IFS= read -r -d ''; do
    args+=( "$REPLY" )
  done < <(xargs printf '%s\0' <<<"$extra_args")

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

  if [ -n "${project_dir}" ]; then
    # shellcheck disable=SC2164 # We are just navigating back to the original directory
    cd "${original_dir}"
  fi
}

make_local_cache_dir() {
  rm -rf "${BUILD_CACHE_DIR}"
  mkdir -p "${BUILD_CACHE_DIR}"
}
