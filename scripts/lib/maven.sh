#!/usr/bin/env bash

readonly CAPTURE_SCANS_EXTENSION_JAR="${LIB_DIR}/maven/capture-published-build-scan-maven-extension-1.0.0-SNAPSHOT.jar"

invoke_maven() {
  local args
  args=()

  pushd "${project_dir}" > /dev/null 2>&1 || die "ERROR: The subdirectory ${project_dir} (set with --project-dir) does not exist in ${project_name}." 3

  args+=(
    -Dmaven.ext.class.path="${CAPTURE_SCANS_EXTENSION_JAR}"
    -Dscan.tag."${EXP_SCAN_TAG}"
    -Dscan.tag."${RUN_ID}"
    -Dorg.slf4j.simpleLogger.log.gradle.goal.cache=debug
  )
  if [ -n "${ge_server}" ]; then
    args+=("-Dgradle.enterprise.url=${ge_server}")
  fi

  # shellcheck disable=SC2206
  args+=(${extra_args})
  args+=("$@")

  debug ./mvnw "${args[@]}"
  ./mvnw "${args[@]}" || die "ERROR: The experiment cannot continue because the build failed." $?

  #shellcheck disable=SC2164  # This is extremely unlikely to fail, and even if it does, nothing terrible will happen.
  popd > /dev/null 2>&1
}

