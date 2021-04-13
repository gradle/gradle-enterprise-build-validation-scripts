#!/usr/bin/env bash

CAPTURE_SCANS_EXTENSION_DIR="${LIB_DIR}/capture-scans-maven-extension"
CAPTURE_SCANS_EXTENSION_JAR="${CAPTURE_SCANS_EXTENSION_DIR}/target/capture-build-scans-extension-1.0.0-SNAPSHOT.jar"

make_maven_extensions() {
  info "Building Maven extensions"
  cd "${CAPTURE_SCANS_EXTENSION_DIR}"
  ./mvnw clean package > "${EXPERIMENT_DIR}/capture-scans-maven-extension.log"
}

invoke_maven() {
  echo "$@"
  ./mvnw \
      -Dmaven.ext.class.path="${CAPTURE_SCANS_EXTENSION_JAR}" \
      -Dscan.tag.${EXP_SCAN_TAG} \
      -Dscan.tag."${RUN_ID}" \
      -Dorg.slf4j.simpleLogger.log.gradle.goal.cache=debug \
      "$@" \
      || die "The experiment cannot continue because the build failed." 1
}

