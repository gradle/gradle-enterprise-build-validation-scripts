#!/usr/bin/env bash
#
# Runs Experiment 05 - Validate Gradle Remote Build Caching - CI and Local
#
# Invoke this script with --help to get a description of the command line arguments
#
readonly EXP_NAME="Validate Gradle Remote Build Caching - CI and Local"
readonly EXP_DESCRIPTION="Validating that a Gradle build is optimized for remote build caching when invoked on CI agent and local machine"
readonly EXP_NO="05"
readonly EXP_SCAN_TAG=exp5-gradle
readonly BUILD_TOOL="Gradle"
readonly SCRIPT_VERSION="<HEAD>"
readonly SHOW_RUN_ID=true

# Needed to bootstrap the script
SCRIPT_NAME=$(basename "$0")
readonly SCRIPT_NAME
SCRIPT_DIR="$(cd "$(dirname "$(readlink -e "${BASH_SOURCE[0]}")")" && pwd)"
readonly SCRIPT_DIR
readonly LIB_DIR="${SCRIPT_DIR}/../lib"

# Include and parse the command line arguments
# shellcheck source=lib/gradle/05-cli-parser.sh
source "${LIB_DIR}/gradle/${EXP_NO}-cli-parser.sh" || { echo "Couldn't find '${LIB_DIR}/gradle/${EXP_NO}-cli-parser.sh' parsing library."; exit 1; }
# shellcheck source=lib/libs.sh
source "${LIB_DIR}/libs.sh" || { echo "Couldn't find '${LIB_DIR}/libs.sh'"; exit 1; }

# These will be set by the config functions (see lib/config.sh)
git_repo=''
project_name=''
git_branch=''
project_dir=''
tasks=''
extra_args=''
enable_ge=''
ge_server=''
interactive_mode=''

ci_build_scan_url=''
mapping_file=''

main() {
  process_script_arguments
  if [ "${interactive_mode}" == "on" ]; then
    wizard_execute
  else
    execute
  fi
  create_receipt_file
}

execute() {
  print_bl
  validate_required_script_arguments
  fetch_build_scan_data
  validate_build_config

  print_bl
  make_experiment_dir
  git_checkout_project ""
  print_bl
  execute_build

  print_bl
  print_summary
  print_bl
}

wizard_execute() {
  print_bl
  print_introduction

  print_bl
  explain_collect_build_scan
  print_bl
  collect_build_scan
  collect_mapping_file

  print_bl
  fetch_build_scan_data

  print_bl
  explain_collect_git_details
  print_bl
  explain_git_repo_fetched_from_build_scan
  collect_git_repo
  explain_git_commit_fetched_from_build_scan
  collect_git_commit_id

  print_bl
  explain_collect_gradle_details
  print_bl
  collect_gradle_root_project_directory
  explain_gradle_tasks_fetched_from_build_scan
  collect_gradle_tasks
  collect_gradle_extra_args
  collect_remote_build_cache_shard

  print_bl
  explain_clone_project
  print_bl
  make_experiment_dir
  git_checkout_project ""

  print_bl
  explain_build
  print_bl
  execute_build

  print_bl
  explain_measure_build_results
  print_bl
  explain_and_print_summary
  print_bl
}

process_script_arguments() {
  ci_build_scan_url="${_arg_first_ci_build}"
  remote_build_cache_shard="${_arg_remote_build_cache_shard}"
  mapping_file="${_arg_mapping_file}"
}

validate_required_script_arguments() {
  if [ -z "${ci_build_scan_url}" ]; then
    _PRINT_HELP=yes die "ERROR: Missing required argument: --build-scan" 1
  fi
}

fetch_build_scan_data() {
  fetch_and_read_build_validation_data "${ci_build_scan_url}"

  if [ -z "${git_repo}" ]; then
    git_repo="${git_repos[0]}"
    project_name="$(basename -s .git "${git_repo}")"
  fi
  if [ -z "${git_branch}" ]; then
    git_branch="${git_branches[0]}"
  fi
  if [ -z "${git_commit_id}" ]; then
    git_commit_id="${git_commit_ids[0]}"
  fi
  if [ -z "${remote_build_cache_shard}" ]; then
    remote_build_cache_shard="${remote_build_cache_shards[0]}"
  fi
  if [ -z "${tasks}" ]; then
    tasks="${requested_tasks[0]}"
  fi
}

