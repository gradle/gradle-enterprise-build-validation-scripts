#!/usr/bin/env bash
#
# Runs Experiment 01 - Validate incremental building
#
# Invoke this script with --help to get a description of the command line arguments
#
readonly EXP_NAME="Validate incremental building"
readonly EXP_DESCRIPTION="Validating that a Gradle build is optimized for incremental building"
readonly EXP_NO="01"
readonly EXP_SCAN_TAG=exp1-gradle
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
# shellcheck source=lib/gradle/01-cli-parser.sh
source "${LIB_DIR}/gradle/${EXP_NO}-cli-parser.sh" || { echo "Couldn't find '${LIB_DIR}/gradle/${EXP_NO}-cli-parser.sh' library."; exit 1; }
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
  git_checkout_project ""

  print_bl
  execute_first_build
  print_bl
  execute_second_build

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
  git_checkout_project ""

  print_bl
  explain_first_build
  print_bl
  execute_first_build

  print_bl
  explain_second_build
  print_bl
  execute_second_build

  print_bl
  explain_measure_build_results
  print_bl
  explain_and_print_summary
  print_bl
}

execute_first_build() {
  info "Running first build:"
  info "./gradlew --no-build-cache -Dscan.tag.${EXP_SCAN_TAG} -Dscan.value.runId=${RUN_ID} clean ${tasks}$(print_extra_args)"

  # shellcheck disable=SC2086  # we want tasks to expand with word splitting in this case
  invoke_gradle --no-build-cache clean ${tasks}
}

execute_second_build() {
  info "Running second build:"
  info "./gradlew --no-build-cache -Dscan.tag.${EXP_SCAN_TAG} -Dscan.value.runId=${RUN_ID} ${tasks}$(print_extra_args)"

  # shellcheck disable=SC2086  # we want tasks to expand with word splitting in this case
  invoke_gradle --no-build-cache ${tasks}
}

print_quick_links() {
  info "Investigation Quick Links"
  info "-------------------------"
  summary_row "Task execution overview:" "${base_urls[0]}/s/${build_scan_ids[1]}/performance/execution"
  summary_row "Executed tasks timeline:" "${base_urls[0]}/s/${build_scan_ids[1]}/timeline?outcome=SUCCESS,FAILED&sort=longest"
  summary_row "Task inputs comparison:" "${base_urls[0]}/c/${build_scan_ids[0]}/${build_scan_ids[1]}/task-inputs"
}

print_introduction() {
  local text
  IFS='' read -r -d '' text <<EOF
$(print_introduction_title)

In this experiment, you will validate how well a given project leverages
Gradle’s incremental build functionality. A build is considered fully
incremental if it can be invoked twice in a row with build caching disabled and
all tasks avoid performing any work because:

  * The tasks' inputs have not changed since their last invocation and
  * The tasks' outputs are still present

The experiment will reveal tasks with volatile inputs, for example tasks that
contain a timestamp in one of their inputs. It will also reveal tasks that produce
non-deterministic outputs consumed by tasks downstream that participate in
incremental building, for example tasks generating code with non-deterministic
method ordering or tasks producing artifacts that include timestamps.

The experiment will assist you to first identify those tasks that do not
participate in Gradle’s incremental build functionality, to then make an
informed decision which of those tasks are worth improving to make your build
faster, to then investigate why they do not participate in incremental building,
and to finally fix them once you understand the root cause.

The experiment can be run on any developer’s machine. It logically consists of
the following steps:

  1. Disable build caching
  2. Run the build with a typical task invocation including the 'clean' task
  3. Run the build with the same task invocation but without the 'clean' task
  4. Determine which tasks are still executed in the second run and why
  5. Assess which of the executed tasks are worth improving
  6. Fix identified tasks

The script you have invoked automates the execution of step 1, step 2, and step 3
without modifying the project. Build scans support your investigation in step 4
and step 5.

After improving the build to make it more incremental, you can push your changes
and run the experiment again. This creates a cycle of run → measure → improve →
run.

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
given Gradle tasks. The build will be invoked with the 'clean' task included
and build caching disabled.

${USER_ACTION_COLOR}Press <Enter> to run the first build of the experiment.${RESTORE}
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
with the same Gradle tasks. This time, the build will be invoked without the
'clean' task included and build caching still disabled.

${USER_ACTION_COLOR}Press <Enter> to run the second build of the experiment.${RESTORE}
EOF
  print_wizard_text "$text"
  wait_for_enter
}

explain_measure_build_results() {
  local text
  IFS='' read -r -d '' text <<EOF
$(print_separator)
${HEADER_COLOR}Measure build results${RESTORE}

Now that the second build has finished successfully, you are ready to measure in
Gradle Enterprise how well your build leverages Gradle’s local build cache for
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
two build scans that were published as part of running the experiment. The build
scan of the second build is particularly interesting since this is where you can
inspect what tasks were not leveraging Gradle’s incremental build functionality.

The 'Investigation Quick Links' section below allows quick navigation to the
most relevant views in build scans to investigate what tasks were uptodate and
what tasks executed in the second build, which of those tasks had the biggest
impact on build performance, and what caused those tasks to not be uptodate.

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
