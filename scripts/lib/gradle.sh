#!/usr/bin/env bash

invoke_gradle() {
  local ge_server_arg
  ge_server_arg=""
  if [ -n "${ge_server}" ]; then
    ge_server_arg="-Pcom.gradle.enterprise.init.script.server=${ge_server}"
  fi

  pushd "${project_dir}" > /dev/null 2>&1 || die "ERROR: The subdirectory ${project_dir} (set with --project-dir) does not exist in ${project_name}." 3

  # The gradle --init-script flag only accepts a relative directory path. ¯\_(ツ)_/¯
  local lib_dir_rel
  lib_dir_rel="$(relative_lib_path)"

  local enable_ge_init_script
  if [ "$enable_ge" == "on" ]; then
    # FIXME This doesn't handle paths with spaces in it very well. Figure out how to do the shell qouting properly!
    enable_ge_init_script="--init-script ${lib_dir_rel}/gradle/enable-gradle-enterprise.gradle"
  fi

  rm -f "${EXP_DIR}/build-scan-publish-error.txt"

  # shellcheck disable=SC2086
  ./gradlew \
      ${enable_ge_init_script} \
      --init-script "${lib_dir_rel}/gradle/configure-gradle-enterprise.gradle" \
      --init-script "${lib_dir_rel}/gradle/capture-build-scans.gradle" \
      ${ge_server_arg} \
      -Pcom.gradle.enterprise.init.script.experimentDir="${EXP_DIR}" \
      -Dscan.tag.${EXP_SCAN_TAG} \
      -Dscan.tag."${RUN_ID}" \
      -Dscan.capture-task-input-files \
      ${extra_args} \
      "$@" \
      || die "ERROR: The experiment cannot continue because the build failed." $?

  if [ -f "${EXP_DIR}/build-scan-publish-error.txt" ]; then
    die "ERROR: The experiment cannot continue because publishing the build scan failed." 2
  fi

  #shellcheck disable=SC2164  # This is extremely unlikely to fail
  popd > /dev/null 2>&1
}

make_local_cache_dir() {
  local build_cache_dir="$1"
  rm -rf "${build_cache_dir}"
  mkdir -p "${build_cache_dir}"
}
