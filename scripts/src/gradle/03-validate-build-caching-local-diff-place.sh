#!/usr/bin/env bash
#
# Runs Experiment 02 - Validate Build Caching - Local - In Place
#
# Invoke this script with --help to get a description of the command line arguments
#
readonly SCRIPT_NAME=$(basename "$0")
readonly SCRIPT_DIR="$(cd "$(dirname "$(readlink -e "${BASH_SOURCE[0]}")")" && pwd)"
readonly LIB_DIR="${SCRIPT_DIR}/../lib"

# Experiment-speicifc constants
readonly EXP_NAME="Validate Build Caching - Local - Different Places"
readonly EXP_NO="03"
readonly EXP_SCAN_TAG=exp3-gradle
readonly EXP_DIR="${SCRIPT_DIR}/data/${SCRIPT_NAME%.*}"
readonly SCAN_FILE="${EXP_DIR}/scans.csv"
readonly BUILD_TOOL="Gradle"

build_cache_dir="${EXP_DIR}/build-cache"

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
# shellcheck source=build-validation-automation/scripts/src/lib/gradle/03-cli-parser.sh
source "${LIB_DIR}/gradle/${EXP_NO}-cli-parser.sh" || { echo "Couldn't find '${LIB_DIR}/gradle/${EXP_NO}-cli-parser.sh' parsing library."; exit 1; }
# shellcheck source=build-validation-automation/scripts/src/lib/libs.sh
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
  make_local_cache_dir "${build_cache_dir}"

  git_clone_project "_1"
  execute_first_build

  git_clone_project "_2"
  execute_second_build

  print_warnings
  print_summary
}

wizard_execute() {
  print_introduction

  make_experiment_dir

  collect_git_details

  explain_collect_gradle_details
  collect_gradle_details

  explain_local_cache_dir
  make_local_cache_dir

  explain_first_clone_project
  git_clone_project "_1"

  explain_first_build
  execute_first_build

  explain_second_clone_project
  git_clone_project "_2"

  explain_second_build
  execute_second_build

  print_warnings
  explain_warnings

  explain_summary
  explain_how_to_repeat_the_experiment
}

execute_first_build() {
  info "Running first build:"
  execute_build
}

execute_second_build() {
  info "Running second build:"
  execute_build
}

execute_build() {
  # The gradle --init-script flag only accepts a relative directory path. ¯\_(ツ)_/¯
  #shellcheck disable=SC2164  # We will handle the error when we try to invoke the build, which calls this same function
  pushd "${project_dir}" > /dev/null 2>&1
  local lib_dir_rel
  lib_dir_rel=$(relpath "$( pwd )" "${LIB_DIR}")
  #shellcheck disable=SC2164  #This is extremely unlikely to fail
  popd > /dev/null 2>&1

  info "./gradlew -Dscan.tag.${EXP_SCAN_TAG} -Dscan.tag.${RUN_ID} clean ${tasks}$(print_extra_args)"

  invoke_gradle \
     --init-script "${lib_dir_rel}/gradle/verify-and-configure-local-build-cache-only.gradle" \
     clean "${tasks}"
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
 local fmt="%-25s%-10s"
 infof "$fmt" "Build scan first build:" "${scan_url[0]}"
 infof "$fmt" "Build scan second build:" "${scan_url[1]}"
}

print_quick_links() {
 local fmt="%-25s%-10s"
 info "Investigation quick links"
 info "-------------------------"
 infof "$fmt" "Build scan comparison:" "${base_url[0]}/c/${scan_id[0]}/${scan_id[1]}/task-inputs?cacheability=cacheable"
 infof "$fmt" "Task execution summary:" "${base_url[0]}/s/${scan_id[1]}/performance/execution"
 infof "$fmt" "Cache performance:" "${base_url[0]}/s/${scan_id[1]}/performance/build-cache"
 infof "$fmt" "Executed tasks:" "${base_url[0]}/s/${scan_id[1]}/timeline?outcome=SUCCESS,FAILED&sort=longest"
 infof "$fmt" "Executed cacheable tasks:" "${base_url[0]}/s/${scan_id[1]}/timeline?cacheableFilter=cacheable&outcomeFilter=SUCCESS,FAILED&sorted=longest"
 infof "$fmt" "Non-cacheable tasks:" "${base_url[0]}/s/${scan_id[1]}/timeline?cacheableFilter=any_non-cacheable&outcomeFilter=SUCCESS,FAILED&sorted=longest"
}

