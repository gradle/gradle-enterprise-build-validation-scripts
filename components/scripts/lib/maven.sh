#!/usr/bin/env bash

readonly CONFIGURE_GRADLE_ENTERPRISE_JAR="${LIB_DIR}/maven-libs/configure-gradle-enterprise-maven-extension-${SCRIPT_VERSION}.jar"

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
    cd "${project_dir}" > /dev/null 2>&1 || die "ERROR: Subdirectory ${project_dir} (set with --project-dir) does not exist in ${project_name}" "${INVALID_INPUT}"
  fi

  mvn=$(find_maven_executable)
  if [ -z "$mvn" ]; then
    die "Unable to find the Maven executable. Add MAVEN_INSTALL_DIR/bin to your PATH environment variable, or install the Maven Wrapper."
  fi

  local extension_classpath
  extension_classpath="${CONFIGURE_GRADLE_ENTERPRISE_JAR}"

  if [ "$enable_ge" == "on" ]; then
    # Reset the extension classpath and add all of the jars in the lib/maven dir
    # The lib/maven dir includes:
    #  - the Gradle Enterprise Maven extension
    #  - the Common Custom User Data Maven extension
    #  - the configure-gradle-enterprise Maven extension
    extension_classpath=""
    for jar in "${LIB_DIR}"/maven-libs/*; do
      if [ "${extension_classpath}" == "" ]; then
        extension_classpath="${jar}"
      else
        extension_classpath="${extension_classpath}:${jar}"
      fi
    done
  fi

  if [ -n "${ge_server}" ]; then
    args+=("-Dgradle.enterprise.url=${ge_server}")
    args+=("-Dgradle.enterprise.allowUntrustedServer=false")
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

  # https://stackoverflow.com/a/31485948
  while IFS= read -r -d ''; do
    local extra_arg="$REPLY"
    if [ -n "$extra_arg" ]; then
      args+=("$extra_arg")
    fi
  done < <(xargs printf '%s\0' <<<"$extra_args")

  args+=("$@")

  rm -f "${EXP_DIR}/errors.txt"

  debug "Current directory: $(pwd)"
  debug "${mvn}" "${args[@]}"

  if ${mvn} "${args[@]}"; then
    build_outcomes+=("SUCCESSFUL")
  else
    build_outcomes+=("FAILED")
  fi

  if [ -f "${EXP_DIR}/errors.txt" ]; then
      print_bl
      die "ERROR: Experiment aborted due to a non-recoverable failure: $(cat "${EXP_DIR}/errors.txt")"
  fi

  if is_build_scan_metadata_missing "$run_num"; then
      print_bl
      die "ERROR: Experiment aborted due to a non-recoverable failure: No Build Scan was published"
  fi

  # defined in git.sh
  read_git_metadata_from_current_repo
  requested_tasks+=("${tasks}")

  if [ -n "${project_dir}" ]; then
    # shellcheck disable=SC2164 # We are just navigating back to the original directory
    cd "${original_dir}"
  fi
}
