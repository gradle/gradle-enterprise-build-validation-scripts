#!/usr/bin/env bash

CAPTURE_SCANS_EXTENSION_JAR="${LIB_DIR}/maven/capture-build-scans-maven-extension-1.0.0-SNAPSHOT.jar"

invoke_maven() {
  ./mvnw \
      -Dmaven.ext.class.path="${CAPTURE_SCANS_EXTENSION_JAR}" \
      -Dscan.tag.${EXP_SCAN_TAG} \
      -Dscan.tag."${RUN_ID}" \
      -Dorg.slf4j.simpleLogger.log.gradle.goal.cache=debug \
      "$@" \
      || die "ERROR: The experiment cannot continue because the build failed." $?
}

