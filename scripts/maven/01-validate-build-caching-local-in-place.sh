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
readonly EXP_NAME="Validate Build Caching - Local - In Place"
readonly EXP_DESCRIPTION="Validating that a Maven build is optimized for local in-place build caching"
readonly EXP_NO="01"
readonly EXP_SCAN_TAG=exp1-maven
readonly EXP_DIR="${SCRIPT_DIR}/data/${SCRIPT_NAME%.*}"
readonly SCAN_FILE="${EXP_DIR}/scans.csv"
readonly BUILD_TOOL="Maven"

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
# shellcheck source=build-validation/scripts/lib/maven/01-cli-parser.sh
source "${LIB_DIR}/maven/${EXP_NO}-cli-parser.sh" || { echo "Couldn't find '${LIB_DIR}/maven/${EXP_NO}-cli-parser.sh' parsing library."; exit 1; }
# shellcheck source=build-validation/scripts/lib/libs.sh
source "${LIB_DIR}/libs.sh" || { echo "Couldn't find '${LIB_DIR}/libs.sh'"; exit 1; }

RUN_ID=$(generate_run_id)

main() {
  if [ "${interactive_mode}" == "on" ]; then
    wizard_execute
  else
    execute
  fi
}

execute() {
  print_bl
  validate_required_config

  make_experiment_dir
  make_local_cache_dir "${build_cache_dir}"
  git_clone_project ""

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
  explain_collect_maven_details
  print_bl
  collect_maven_details

  print_bl
  explain_clone_project
  print_bl
  make_experiment_dir
  git_clone_project ""

  print_bl
  explain_local_cache_dir
  make_local_cache_dir

  print_bl
  explain_first_build
  print_bl
  execute_first_build

  print_bl
  explain_second_build
  print_bl
  execute_second_build

  print_bl
  explain_summary
  explain_how_to_repeat_the_experiment
  print_bl
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
  info "./mvnw -Dscan.tag.${EXP_SCAN_TAG} clean ${tasks}$(print_extra_args)"

  #shellcheck disable=SC2086  # we actually want ${tasks} to expand because it may have more than one maven goal
  invoke_maven \
     -Dgradle.cache.local.enabled=true \
     -Dgradle.cache.remote.enabled=false \
     -Dgradle.cache.local.directory="${build_cache_dir}" \
     clean ${tasks}
}

print_summary() {
 read_scan_info
 print_experiment_info
 print_build_scans
 print_bl
 print_quick_links
 print_bl
}

print_build_scans() {
 local fmt="%-25s%-10s"
 infof "$fmt" "Build scan first build:" "${scan_url[0]}"
 infof "$fmt" "Build scan second build:" "${scan_url[1]}"
}

print_quick_links() {
 local fmt="%-25s%-10s"
 info "Investigation Quick Links"
 info "-------------------------"
 infof "$fmt" "Task execution overview:" "${base_url[0]}/s/${scan_id[1]}/performance/execution"
 infof "$fmt" "Cache performance:" "${base_url[0]}/s/${scan_id[1]}/performance/build-cache"
 infof "$fmt" "Executed goals timeline:" "${base_url[0]}/s/${scan_id[1]}/timeline?outcome=successful&sort=longest"
 infof "$fmt" "Goal inputs comparison:" "${base_url[0]}/c/${scan_id[0]}/${scan_id[1]}/goal-inputs?cacheability=cacheable"
 infof "$fmt" "Executed cacheable goals:" "${base_url[0]}/s/${scan_id[1]}/timeline?cacheableFilter=cacheable&outcomeFilter=successful&sorted=longest"
 infof "$fmt" "Non-cacheable goals:" "${base_url[0]}/s/${scan_id[1]}/timeline?cacheableFilter=any_non-cacheable&outcomeFilter=successful&sorted=longest"
}

print_introduction() {
  local text
  IFS='' read -r -d '' text <<EOF
$(print_introduction_title)

This is the first of several experiments designed to help you
optimize your team's builds. If you are running this experiment as part of a
Gradle Enterprise Trial, then the experiments will also help you to build
the data necessary to determine if Gradle Enerprise is useful to your
organization.

This script (and the other experiment scripts) will run some of the
experiment steps for you, but we'll walk you through each step so that you
know exactly what we are doing, and why.

In this experiment, we will be checking your build to see how well it takes
advantage of the local build cache. When the build cache is enabled, the
Gradle Enterprise Maven extension saves the output from goals so that the
same output can be reused if the goal is executed again with the same
inputs.

To test out the build cache, we'll run two builds (with build caching
enabled). Both builds will invoke clean and run the same goals. We will not
make any changes between each build run.

If the build is taking advantage of the local build cache, then very few (if
any) goals should actually execute on the seond build (all of the goal
output should be used from the local cache).

The Gradle Solutions engineer will then work with you to figure out why some
(if any) goals ran on the second build, and how to optimize them to take
advantage of the build cache.

${USER_ACTION_COLOR}Press <Enter> to get started.${RESTORE}
EOF

  print_wizard_text "${text}"
  wait_for_enter
}

explain_local_cache_dir() {
  local text
  IFS='' read -r -d '' text <<EOF
$(print_separator)
${HEADER_COLOR}Configure local build cache${RESTORE}

We are going to create a new empty local build cache dir (and configure
Gradle to use it instead of the default local cache dir). This way, the
first build won't find anything in the cache and all goals will run.

This is important because we want to make sure goals that are cachable do in
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

explain_first_build() {
  local text
  IFS='' read -r -d '' text <<EOF
$(print_separator)
${HEADER_COLOR}Run first build${RESTORE}

OK! We are ready to run our first build!

For this run, we'll execute 'clean ${tasks}'.

We will also add a few the build scan tags.

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

Now we are going to run the build again without changing anything.

In a fully optimized build, no goals would run on this second build because
we already built everything in the first build, and the goal outputs should
be in the local build cache. If some goals do run, they will show up in the
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
$(print_separator)
${HEADER_COLOR}Measure build results${RESTORE}

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

The "Goal execution summary" shows overall statistics for the execution of
the second build. You can use this link to get a quick overview of where
there may be overall opportunities to optimize.

The "Cache performance" link takes you to the build cache performance page
of the 2nd build scan. This page contains various metrics related to the
build cache (such as cache hits and misses).

The "Executed goals" link takes you to the timeline view of the second build
scan and automatically shows only the goals that were executed, sorted by
execution time (with the longest-running goal listed first). You can use
this to quickly identify goals that were executed again unnecessarily. You
will want to optimize any such goals that take a significant amount of time
to complete.

The "Executed cacheable goals" link shows you which tasks ran again on the
second build, but shouldn't have because they are actually cacheable. If any
cacheable goals ran, then one of their inputs changed (even though we didn't
make any changes), or they may not be declaring their inputs correctly.

The last link, "Non-cacheable goals", shows you which goals ran that are not
cacheable. It is not always possible (or doesn't make sense) to cache the
output from every goal. For example, there is no way to cache the "output"
of the clean goal because the clean goal deletes output rather than creating
it.
EOF
  print_wizard_text "${text}"
}

process_arguments "$@"
main

