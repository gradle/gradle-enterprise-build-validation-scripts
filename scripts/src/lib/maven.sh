#!/usr/bin/env bash

readonly CAPTURE_SCANS_EXTENSION_JAR="${LIB_DIR}/maven/capture-build-scans-maven-extension-1.0.0-SNAPSHOT.jar"

invoke_maven() {
  pushd "${project_dir}" > /dev/null 2>&1 || die "ERROR: The subdirectory ${project_dir} (set with --project-dir) does not exist in ${project_name}." 3

  ./mvnw \
      -Dmaven.ext.class.path="${CAPTURE_SCANS_EXTENSION_JAR}" \
      -Dscan.tag."${EXP_SCAN_TAG}" \
      -Dscan.tag."${RUN_ID}" \
      -Dorg.slf4j.simpleLogger.log.gradle.goal.cache=debug \
      "$@" \
      || die "ERROR: The experiment cannot continue because the build failed." $?

  #shellcheck disable=SC2164  # This is extremely unlikely to fail
  popd > /dev/null 2>&1
}

