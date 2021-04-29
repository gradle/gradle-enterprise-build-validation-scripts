#!/usr/bin/env bash
#
# Runs Experiment 01 - Validate Incremental Build
#
# Invoke this script with --help to get a description of the command line arguments
readonly SCRIPT_NAME=$(basename "$0")
readonly SCRIPT_DIR="$(cd "$(dirname "$(readlink -e "${BASH_SOURCE[0]}")")" && pwd)"
readonly LIB_DIR="${SCRIPT_DIR}/../lib"

# Experiment-specific constants
readonly EXP_NAME="Validating that a Gradle build is optimized for incremental building"
readonly EXP_NO="01"
readonly EXP_SCAN_TAG=exp1-gradle
readonly EXP_DIR="${SCRIPT_DIR}/data/${SCRIPT_NAME%.*}"
readonly SCAN_FILE="${EXP_DIR}/scans.csv"
readonly BUILD_TOOL="Gradle"

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

# Include and parse the command line arguments
# shellcheck source=build-validation/scripts/lib/gradle/01-cli-parser.sh
source "${LIB_DIR}/gradle/${EXP_NO}-cli-parser.sh" || { echo "Couldn't find '${LIB_DIR}/gradle/${EXP_NO}-cli-parser.sh' library."; exit 1; }
# shellcheck source=build-validation/scripts/lib/libs.sh
source "${LIB_DIR}/libs.sh" || { echo "Couldn't find '${LIB_DIR}/libs.sh'"; exit 1; }

readonly RUN_ID=$(generate_run_id)

main() {
  if [ "${interactive_mode}" == "on" ]; then
    wizard_execute
  else
    execute
  fi
}

execute() {
  validate_required_config

  make_experiment_dir
  git_clone_project ""

  execute_first_build
  execute_second_build

  print_warnings
  print_summary
}

wizard_execute() {
  print_introduction

  make_experiment_dir

  explain_collect_git_details
  collect_git_details

  explain_collect_gradle_details
  collect_gradle_details

  explain_clone_project
  git_clone_project ""

  explain_first_build
  execute_first_build

  explain_second_build
  execute_second_build

  print_warnings
  explain_warnings

  explain_summary
  explain_how_to_repeat_the_experiment
}

execute_first_build() {
  info "Running first build:"
  info "./gradlew --no-build-cache -Dscan.tag.${EXP_SCAN_TAG} -Dscan.tag.${RUN_ID} clean ${tasks}$(print_extra_args)"

  invoke_gradle --no-build-cache clean "${tasks}"
}

execute_second_build() {
  info "Running second build:"
  info "./gradlew --no-build-cache -Dscan.tag.${EXP_SCAN_TAG} -Dscan.tag.${RUN_ID} ${tasks}$(print_extra_args)"

  invoke_gradle --no-build-cache "${tasks}"
}

print_summary() {
 read_scan_info
 echo
 print_experiment_info
 print_build_scans
 echo
 print_quick_links
 echo
}

print_build_scans() {
 local fmt="%-26s%s"
 infof "$fmt" "Build scan first build:" "${scan_url[0]}"
 infof "$fmt" "Build scan second build:" "${scan_url[1]}"
}

print_quick_links() {
 local fmt="%-26s%s"
 info "Investigation Quick Links"
 info "-------------------------"
 infof "$fmt" "Build scan comparison:" "${base_url[0]}/c/${scan_id[0]}/${scan_id[1]}/task-inputs"
 infof "$fmt" "Task execution summary:" "${base_url[0]}/s/${scan_id[1]}/performance/execution"
 infof "$fmt" "Executed tasks:" "${base_url[0]}/s/${scan_id[1]}/timeline?outcome=SUCCESS,FAILED&sort=longest"
}

print_introduction() {
  local text
  IFS='' read -r -d '' text <<EOF
$(print_introduction_title)

In this experiment, you will validate how well a given project leverages
Gradle’s incremental build functionality. A build is considered fully
incremental if all tasks avoid performing any work because:

  * The tasks' inputs have not changed since their last invocation
  * The tasks' outputs are still present

The goal of this experiment is to first identify those tasks that do not
participate in Gradle’s incremental build functionality, to then investigate
why they do not participate, and to finally make an informed decision of
which tasks are worth improving to make your build faster.

This experiment can be run on any developer’s machine. It logically consists
of the following steps:

  1. Run the Gradle build with a typical task invocation including the 'clean' task
  2. Run the Gradle build with the same task invocation but without the 'clean' task
  3. Determine which tasks are still executed in the second run and why
  4. Assess which of the executed tasks are worth improving

The script you have invoked automates the execution of step 1 and step 2,
without modifying the project. Build scans support your investigation in
step 3 and step 4.

After improving the build to make it more incremental, you can push your
changes and run the experiment again. This creates a cycle of run → measure
→ improve → run → …

${USER_ACTION_COLOR}Press <Enter> to get started.${RESTORE}
EOF
  print_wizard_text "${text}"
  wait_for_enter
}

explain_first_build() {
  local text
  IFS='' read -r -d '' text <<EOF
Now that the project has been checked out, we can run the first build with
the given configuration. The build will be run with the 'clean' task
included and build caching disabled.

${USER_ACTION_COLOR}Press <Enter> to run the first build of the experiment.${RESTORE}
EOF
  print_wizard_text "${text}"
  wait_for_enter
}

explain_second_build() {
  local text
  IFS='' read -r -d '' text <<EOF
Now we are going to run the build again, but this time we will invoke it
without 'clean'. This will let us see how well the build takes advantage of
Gradle's incremental build.

In a fully optimized build, no tasks should run on this second build because
we already built everything in the first build. If some tasks do run, they
will show up in the build scan for this second build.

${USER_ACTION_COLOR}Press <Enter> to run the second build.${RESTORE}
EOF
  print_wizard_text "$text"
  wait_for_enter
}

explain_summary() {
  read_scan_info
  local text
  IFS='' read -r -d '' text <<EOF
Builds complete!

Now that both builds have completed, there is a lot of valuable data in
Gradle Enterprise to look at. The data can help you find inefficiencies in
your build.

After running the experiment, this script will generate a summary table of
useful data and links to help you analyze the experiment results:

$(print_experiment_info)

"Experiment id" and "Experiment run id" are added as tags on the build
scans.

You can use the "Experiment id" to find all of the build scans for all runs
of this experiment.

Every time you run this script, we'll generate a unique "Experiment run id".
You can use the run id to search for the build scans from a specific run of the
experiment.

$(print_build_scans)

Above are links to the build scans from this experiment. A build scan provides
a wealth of information and statistics about the build execution.

$(print_quick_links)

Use the above links help you get started in your analysis.

The first link is to a comparison of the two build scans. Comparisons show you
what was different between two different build executions.

The "Task execution summary" shows overall statistics for the execution of
the second build. You can use this link to get a quick overview of where
there may be overall opportunities to optimize.

The "Executed tasks" link takes you to the timeline view of the second build
scan and automatically shows only the tasks that were executed, sorted by
execution time (with the longest-running tasks listed first). You can use
this to quickly identify tasks that were executed again unnecessarily. You
will want to optimize any such tasks that take a significant amount of time
to complete.

Take some time to explore all of the links. You might be surprised by what
you find!
EOF
  print_wizard_text "${text}"
}

process_arguments "$@"
main