validate_build_config() {
  if [ -z "${git_repo}" ]; then
    _PRINT_HELP=yes die "ERROR: The Git repository URL was not found in the build scan. Please specify --git-repo and try again." 1
  fi
  if [ -z "${tasks}" ]; then
      _PRINT_HELP=yes die "ERROR: The Gradle tasks were not found in the build scan. Please specify --tasks and try again." 1
  fi
  if [ -z "${git_commit_id}" ]; then
      _PRINT_HELP=yes die "ERROR: The Git commit id was not found in the build scan. Please specify --git-commit-id and try again." 1
  fi

  if [[ "${enable_ge}" == "on" ]]; then
    if [ -z "${ge_server}" ]; then
      _PRINT_HELP=yes die "ERROR: --gradle-enterprise-server is required when using --enable-gradle-enterprise."
    fi
  fi
}

execute_build() {
  # The gradle --init-script flag only accepts a relative directory path. ¯\_(ツ)_/¯
  local lib_dir_rel args
  lib_dir_rel="$(relative_lib_path)"

  args=(--build-cache --init-script "${lib_dir_rel}/gradle/configure-remote-build-caching.gradle")
  if [ -n "${remote_build_cache_shard}" ]; then
    args+=("-Pcom.gradle.enterprise.build_validation.remoteBuildCacheShard=${remote_build_cache_shard}")
  fi

  # shellcheck disable=SC2206  # we want tasks to expand with word splitting in this case
  args+=(${tasks})

  info
  info "Running build:"
  info "./gradlew --build-cache -Dscan.tag.${EXP_SCAN_TAG} -Dscan.value.runId=${RUN_ID} ${tasks}$(print_extra_args)"

  invoke_gradle "${args[@]}"
}

# Overrides info.sh#print_experiment_specific_info
print_experiment_specific_info() {
  summary_row "Custom value mapping file:" "${mapping_file:-<none>}"
}

print_quick_links() {
  info "Investigation Quick Links"
  info "-------------------------"
  summary_row "Task execution overview:" "${base_urls[0]}/s/${build_scan_ids[1]}/performance/execution"
  summary_row "Executed tasks timeline:" "${base_urls[0]}/s/${build_scan_ids[1]}/timeline?outcome=SUCCESS,FAILED&sort=longest"
  summary_row "Executed cacheable tasks:" "${base_urls[0]}/s/${build_scan_ids[1]}/timeline?cacheability=cacheable,overlapping_outputs,validation_failure&outcome=SUCCESS,FAILED&sort=longest"
  summary_row "Executed non-cacheable tasks:" "${base_urls[0]}/s/${build_scan_ids[1]}/timeline?cacheability=any_non-cacheable&outcome=SUCCESS,FAILED&sort=longest"
  summary_row "Build caching statistics:" "${base_urls[0]}/s/${build_scan_ids[1]}/performance/build-cache"
  summary_row "Task inputs comparison:" "${base_urls[0]}/c/${build_scan_ids[0]}/${build_scan_ids[1]}/task-inputs?cacheability=cacheable"
}

print_introduction() {
  local text
  IFS='' read -r -d '' text <<EOF
$(print_introduction_title)

In this experiment, you will validate how well a given project leverages
Gradle's remote caching functionality to avoid doing unnecessary work that has
already been done on a CI server.

A build is considered fully remote cache enabled if all tasks avoid performing
any work because:

  * The tasks' inputs have not changed since their last invocation and
  * The tasks' outputs are present in the remote cache

The goal of the experiment is to first identify those tasks that do not reuse
outputs from the remote cache, to then make an informed decision which of those
tasks are worth improving to make your build faster, to then investigate why
they did not reuse outputs, and to finally fix them once you understand the root
cause.

This experiment consists of the following steps:

  1. On a Continuous Integration server, run the Gradle build with a typical
     task invocation
  2. Locally, check out the same commit that was built on the Continuous
     Integration server
  3. Locally, run the Gradle build with the same typical task invocation
     including the 'clean' task
  4. Determine which tasks are still executed in the second run and why
  5. Assess which of the executed tasks are worth improving

The script you have invoked automates the execution of step 2 and step 3,
without modifying the project. Step 1 must be completed prior to running this
script. Build scans support your investigation in step 4 and step 5.

After improving the build to make it more incremental, you can run the
experiment again. This creates a cycle of run → measure → improve → run → …

${USER_ACTION_COLOR}Press <Enter> to get started with the experiment.${RESTORE}
EOF

  print_wizard_text "${text}"
  wait_for_enter
}

