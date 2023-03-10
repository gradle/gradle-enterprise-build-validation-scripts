#!/usr/bin/env bash

readonly CAPTURE_BUILD_SCAN_URL_JAR="${LIB_DIR}/maven-libs/capture-build-scan-url-maven-extension-${SCRIPT_VERSION}.jar"

find_maven_executable() {
  if [ -f "./mvnw" ]; then
    echo "./mvnw"
  elif command -v mvn &> /dev/null; then
    echo "mvn"
  fi
}

invoke_maven() {
  local run_num args mvn
  args=()
  run_num=$1
  shift

  local original_dir
  if [ -n "${project_dir}" ]; then
    original_dir="$(pwd)"
    cd "${project_dir}" > /dev/null 2>&1 || die "ERROR: The subdirectory ${project_dir} (set with --project-dir) does not exist in ${project_name}." "${INVALID_INPUT}"
  fi

  mvn=$(find_maven_executable)
  if [ -z "$mvn" ]; then
    die "Unable to find the Maven executable. Add MAVEN_INSTALL_DIR/bin to your PATH environment variable, or install the Maven Wrapper."
  fi

  local extension_classpath
  extension_classpath="${CAPTURE_BUILD_SCAN_URL_JAR}"

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

  if [ "$build_scan_publishing_mode" == "on" ]; then
    args+=("-Dscan")
  else
    args+=("-Dscan.dump")
  fi

  args+=(
    -Dmaven.ext.class.path="${extension_classpath}"
    -Dcom.gradle.enterprise.build-validation.expDir="${EXP_DIR}"
    -Dcom.gradle.enterprise.build-validation.expId="${EXP_SCAN_TAG}"
    -Dcom.gradle.enterprise.build-validation.runId="${RUN_ID}"
    -Dcom.gradle.enterprise.build-validation.runNum="${run_num}"
    -Dcom.gradle.enterprise.build-validation.scriptsVersion="${SCRIPT_VERSION}"
    -Dgradle.scan.captureGoalInputFiles=true
  )

  if [ -n "${ge_server}" ]; then
    args+=("-Dgradle.enterprise.url=${ge_server}")
  fi

  # https://stackoverflow.com/a/31485948
  while IFS= read -r -d ''; do
    local extra_arg="$REPLY"
    if [ -n "$extra_arg" ]; then
      args+=("$extra_arg")
    fi
  done < <(xargs printf '%s\0' <<<"$extra_args")

  args+=("$@")

  debug "Current directory: $(pwd)"
  debug "${mvn}" "${args[@]}"
  if ${mvn} "${args[@]}"; then
    build_outcomes+=("SUCCESSFUL")
  else
    build_outcomes+=("FAILED")
  fi

  if is_build_scan_metadata_missing "$run_num"; then
    print_bl
    die "ERROR: The experiment cannot continue because of a non-recoverable failure while running the build."
  fi

  # defined in git.sh
  read_git_metadata_from_current_repo
  requested_tasks+=("${tasks}")

  if [ -n "${project_dir}" ]; then
    # shellcheck disable=SC2164 # We are just navigating back to the original directory
    cd "${original_dir}"
  fi
}
