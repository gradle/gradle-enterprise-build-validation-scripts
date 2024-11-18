#!/usr/bin/env bash

invoke_gradle() {
  local run_num
  run_num=$1
  shift

  local original_dir
  if [ -n "${project_dir}" ]; then
    original_dir="$(pwd)"
    cd "${project_dir}" > /dev/null 2>&1 || die "ERROR: Subdirectory ${project_dir} (set with --project-dir) does not exist in ${project_name}" "${INVALID_INPUT}"
  fi

  envs+=(
    DEVELOCITY_INJECTION_INIT_SCRIPT_NAME=develocity-injection.gradle
    DEVELOCITY_INJECTION_ENABLED=true
  )

  if [ "$enable_ge" == "on" ]; then
    envs+=(
      GRADLE_PLUGIN_REPOSITORY_URL=https://plugins.gradle.org/m2
      DEVELOCITY_PLUGIN_VERSION="3.14.1"
      DEVELOCITY_CCUD_PLUGIN_VERSION="2.0.2"
    )
  fi

  if [ -n "${ge_server}" ]; then
    envs+=(
      DEVELOCITY_BUILD_VALIDATION_URL="${ge_server}"
      DEVELOCITY_BUILD_VALIDATION_ALLOW_UNTRUSTED_SERVER=false
    )
  fi

  if [ -n "${remote_build_cache_url}" ]; then
    envs+=(
      DEVELOCITY_BUILD_VALIDATION_REMOTEBUILDCACHEURL="${remote_build_cache_url}"
    )
  fi

  envs+=(
    DEVELOCITY_BUILD_VALIDATION_EXPDIR="${EXP_DIR}"
    DEVELOCITY_BUILD_VALIDATION_EXPID="${EXP_SCAN_TAG}"
    DEVELOCITY_BUILD_VALIDATION_RUNID="${RUN_ID}"
    DEVELOCITY_BUILD_VALIDATION_RUNNUM="${run_num}"
    DEVELOCITY_BUILD_VALIDATION_SCRIPTSVERSION="${SCRIPT_VERSION}"
    DEVELOCITY_CAPTURE_FILE_FINGERPRINTS=true
  )

  local args
  args=(
    --init-script "${INIT_SCRIPTS_DIR}/develocity-injection.gradle"
    --init-script "${INIT_SCRIPTS_DIR}/configure-build-validation.gradle"
    -Dpts.enabled=false
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
  # shellcheck disable=SC2145
  debug export "${envs[@]}"';' ./gradlew "${args[@]}"

  # The parenthesis below will intentionally create a subshell. This causes the
  # environment variables to only be exported for the child process and not leak
  # to the rest of the script.
  if (export "${envs[@]}"; ./gradlew "${args[@]}"); then
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

make_local_cache_dir() {
  rm -rf "${BUILD_CACHE_DIR}"
  mkdir -p "${BUILD_CACHE_DIR}"
}