print_introduction() {
  local text
  IFS='' read -r -d '' text <<EOF
$(print_introduction_title)

This is the third of several experiments designed to help you
optimize your team's builds. If you are running this experiment as part of a
Gradle Enterprise Trial, then the experiments will also help you to build
the data necessary to determine if Gradle Enerprise is useful to your
organization.

This script (and the other experiment scripts) will run some of the
experiment steps for you, but we'll walk you through each step so that you
know exactly what we are doing, and why.

In this experiment, we will be checking your build to see how well it takes
advantage of the local build cache when the build is run from different
locations.

When the build cache is enabled, Gradle saves the output from tasks so that
the same output can be reused if the task is executed again with the same
inputs.  This is similar to incremental build, except that the cache is used
across build runs. So even if you perform a clean, cached output will be
used if the inputs to a task have not changed.

To test out the build cache, we will run two builds (with build caching
enabled) against the same project, but in different locations. Both builds
will invoke clean and run the same tasks. We will not make any changes
between each build run (other than the location).

If the build is taking advantage of the local build cache, then very few (if
any) tasks should actually execute on the second build (all of the task
output should be used from the local cache).

The Gradle Solutions engineer will then work with you to figure out why some
(if any) tasks ran on the second build, and how to optimize them to take
advantage of the build cache.

${USER_ACTION_COLOR}Press <Enter> to get started.${RESTORE}
EOF

  print_wizard_text "${text}"
  wait_for_enter
}

explain_local_cache_dir() {
  local text
  IFS='' read -r -d '' text <<EOF
We are going to create a new empty local build cache dir (and configure
Gradle to use it instead of the default local cache dir). This way, the
first build won't find anything in the cache and all tasks will run.

This is important because we want to make sure tasks that are cachable do in
fact produce output that is stored in the cache.

Specifically, we are going to create and use this directory for the local
build cache (we'll delete it if it already exists from a previous run of the
experiment):

$(info "${build_cache_dir}")

${USER_ACTION_COLOR}Press <Enter> to continue.${RESTORE}
EOF
  print_wizard_text "${text}"
  wait_for_enter
}

explain_first_clone_project(){
  local text
  IFS='' read -r -d '' text <<EOF
For the first build, we are going create a fresh clone of the project.  That
way, the experiment will be infleunced by as few outside factors as
possible.

We'll use a different clone of the project for the second build.

${USER_ACTION_COLOR}Press <Enter> to continue.${RESTORE}
EOF
  print_wizard_text "${text}"
  wait_for_enter
}

explain_first_build() {
  local text
  IFS='' read -r -d '' text <<EOF
We are now ready to run the first build.

We will execute 'clean ${tasks}'.

We are invoking clean even though we just created a fresh clone because
sometimes the clean task changes the order other tasks run in, which can
impact how the build cache is utilized.

We will also add a few build scan tags.

${USER_ACTION_COLOR}Press <Enter> to run the first build.${RESTORE}
EOF
  print_wizard_text "${text}"
  wait_for_enter
}

explain_second_clone_project(){
  local text
  IFS='' read -r -d '' text <<EOF
Before running the second build, we are going to clone the project into a
different directory. If all goes well, the second build will use the build
cache in exactly the same way as it does when we run multiple builds from
the same location.

${USER_ACTION_COLOR}Press <Enter> to continue.${RESTORE}
EOF
  print_wizard_text "${text}"
  wait_for_enter
}


explain_second_build() {
  local text
  IFS='' read -r -d '' text <<EOF
Now we are going to run the build again without changing anything, other
than the location (we're running this against the second clone of the
project).

In a fully optimized build, no tasks would run on this second build because
we already built everything in the first build, and the task outputs should
be in the local build cache. If some tasks do run, they will show up in the
build scan for this second build.

${USER_ACTION_COLOR}Press <Enter> to run the second build.${RESTORE}
EOF
  print_wizard_text "$text"
  wait_for_enter
}

explain_summary() {
  read_scan_info
  local text
  IFS='' read -r -d '' text <<EOF
Now that both builds have completed, there is a lot of valuable data in
Gradle Enterprise to look at. The data can help you find ineffiencies in
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

The "Cache performance" link takes you to the build cache performance page
of the 2nd build scan. This page contains various metrics related to the
build cache (such as cache hits and misses).

The "Executed tasks" link takes you to the timeline view of the second build
scan and automatically shows only the tasks that were executed, sorted by
execution time (with the longest-running tasks listed first). You can use
this to quickly identify tasks that were executed again unnecessarily. You
will want to optimize any such tasks that take a significant amount of time
to complete.

The "Executed cacheable tasks" link shows you which tasks ran again on the
second build, but shouldn't have because they are actually cacheable. If any
cacheable tasks ran, then one of their inputs changed (even though we didn't
make any changes), or they may not be declaring their inputs correctly.

The last link, "Non-cacheable tasks", shows you which tasks ran that are not
cacheable. It is not always possible (or doesn't make sense) to cache the
output from every task. For example, there is no way to cache the "output"
of the clean task because the clean task deletes output rather than creating
it.
EOF
  print_wizard_text "${text}"
}

process_arguments "$@"
main

