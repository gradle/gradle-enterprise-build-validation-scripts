#!/usr/bin/env bash
#
# Runs Experiment 01 -  Optimize for incremental building
#
set -e
script_name=$(basename "$0")
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" > /dev/null && pwd )"
project_dir="$( pwd )"
project_name=$( basename ${project_dir} )
experiment_dir="$project_dir/build/enterprise-trial-experiments/experiment-01"

run_id=$(uuidgen)

main() {
 print_introduction
 print_run_id
 collect_gradle_task
 make_experiment_dir
 clone_project
 execute_first_build
 execute_second_build
 open_build_scan_comparison
 print_done
 print_wrap_up
}

print_run_id() {
  wizard "Below is the ID for this particular run of this experiment. Every time you run this script, \
we'll generate a new unique ID. This ID is added as a tag on all of the build scans, which \
makes it easy to find the build scans for each run of the experiment. We will also add an \
'exp1' tag to every build scan so that you can easily find all of the build scans for all \
runs of this experiment."

  info
  info "Experiment tag: exp1"
  info "Experiment Run ID: ${run_id}"
}

collect_gradle_task() {
  wizard "Before we do anything else, we need to know what tasks to execute on each build."

  echo
  read -p "What Gradle task do you want to run? (build) " task
  if [[ "${task}" == "" ]]; then
    task=build
  fi
}

make_experiment_dir() {
  mkdir -p "${experiment_dir}"
  wizard "I just created ${experiment_dir} where we will do the work for this experiment."
}

clone_project() {
   wizard "Next, we're going to create a fresh clone of the project. This will ensure no \
local changes will interfere with the experiment."
   wizard_pause "Press enter to continue."

   info "Creating a clean clone of the project."

   local clone_dir="${experiment_dir}/${project_name}"

   rm -rf "${clone_dir}"
   git clone "${project_dir}" "${clone_dir}"
   cd "${clone_dir}"
}

execute_first_build() {
  wizard "OK! We are ready to run our first build!"
  wizard "For this run, we'll execute 'clean ${task}'. We will also add a few more flags to \
make sure build caching is disabled (since we are just focused on icremental building \
for now), and to add the build scan tags we talked about before. I will use a Gradle \
init script to capture the build scan information. That's for me though, you can totally \
ignore that part."
  wizard "Effectively, this is what we are going to run (the actual command is a bit more complex):"

  info 
  info "./gradlew --no-build-cache -Dscan.tag.exp1 -Dscan.tag.${run_id} clean ${task}"

  wizard_pause "Press enter to run the first build."

  info "Running first build (invoking clean)."
  invoke_gradle --no-build-cache clean ${task}
  echo
}

execute_second_build() {
  wizard "Now we are going to run the build again, but this time we will invoke it without \
'clean'. This will let us see how well the build takes advantage of Gradle's incremental build."

  info 
  info "./gradlew --no-build-cache -Dscan.tag.exp1 -Dscan.tag.${run_id} ${task}"

  wizard_pause "Press enter to run the second build."

  info "Running second build (without invoking clean)."
  invoke_gradle --no-build-cache ${task}
  echo
}

open_build_scan_comparison() {
  wizard "It is time to compare the build scans from both builds. \
If you are unfamiliar with build scan comparisions then you might want to look this over with \
a Gradle Solutions engineer (who can help you to interpret the data)."
  wizard "After you are done looking at the scan comparison, come back here and I will share with \
you some final thoughts."

  read -p "Press enter to to open the build scan comparision in your default browser."

  local base_url=()
  local scan_url=()
  local scan_id=()
  # This isn't the most robust way to read a CSV,
  # but we control the CSV so we don't have to worry about various CSV edge cases
  while IFS=, read -r field_1 field_2 field_3; do
     base_url+=("$field_1")
     scan_id+=("$field_2")
     scan_url+=("$field_3")
  done < scans.csv

  local OS=$(uname)
  case $OS in
    'Darwin') browse=open ;;
    'WindowsNT') browse=start ;;
    *) browse=xdg-open ;;
  esac
  $browse "${base_url[0]}/c/${scan_id[0]}/${scan_id[1]}/task-inputs"
}