explain_collect_build_scan() {
  local text
  IFS='' read -r -d '' text <<EOF
$(print_separator)
${HEADER_COLOR}Fetch build scan${RESTORE}

Data from the CI build scan (the build scan generated in step 1) will be used to
to lookup some of the parameters we will use to run the local build.

Some of the data is stored as custom values on the build scans. By default, this
script assumes the values have been created by the Common Custom User Data
Gradle plugin. If you are not using the plugin but the builds still publish the
same data using different names, then you can provide a mapping file so that the
script can still find the data.
EOF
  print_wizard_text "${text}"
}

collect_build_scan() {
  prompt_for_setting "What is the build scan for the CI server build?" "${_arg_first_ci_build}" "" ci_build_scan_url
}

# This overrides explain_collect_git_details found in lib/wizard.sh
explain_collect_git_details() {
  local text
  IFS='' read -r -d '' text <<EOF
$(print_separator)
${HEADER_COLOR}Configure local build${RESTORE}

The experiment will run against a fresh checkout of a given project stored in
Git. The fresh checkout ensures reproducibility of the experiment across
machines and users since no local changes and commits will be accidentally
included in the validation process.

The local build should be executed against the same commit the CI build ran
against.
EOF
  print_wizard_text "${text}"
}

explain_git_repo_fetched_from_build_scan() {
  if [ -n "${git_repos[0]}" ]; then
    wizard "The Git repository URL was extracted from the CI build scan. Press enter to use the same URL."
    print_bl
  fi
}

explain_git_commit_fetched_from_build_scan() {
  if [ -n "${git_commit_ids[0]}" ]; then
    print_bl
    wizard "The Git commit was extracted from the CI build scan. Press enter to build against the same commit."
    print_bl
  fi
}

# This overrides config.sh#collect_git_commit_id
collect_git_commit_id() {
  prompt_for_setting "What is the commit id for the Git repository that contains the project to validate?" "${git_commit_id}" "" git_commit_id
}

# This overrides explain_collect_gradle_details found in lib/wizard.sh
explain_collect_gradle_details() {
  local text
  IFS='' read -r -d '' text <<EOF
Once the project is checked out from Git, the experiment will invoke the
project’s contained Gradle build with a given set of tasks and an optional set
of arguments. The Gradle tasks to invoke should be the same, or very similar to
the tasks invoked by the CI build.

The build will be invoked from the project’s root directory or from a given
sub-directory.
EOF
  print_wizard_text "${text}"
}

explain_gradle_tasks_fetched_from_build_scan() {
  if [ -n "${requested_tasks[0]}" ]; then
    print_bl
    wizard "The Gradle tasks to invoke were extracted from the CI build scan. Press enter to run the local build \
with the same Gradle tasks, or enter a different set of tasks if it is not appropriate to use the the \
same tasks locally."
    print_bl
  fi
}

collect_remote_build_cache_shard() {
  local default_remote_cache="<none>"
  prompt_for_setting "What is the remote build cache shard to use?" "${remote_build_cache_shard}" "${default_remote_cache}" remote_build_cache_shard

  if [[ "${remote_build_cache_shard}" == "${default_remote_cache}" ]]; then
    remote_build_cache_shard=''
  fi
}

