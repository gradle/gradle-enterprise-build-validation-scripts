#!/usr/bin/env bash
#
# Runs Experiment 01 - Validate Incremental Build 
#
# Invoke this script with --help to get a description of the command line arguments
SCRIPT_NAME=$(basename "$0")
SCRIPT_DIR="$(cd "$(dirname "$(readlink -e "${BASH_SOURCE[0]}")")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/../lib"

# Experiment-speicifc constants
EXP_NAME="Validate Incremental Build"
EXP_NO="01"
EXP_SCAN_TAG=exp1-gradle
EXPERIMENT_DIR="${SCRIPT_DIR}/data/${SCRIPT_NAME%.*}"
SCAN_FILE="${EXPERIMENT_DIR}/scans.csv"

# These will be set by the config functions (see lib/config.sh)
git_repo=''
project_name=''
git_branch=''
tasks=''
extra_args=''
enable_ge=''
ge_server=''
interactive_mode=''

# Include and parse the command line arguments
# shellcheck source=experiments/lib/gradle/01/parsing.sh
source "${LIB_DIR}/gradle/01/parsing.sh" || { echo "Couldn't find '${LIB_DIR}/gradle/01/parsing.sh' parsing library."; exit 1; }
# shellcheck source=experiments/lib/libs.sh
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
  validate_required_config

  make_experiment_dir
  clone_project ""

  execute_first_build
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

  explain_clone_project
  clone_project ""

  explain_scan_tags
  explain_first_build
  execute_first_build

  explain_second_build
  execute_second_build

  save_config

  print_warnings
  explain_warnings

  print_summary
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

 local branch
 branch=$(git symbolic-ref --short HEAD)

 local fmt="%-26s%s"
 info
 info "Summary"
 info "-------"
 infof "$fmt" "Project:" "${project_name}"
 infof "$fmt" "Git repo:" "${git_repo}"
 infof "$fmt" "Git branch:" "${branch}"
 infof "$fmt" "Gradle tasks:" "${tasks}"
 infof "$fmt" "Gradle arguments:" "${extra_args}"
 infof "$fmt" "Experiment:" "${EXP_NO}-${EXP_NAME}"
 infof "$fmt" "Experiment id:" "${EXP_SCAN_TAG}"
 infof "$fmt" "Experiment run id:" "${RUN_ID}"
 infof "$fmt" "Experiment artifact dir:" "${EXPERIMENT_DIR}"
 print_build_scans
 print_quick_links
}

print_build_scans() {
 local fmt="%-26s%s"
 infof "$fmt" "Build scan first build:" "${scan_url[0]}"
 infof "$fmt" "Build scan second build:" "${scan_url[1]}"
}

print_quick_links() {
 local fmt="%-26s%s"
 info 
 info "Investigation quick links"
 info "-------------------------"
 infof "$fmt" "Build scan comparison:" "${base_url[0]}/c/${scan_id[0]}/${scan_id[1]}/task-inputs"
 infof "$fmt" "Task execution summary:" "${base_url[0]}/s/${scan_id[1]}/performance/execution"
 infof "$fmt" "Executed tasks:" "${base_url[0]}/s/${scan_id[1]}/timeline?outcome=SUCCESS,FAILED&sort=longest"
 info
}

print_introduction() {
  local text
  IFS='' read -r -d '' text <<EOF
$(print_introduction_title)

Welcome! This is the first of several experiments designed to help you
optimize your team's builds. If you are running this experiment as part of a
Gradle Enterprise Trial, then the experiments will also help you to build
the data necessary to determine if Gradle Enerprise is useful to your
organization.

A software development team can gain a lot of efficiency and productivity by
optimizing their build to avoid performing unnecessary work, or work that
has been performed already. Shorter builds allow software developers to get
feedback quicker about their changes (does the code compile, do the tests
pass?) and helps to reduce context switching (a known productivity killer).

We can optimize the build to avoid uncessary work by running controlled,
reproducable experiments and then using Gradle Enterprise to understand what
ran unnecessarily and why it ran.

This script (and the other experiment scripts) will run some of the
experiment steps for you. When run with -i/--interactive, this script will
explain each step so that you know exactly what the experiment is doing, and
why.

It is a good idea to use interactive mode for the first one or two times you
run an experiment, but afterwards, you can run the script normally to save
time (all of the steps will execuite automatically without pause). 

You may want to repeat the experiment on a regular basis to validate any
optimizations you have made or to look for any regressions that may sneak
into your build over time.

In this first experiment, we will be optimizing your existing build so that
all tasks participate in Gradle's incremental build feature. Within a single
project, Gradle will only execute tasks if their inputs have changed since
the last time you ran them.

For this experiment, we will run a clean build, and then we will run the
same build again without making any changes (but without invoking clean).
Afterwards, we'll look at the build scans to find tasks that were executed
the second time. In a fully optimized build, no tasks should run when no
changes have been made.

After the experiment has completed, you can look at the generated build
scans in Gradle Enterprise to figure out why some (if any) tasks ran on the
second build, and how to optimize them so that all tasks participate in
Gradle's incremental building feature.

${USER_ACTION_COLOR}Press enter when you're ready to get started.
EOF
  print_wizard_text "${text}"
  wait_for_enter
}

explain_first_build() {
 local build_command
  build_command="${YELLOW}./gradlew --no-build-cache \\
  ${YELLOW}-Dscan.tag.${EXP_SCAN_TAG} \\
  ${YELLOW}-Dscan.tag.${RUN_ID} \\
  ${YELLOW} clean ${tasks}"

  local text
  IFS='' read -r -d '' text <<EOF
OK! We are ready to run our first build!

For this run, we'll execute 'clean ${tasks}'. 

We are invoking clean even though we just created a fresh clone because
sometimes the clean task changes the order other tasks run in, which can
impact how incremental building works.

We will also add a flag to make sure build caching is disabled (since we are
just focused on incremental building for now), and we will add the build
scan tags we talked about before.

Effectively, this is what we are going to run:

${build_command}

${USER_ACTION_COLOR}Press enter to run the first build.
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

${USER_ACTION_COLOR}Press enter to run the second build.
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
Gradle Enterprise to look at. The data can help you find ineffiencies in
your build.

After running the experiment, this script will generate a summary table of
useful data and links to help you analyze the experiment results. Most of
the data in the summmary is self-explanatory, but a few are worth reviewing:

$(print_build_scans)

^^ These are links to the build scans for the builds. A build scan provides
a wealth of information and statistics about the build execution.

$(print_quick_links)

^^ These are links to help you get started in your analysis. 

The first link is to a comparison of the two build scans. Comparisons show you
what was different between two different build executions.

The "Task execution summary" shows overall statistics for the execution of
the second build. You can use this link to get a quick overview of where
there may be overall opportunities to optimize.

The "Executed tasks" link takes you to the timeline view of the second build
scan and automatically shows only the tasks that were executed, sorted by
execution time (with the longest-running tasks listed first). You can use
this to quickly identify tasks that were executed again unecessarily. You
will want to optimize any such tasks that take a significant amount of time
to complete.

Take some time to explore all of the links. You might be surprised by what
you find!
EOF
  print_wizard_text "${text}"
}

process_arguments "$@"
main