print_done() {
 printf "\n\033[00;32mDONE\033[0m\n"
}

invoke_gradle() {
  # The gradle --init-script flag only accepts a relative directory path. ¯\_(ツ)_/¯
  local script_dir_rel=$(realpath --relative-to="$( pwd )" "${script_dir}")
  local cmd="./gradlew --init-script ${script_dir_rel}/capture-build-scan-info.gradle -Dscan.tag.exp1 -Dscan.tag.${run_id} $@"
  $cmd
}

info () {
  printf "$1\n"
}

wizard () {
  echo
  printf "\033[00;34m$1\033[0m\n" | fmt -w 80
}

wizard_pause() {
  echo
  read -p "$1"
  echo
}

print_introduction() {
  printf "\033[00;34m"
  cat <<EOF

                              ;x0K0d,
                             kXOxx0XXO,
               ....                '0XXc
        .;lx0XXXXXXXKOxl;.          oXXK
       xXXXXXXXXXXXXXXXXXX0d:.     ,KXX0
      .,KXXXXXXXXXXXXXXXXXO0XXKOxkKXXXX:
    lKX:'0XXXXXKo,dXXXXXXO,,XXXXXXXXXK;       Gradle Enterprise Trial
  ,0XXXXo.oOkl;;oKXXXXXXXXXXXXXXXXXKo.
 :XXXXXXXKdllxKXXXXXXXXXXXXXXXXXX0c.
'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXk'
xXXXXXXXXXXXXXXXXXXXXXXXXXXXXXc           Experiment 1:
KXXXXXXXXXXXXXXXXXXXXXXXXXXXXl            Optimize for Incremental Build
XXXXXXklclkXXXXXXXklclxKXXXXK
OXXXk.     .OXXX0'     .xXXXx
oKKK'       ,KKK:       .KKKo


Wecome! This is the first of several experiments that are part of your Gradle
Enterprise Trial. Each experiment will help you to make concrete improvements
to your existing build. The experiments will also help you to build the data
necessary to recommend Gradle Enerprise to your organization.

This script (and the other experiment scripts) will run some of the experiment
steps for you, but we'll walk you through each step so that you know exactly
what we are doing, and why.

In this first experiment, we will be optimizing your existing build so that all
tasks participate in Gradle's incremental build feature. Gradle will only
execute tasks if their inputs have changed since the last time you ran them.
This let's Gradle avoid running tasks unecessarily (after all, why run a task
again if it's already completed it's work?).

For this experiment, we will run a clean build, and then we will run the same
build again without making any changes (but without invoking clean).
Afterwards, we'll look at the build scans to find tasks that were executed the
second time. In a fully optimized build, no tasks should run when no changes
have been made.

The Gradle Solutions engineer will then work with you to figure out why some
(if any) tasks ran on the second build, and how to optimize them so that all
tasks participate in Gradle's incremental building feature.

----------------------------------------------------------------------------
EOF
  printf "\033[0m\n"
  
  wizard_pause "Press enter when you're ready to get started."
}

print_wrap_up() {
  wizard "Did you find any tasks to optimize? If so, great! You are one step \
closer to a faster build and a more productive team."
  wizard "If you did find something to optimize, then you will want to run this \
expirment again after you have implemented the optimizations (to validate the \
optimizations were effective.)"
  wizard "You will not have to go through this wizard again (that would be annoying). \
Instead, as long as you do not delete the experiment directory (${experiment_dir}), \
then the wizard will be skipped (the experiment will run without interruption). If for some \
reason the experiment directory does get deleted, then you can skip the wizard \
by running the script with the --no-wizard flag:"

  wizard "${script_name} --no-wizard --task ${task}"

  wizard "Cheers!"
}

main
