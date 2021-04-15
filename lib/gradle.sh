#!/usr/bin/env bash

invoke_gradle() {
  local ge_server_arg
  ge_server_arg=""
  if [ -n "${_arg_server}" ]; then
    ge_server_arg="-Pcom.gradle.enterprise.init.script.server=${_arg_server}"
  fi
  

  # The gradle --init-script flag only accepts a relative directory path. ¯\_(ツ)_/¯
  local lib_dir_rel
  lib_dir_rel=$(realpath --relative-to="$( pwd )" "${LIB_DIR}")
  ./gradlew \
      --init-script "${lib_dir_rel}/gradle/verify-ge-configured.gradle" \
      --init-script "${lib_dir_rel}/gradle/capture-build-scan-info.gradle" \
      ${ge_server_arg} \
      -Dscan.tag.${EXP_SCAN_TAG} \
      -Dscan.tag."${RUN_ID}" \
      -Dscan.capture-task-input-files \
      "$@" \
      || die "The experiment cannot continue because the build failed." 1
}

make_local_cache_dir() {
  rm -rf "${build_cache_dir}"
  mkdir -p "${build_cache_dir}"
}