# This overrides explain_collect_gradle_details found in lib/wizard.sh
explain_clone_project() {
  local text
  IFS='' read -r -d '' text <<EOF
$(print_separator)
${HEADER_COLOR}Check out project from Git${RESTORE}

All configuration to run the local build has been collected. In the next
step of the experiment, the Git repository that contains the project to
validate will be checked out.

${USER_ACTION_COLOR}Press <Enter> to check out the project from Git.${RESTORE}
EOF
  print_wizard_text "${text}"
  wait_for_enter
}

explain_build() {
  local text
  IFS='' read -r -d '' text <<EOF
$(print_separator)
${HEADER_COLOR}Run local build${RESTORE}

Now that the project has been checked out, the local build can be run with the
given Gradle tasks.

${USER_ACTION_COLOR}Press <Enter> to run the local build of the experiment.${RESTORE}
EOF
  print_wizard_text "${text}"
  wait_for_enter
}

explain_measure_build_results() {
  local text
  IFS='' read -r -d '' text <<EOF
$(print_separator)
${HEADER_COLOR}Measure build results${RESTORE}

Now that the local build has finished successfully, you are ready to measure in
Gradle Enterprise how well your build leverages Gradle’s remote build cache for
the invoked set of Gradle tasks.

${USER_ACTION_COLOR}Press <Enter> to measure the build results.${RESTORE}
EOF
  print_wizard_text "${text}"
  wait_for_enter
}

#Overrides config.sh#print_command_to_repeat_experiment
print_command_to_repeat_experiment() {
  local cmd
  cmd=("./${SCRIPT_NAME}")

  if [ -n "${git_repo}" ] && [[ "${git_repo}" != "${git_repos[0]}" ]]; then
    cmd+=("-r" "${git_repo}")
  fi

  if [ -n "${git_branch}" ] && [[ "${git_branch}" != "${git_branches[0]}" ]]; then
    cmd+=("-b" "${git_branch}")
  fi

  if [ -n "${git_commit_id}" ] && [[ "${git_commit_id}" != "${git_commit_ids[0]}" ]]; then
    cmd+=("-c" "${git_commit_id}")
  fi

  if [ -n "${project_dir}" ]; then
    cmd+=("-p" "${project_dir}")
  fi

  if [ -n "${tasks}" ] && [[ "${tasks}" != "${requested_tasks[0]}" ]]; then
    cmd+=("-t" "${tasks}")
  fi

  if [ -n "${extra_args}" ]; then
    cmd+=("-a" "${extra_args}")
  fi

  if [ -n "${ci_build_scan_url}" ]; then
    cmd+=("-B" "${ci_build_scan_url}")
  fi

  if [ -n "${mapping_file}" ]; then
    cmd+=("-m" "${mapping_file}")
  fi

  if [ -n "${remote_build_cache_shard}" ]; then
    cmd+=("-u" "${remote_build_cache_shard}")
  fi

  if [ -n "${ge_server}" ]; then
    cmd+=("-s" "${ge_server}")
  fi

  if [[ "${enable_ge}" == "on" ]]; then
    cmd+=("-e")
  fi

  info "Command Line Invocation"
  info "-----------------------"
  info "$(printf '%q ' "${cmd[@]}")"
}

explain_and_print_summary() {
  read_build_scan_metadata
  local text
  IFS='' read -r -d '' text <<EOF
The 'Summary' section below captures the configuration of the experiment and the
two build scans that were published as part of running the experiment.  The
build scan of the second build is particularly interesting since this is where
you can inspect what tasks were not leveraging Gradle’s local build cache.

The 'Investigation Quick Links' section below allows quick navigation to the
most relevant views in build scans to investigate what task outputs were fetched
from the remote cache and what tasks executed in the second build with cache
misses, which of those tasks had the biggest impact on build performance, and
what caused the cache misses.

The 'Command Line Invocation' section below demonstrates how you can rerun the
experiment with the same configuration and in non-interactive mode.

$(print_summary)

$(print_command_to_repeat_experiment)

Once you have addressed the issues surfaced in build scans and pushed the
changes to your Git repository, you can rerun the experiment and start over the
cycle of run → measure → improve → run.
EOF
  print_wizard_text "${text}"
}

process_arguments "$@"
main

