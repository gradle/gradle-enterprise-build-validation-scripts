#!/usr/bin/env bash
#
# Runs Experiment 02 - Validate Gradle Build Caching - Local - In Place
#
# Invoke this script with --help to get a description of the command line arguments
#
readonly EXP_NAME="Validate Gradle Build Caching - Local - In Place"
readonly EXP_DESCRIPTION="Validating that a Gradle build is optimized for local in-place build caching"
readonly EXP_NO="02"
readonly EXP_SCAN_TAG=exp2-gradle
readonly BUILD_TOOL="Gradle"

# Needed to bootstrap the script
readonly SCRIPT_NAME=$(basename "$0")
readonly SCRIPT_DIR="$(cd "$(dirname "$(readlink -e "${BASH_SOURCE[0]}")")" && pwd)"
readonly LIB_DIR="${SCRIPT_DIR}/../lib"

# Include and parse the command line arguments
# shellcheck source=build-validation/scripts/lib/gradle/02-cli-parser.sh
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
  validate_required_config

  make_experiment_dir
  make_local_cache_dir
  git_clone_project ""

  print_bl
  execute_first_build
  print_bl
  execute_second_build

  print_warnings
  print_bl
  print_summary
  print_bl
}

wizard_execute() {
  print_bl
  print_introduction

  print_bl
  explain_collect_git_details
  print_bl
  collect_git_details

  print_bl
  explain_collect_gradle_details
  print_bl
  collect_gradle_details

  print_bl
  explain_clone_project
  print_bl
  make_experiment_dir
  make_local_cache_dir
  git_clone_project ""

  print_bl
  explain_first_build
  print_bl
  execute_first_build

  print_bl
  explain_second_build
  print_bl
  execute_second_build

  print_warnings
  explain_warnings

  print_bl
  explain_measure_build_results
  print_bl
  explain_and_print_summary
  print_bl
}

execute_first_build() {
  info "Running first build:"
  # The gradle --init-script flag only accepts a relative directory path. ¯\_(ツ)_/¯
  local lib_dir_rel
  lib_dir_rel="$(relative_lib_path)"

  info "./gradlew --build-cache --rerun-tasks -Dscan.tag.${EXP_SCAN_TAG} -Dscan.value.runId=${RUN_ID} clean ${tasks}$(print_extra_args)"

  invoke_gradle \
     --build-cache \
     --rerun-tasks \
     --init-script "${lib_dir_rel}/gradle/configure-local-build-caching.gradle" \
     clean "${tasks}"
}

execute_second_build() {
  info "Running second build:"
  # The gradle --init-script flag only accepts a relative directory path. ¯\_(ツ)_/¯
  local lib_dir_rel
  lib_dir_rel="$(relative_lib_path)"

  info "./gradlew --build-cache -Dscan.tag.${EXP_SCAN_TAG} -Dscan.value.runId=${RUN_ID} clean ${tasks}$(print_extra_args)"

  invoke_gradle \
     --build-cache \
     --init-script "${lib_dir_rel}/gradle/configure-local-build-caching.gradle" \
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
 summary_row "Cache performance:" "${base_urls[0]}/s/${build_scan_ids[1]}/performance/build-cache"
 summary_row "Executed tasks timeline:" "${base_urls[0]}/s/${build_scan_ids[1]}/timeline?outcome=SUCCESS,FAILED&sort=longest"
 summary_row "Task inputs comparison:" "${base_urls[0]}/c/${build_scan_ids[0]}/${build_scan_ids[1]}/task-inputs"
 summary_row "Executed cacheable tasks:" "${base_urls[0]}/s/${build_scan_ids[1]}/timeline?cacheableFilter=cacheable&outcomeFilter=SUCCESS,FAILED&sorted=longest"
 summary_row "Non-cacheable tasks:" "${base_urls[0]}/s/${build_scan_ids[1]}/timeline?cacheableFilter=any_non-cacheable&outcomeFilter=SUCCESS,FAILED&sorted=longest"
}

print_introduction() {
  local text
  IFS='' read -r -d '' text <<EOF
$(print_introduction_title)

In this experiment, you will validate how well a given project leverages
Gradle’s local build cache. A build is considered fully local-cache enabled if
all tasks avoid performing any work because:

  * The tasks' inputs have not changed since their last invocation and
  * The tasks' outputs are present in the local cache

The goal of the experiment is to first identify those tasks that do not reuse
outputs from the local cache, to then make an informed decision which of those
tasks are worth improving to make your build faster, to then investigate why
they did not reuse outputs, and to finally fix them once you understand the root
cause.

The experiment can be run on any developer’s machine. It logically consists of
the following steps:

  1. Run the Gradle build with the a typical task invocation including the 'clean' task
  2. Run the Gradle build with the same task invocation including the 'clean' task
  3. Determine which tasks are still executed in the second run and why
  4. Assess which of the executed tasks are worth improving

Step 1 and 2 should be executed with the local build cache enabled.

The script you have invoked automates the execution of step 1 and step 2 without
modifying the project. Build scans support your investigation in step 3 and step
4.

After improving the build to make it leverage the local build cache, you can
push your changes and run the experiment again. This creates a cycle of run →
measure → improve → run.

${USER_ACTION_COLOR}Press <Enter> to get started with the experiment.${RESTORE}
EOF

  print_wizard_text "${text}"
  wait_for_enter
}

explain_first_build() {
  local text
  IFS='' read -r -d '' text <<EOF
$(print_separator)
${HEADER_COLOR}Run first build${RESTORE}

Now that the project has been checked out, the first build can be run with the
given Gradle tasks. The build will be invoked with the 'clean' task included and
local build caching enabled.

To keep the experiment isolated and repeatable, a clean local build cache
directory was created.

${USER_ACTION_COLOR}Press <Enter> to run the first build.${RESTORE}
EOF
  print_wizard_text "${text}"
  wait_for_enter
}

explain_second_build() {
  local text
  IFS='' read -r -d '' text <<EOF
$(print_separator)
${HEADER_COLOR}Run second build${RESTORE}

Now that the first build has finished successfully, the second build can be run
with the same Gradle tasks.

${USER_ACTION_COLOR}Press <Enter> to run the second build.${RESTORE}
EOF
  print_wizard_text "$text"
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
from the cache and what tasks executed in the second build with cache misses,
which of those tasks had the biggest impact on build performance, and what
caused the cache misses.

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

