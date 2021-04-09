#!/usr/bin/env bash

invoke_gradle() {
  # The gradle --init-script flag only accepts a relative directory path. ¯\_(ツ)_/¯
  local script_dir_rel
  script_dir_rel=$(realpath --relative-to="$( pwd )" "${script_dir}")
  ./gradlew \
      --init-script "${script_dir_rel}/lib/verify-ge-configured.gradle" \
      --init-script "${script_dir_rel}/lib/capture-build-scan-info.gradle" \
      -Dscan.tag.${EXP_SCAN_TAG} \
      -Dscan.tag."${RUN_ID}" \
      "$@" \
      || die "The experiment cannot continue because the build failed." 1
}
