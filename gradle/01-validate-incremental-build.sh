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
RUN_ID=$(uuidgen)
EXPERIMENT_DIR="${SCRIPT_DIR}/data/${SCRIPT_NAME%.*}"
SCAN_FILE="${EXPERIMENT_DIR}/scans.csv"

# These will be set by the collect functions (see lib/input.sh)
project_url=""
project_name=""
project_branch=""
tasks=""

# Include and parse the command line arguments
# shellcheck source=experiments/lib/gradle/01/parsing.sh
source "${LIB_DIR}/gradle/01/parsing.sh" || { echo "Couldn't find '${LIB_DIR}/gradle/01/parsing.sh' parsing library."; exit 1; }

# shellcheck source=experiments/lib/libs.sh
source "${LIB_DIR}/libs.sh" || { echo "Couldn't find '${LIB_DIR}/libs.sh'"; exit 1; }

main() {
  if [ "$_arg_interactive" == "on" ]; then
    wizard_execute
  else
    execute
  fi
}

execute() {
  load_settings
  validate_required_config

  print_experiment_info

  make_experiment_dir
  clone_project ""

  execute_first_build
  execute_second_build

  save_settings
  print_warnings
  print_summary
}

wizard_execute() {
  print_introduction

  explain_experiment_info

  explain_experiment_dir
  make_experiment_dir

  load_settings

  collect_project_details

  explain_collect_gradle_task
  collect_gradle_task

  explain_clone_project
  clone_project ""

  explain_first_build
  execute_first_build

  explain_second_build
  execute_second_build

  save_settings

  print_warnings
  explain_warnings

  print_summary
  explain_summary
}

execute_first_build() {
  info "Running first build (invoking clean)."
  info 
  info "./gradlew --no-build-cache -Dscan.tag.${EXP_SCAN_TAG} -Dscan.tag.${RUN_ID} clean ${tasks}"

  invoke_gradle --no-build-cache clean "${tasks}"
}

execute_second_build() {
  info "Running second build (without invoking clean)."
  info 
  info "./gradlew --no-build-cache -Dscan.tag.${EXP_SCAN_TAG} -Dscan.tag.${RUN_ID} ${tasks}"

  invoke_gradle --no-build-cache "${tasks}"
}

print_summary() {
 read_scan_info

 local branch
 branch=$(git branch)
 if [ -n "$_arg_branch" ]; then
   branch=${_arg_branch}
 fi

 local fmt="%-25s%-10s"
 info
 info "SUMMARY"
 info "----------------------------"
 infof "$fmt" "Project:" "${project_name}"
 infof "$fmt" "Branch:" "${branch}"
 infof "$fmt" "Gradle task(s):" "${tasks}"
 infof "$fmt" "Experiment dir:" "${EXPERIMENT_DIR}"
 infof "$fmt" "Experiment tag:" "${EXP_SCAN_TAG}"
 infof "$fmt" "Experiment run ID:" "${RUN_ID}"
 print_build_scans
 print_starting_points
}

print_build_scans() {
 local fmt="%-25s%-10s"
 infof "$fmt" "First build scan:" "${scan_url[0]}"
 infof "$fmt" "Second build scan:" "${scan_url[1]}"
}

print_starting_points() {
 local fmt="%-25s%-10s"
 info 
 info "SUGGESTED STARTING POINTS"
 info "----------------------------"
 infof "$fmt" "Scan comparision:" "${base_url[0]}/c/${scan_id[0]}/${scan_id[1]}/task-inputs?cacheability=cacheable"
 infof "$fmt" "Longest-running tasks:" "${base_url[0]}/s/${scan_id[1]}/timeline?outcome=SUCCESS&sort=longest"
 info
}

print_introduction() {
  local text
  IFS='' read -r -d '' text <<EOF
${CYAN}                              ;x0K0d,
${CYAN}                            kXOxx0XXO,
${CYAN}              ....                '0XXc
${CYAN}       .;lx0XXXXXXXKOxl;.          oXXK
${CYAN}      xXXXXXXXXXXXXXXXXXX0d:.     ,KXX0
${CYAN}     .,KXXXXXXXXXXXXXXXXXO0XXKOxkKXXXX:
${CYAN}   lKX:'0XXXXXKo,dXXXXXXO,,XXXXXXXXXK;   Gradle Enterprise Trial
${CYAN} ,0XXXXo.oOkl;;oKXXXXXXXXXXXXXXXXXKo.
${CYAN}:XXXXXXXKdllxKXXXXXXXXXXXXXXXXXX0c.
${CYAN}'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXk'
${CYAN}xXXXXXXXXXXXXXXXXXXXXXXXXXXXXXc          Experiment ${EXP_NO}:
${CYAN}KXXXXXXXXXXXXXXXXXXXXXXXXXXXXl           ${EXP_NAME}
${CYAN}XXXXXXklclkXXXXXXXklclxKXXXXK
${CYAN}OXXXk.     .OXXX0'     .xXXXx
${CYAN}oKKK'       ,KKK:       .KKKo

Welcome! This is the first of several experiments that are part of your
Gradle Enterprise Trial. Each experiment will help you to make concrete
improvements to your existing build. The experiments will also help you to
build the data necessary to recommend Gradle Enerprise to your organization.

This script (and the other experiment scripts) will run some of the
experiment steps for you, but we'll walk you through each step so that you
know exactly what we are doing, and why.

In this first experiment, we will be optimizing your existing build so that
all tasks participate in Gradle's incremental build feature. Gradle will
only execute tasks if their inputs have changed since the last time you ran
them.  This let's Gradle avoid running tasks unecessarily (after all, why
run a task again if it's already completed it's work?).

For this experiment, we will run a clean build, and then we will run the
same build again without making any changes (but without invoking clean).
Afterwards, we'll look at the build scans to find tasks that were executed
the second time. In a fully optimized build, no tasks should run when no
changes have been made.

The Gradle Solutions engineer will then work with you to figure out why some
(if any) tasks ran on the second build, and how to optimize them so that all
tasks participate in Gradle's incremental building feature.

${USER_ACTION_COLOR}Press enter when you're ready to get started.
EOF
  print_in_box "${text}"
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
  print_in_box "${text}"
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
  print_in_box "$text"
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

After running the experiment, I will generate a summary table of useful data
and links to help you analyze the experiment results. Most of the data in
the summmary is self-explanatory, but there are a few things are worth
reviewing:

$(print_build_scans)

^^ These are links to the build scans for the builds. A build scan is a
report that provides information and statistics about the build execution.

$(print_starting_points)

^^ These are links to help you get started in your analysis. The first link
is to a comparison of the two build scans. Comparisions show you what was
different between two different builds.

The second link takes you to the timeline view of the second build scan and
automatically shows only the tasks that were executed, sorted by execution
time (with the longest-running tasks listed first). You can use this to
quickly identify tasks that were executed again unecessarily. You will want
to optimize any such tasks that also take a significant amount of time to
complete.

Take some time to look over the build scans and the build comparison. You
might be surprised by what you find!"

If you do find something to optimize, then you will want to run this expirment
again after you have implemented the optimizations (to validate the
optimizations were effective). You will not need to run this wizard again. All
of your settings have been saved, so all you need to do to run this experiment
again without the wizard is to invoke this script without any arguments:

$(info "./${SCRIPT_NAME}")

Congrats! You have completed this experiment.
EOF
  print_in_box "${text}"
}

main

