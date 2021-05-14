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

# Needed to bootstrap the script
readonly SCRIPT_NAME=$(basename "$0")
readonly SCRIPT_DIR="$(cd "$(dirname "$(readlink -e "${BASH_SOURCE[0]}")")" && pwd)"
readonly LIB_DIR="${SCRIPT_DIR}/../lib"

# Include and parse the command line arguments
# shellcheck source=build-validation/scripts/lib/gradle/05-cli-parser.sh
source "${LIB_DIR}/gradle/${EXP_NO}-cli-parser.sh" || { echo "Couldn't find '${LIB_DIR}/gradle/${EXP_NO}-cli-parser.sh' parsing library."; exit 1; }
# shellcheck source=build-validation/scripts/lib/libs.sh
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
commit_id=''
mapping_file=''

main() {
  if [ "${interactive_mode}" == "on" ]; then
    wizard_execute
  else
    execute
  fi
  create_receipt_file
}

execute() {
  print_bl
  validate_required_args
  fetch_build_scan_data
  validate_required_config

  make_experiment_dir

  git_clone_project ""
  git_checkout_commit "${commit_id}"
  print_bl
  execute_build

  print_warnings
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
  fetch_build_scan_data

  collect_git_details

  print_bl
  explain_collect_gradle_details
  print_bl
  collect_gradle_details

  print_bl
  explain_clone_project
  print_bl
  make_experiment_dir
  git_clone_project ""

  print_bl
  explain_build
  print_bl
  execute_build

  print_warnings
  explain_warnings

  print_bl
  explain_measure_build_results
  print_bl
  explain_and_print_summary
  print_bl
}

validate_required_args() {
  if [ -z "${_arg_build_scan}" ]; then
    _PRINT_HELP=yes die "ERROR: Missing required argument: --build-scan" 1
  fi
  ci_build_scan_url="${_arg_build_scan}"
}

fetch_build_scan_data() {
  mapping_file="${_arg_mapping_file}"
  fetch_and_read_build_validation_data "${ci_build_scan_url}"

  if [ -z "${git_repo}" ]; then
    git_repo="${git_repos[0]}"
    project_name="$(basename -s .git "${git_repo}")"
  fi
  if [ -z "${git_branch}" ]; then
    git_branch="${git_branches[0]}"
  fi
  if [ -z "${commit_id}" ]; then
    commit_id="${git_commit_ids[0]}"
  fi
  if [ -z "${tasks}" ]; then
    tasks="${requested_tasks[0]}"
  fi
}

execute_build() {
  # The gradle --init-script flag only accepts a relative directory path. ¯\_(ツ)_/¯
  local lib_dir_rel
  lib_dir_rel="$(relative_lib_path)"

  info
  info "Running build:"
  info "./gradlew --build-cache -Dscan.tag.${EXP_SCAN_TAG} -Dscan.value.runId=${RUN_ID} clean ${tasks}$(print_extra_args)"

  invoke_gradle \
     --build-cache \
     --init-script "${lib_dir_rel}/gradle/configure-remote-build-caching.gradle" \
     clean "${tasks}"
}

print_summary() {
 read_build_scan_metadata
 print_experiment_info
 print_build_scans
 print_bl
 print_quick_links
}

print_build_scans() {
 summary_row "Build scan first build:" "${build_scan_urls[0]}"
 summary_row "Build scan second build:" "${build_scan_urls[1]}"
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

A build is considered fully remote cache enabled if all tasks avoid performing any
work because:

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

collect_build_scan() {
  prompt_for_setting "What is the build scan for the CI server build?" "${_arg_build_scan}" "" ci_build_scan_url
}

explain_collect_build_scan() {
  local text
  IFS='' read -r -d '' text <<EOF
$(print_separator)
${HEADER_COLOR}Configure experiment${RESTORE}
Data from the CI build scan (the build scan generated in step 1) will be used to
to lookup:

  * the commit ID the CI build ran against
  * the tasks and arguments the CI build invoked Gradle with

EOF
  print_wizard_text "${text}"
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

