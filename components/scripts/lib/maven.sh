#!/usr/bin/env bash

readonly CAPTURE_BUILD_SCANS_EXTENSION_JAR="${LIB_DIR}/maven-libs/capture-published-build-scan-maven-extension-${SCRIPT_VERSION}.jar"

find_maven_executable() {
  if [ -f "./mvnw" ]; then
    echo "./mvnw"
  elif command -v mvn &> /dev/null; then
    echo "mvn"
  fi
}

invoke_maven() {
  local args mvn
  args=()

  pushd "${project_dir}" > /dev/null 2>&1 || die "ERROR: The subdirectory ${project_dir} (set with --project-dir) does not exist in ${project_name}." 3

  mvn=$(find_maven_executable)
  if [ -z "$mvn" ]; then
    die "Unable to find the Maven executable. Add MAVEN_INSTALL_DIR/bin to your PATH environment variable, or install the Maven Wrapper." 2
  fi

  local extension_classpath
  extension_classpath="${CAPTURE_BUILD_SCANS_EXTENSION_JAR}"

  if [ "$enable_ge" == "on" ]; then
    # Reset the extension classpath and add all of the jars in the lib/maven dir
    # The lib/maven dir includes:
    #  - the Gradle Enterprise Maven extension
    #  - the Common Custom User Data Maven extension
    #  - the capture-publish-build-scan Maven extension
    extension_classpath=""
    for jar in "${LIB_DIR}"/maven-libs/*; do
      if [ "${extension_classpath}" == "" ]; then
        extension_classpath="${jar}"
      else
        extension_classpath="${extension_classpath}:${jar}"
      fi
    done
  fi

  args+=(
    -Dmaven.ext.class.path="${extension_classpath}"
    -Dcom.gradle.enterprise.build_validation.experimentDir="${EXP_DIR}"
    "-Dscan.tag.${EXP_SCAN_TAG}"
    "-Dscan.value.Experiment id=${EXP_SCAN_TAG}"
    "-Dscan.value.Experiment run id=${RUN_ID}"
    -Dorg.slf4j.simpleLogger.log.gradle.goal.cache=debug
  )
  if [ -n "${ge_server}" ]; then
    args+=("-Dgradle.enterprise.url=${ge_server}")
  fi

  # shellcheck disable=SC2206
  args+=(${extra_args})
  args+=("$@")

  debug "Current directory: $(pwd)"
  debug "${mvn}" "${args[@]}"
  if ${mvn} "${args[@]}"; then
    build_outcomes+=("SUCCESSFUL")
  else
    build_outcomes+=("FAILED")
  fi

  # defined in build_scan.sh
  read_build_data_from_current_dir

  #shellcheck disable=SC2164  # This is extremely unlikely to fail, and even if it does, nothing terrible will happen.
  popd > /dev/null 2>&1
}
