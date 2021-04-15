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

  local enable_ge_init_script
  enable_ge_init_script=""

  if [ "$_arg_enable_gradle_enterprise" == "on" ]; then
    # FIXME This doesn't handle paths with spaces in it very well. Figure out how to do the shell qouting properly!
    enable_ge_init_script="--init-script ${lib_dir_rel}/gradle/enable-gradle-enterprise.gradle"
  fi

  ./gradlew \
      ${enable_ge_init_script} \
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

