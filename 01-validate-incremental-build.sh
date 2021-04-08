#!/usr/bin/env bash
#
# Runs Experiment 01 -  Optimize for incremental building
#
# Invoke this script with --help to get a description of the command line arguments
#
script_dir="$(cd "$(dirname "$(readlink -e "${BASH_SOURCE[0]}")")" && pwd)"
script_name=$(basename "$0")
experiment_dir="${script_dir}/data/${script_name%.*}"

# Include and parse the command line arguments
# shellcheck source=experiments/lib/01/parsing.sh
source "${script_dir}/lib/01/parsing.sh" || { echo "Couldn't find '${script_dir}/lib/01/parsing.sh' parsing library."; exit 1; }

run_id=$(uuidgen)

main() {
  if [ "$_arg_wizard" == "on" ]; then
    wizard_execute
  else
    execute
  fi
}

execute() {
 print_experiment_name
 print_scan_tags

 make_experiment_dir

 load_settings
 collect_project_details
 collect_gradle_task

 clone_project

 execute_first_build
 execute_second_build

 save_settings
 print_summary
}

wizard_execute() {
 print_introduction

 explain_scan_tags

 explain_experiment_dir
 make_experiment_dir

 load_settings

 collect_project_details

 explain_collect_gradle_task
 collect_gradle_task

 explain_clone_project
 clone_project

 explain_first_build
 execute_first_build

 explain_second_build
 execute_second_build

 save_settings
 print_summary
 explain_summary
}

print_experiment_name() {
  info
  info "Experiment 01: Validate Incremental Build"
  info "-----------------------------------------"
}

print_scan_tags() {
  local fmt="%-20s%-10s"

  info
  infof "$fmt" "Experiment Tag:" "exp1"
  infof "$fmt" "Experiment Run ID:" "${run_id}"
}

collect_project_details() {

  if [ -n "${_arg_git_url}" ]; then
     project_url=$_arg_git_url
  else
    echo
    read -r -p "What is the project's GitHub URL? " project_url
  fi

  if [ -n "${_arg_branch}" ]; then
     project_branch=$_arg_branch
  else
     read -r -p "What branch should we checkout (press enter to use the project's default branch)? " project_branch
  fi

  project_name=$(basename -s .git "${project_url}")
}

collect_gradle_task() { 
  if [ -z "$_arg_task" ]; then
    echo
    read -r -p "What Gradle task do you want to run? (assemble) " task

    if [[ "${task}" == "" ]]; then
      task=assemble
    fi
  else
    task=$_arg_task
  fi
}

save_settings() {
  if [ ! -f "${_arg_settings}" ]; then
    cat << EOF > "${_arg_settings}"
GIT_URL=${project_url}
GIT_BRANCH=${project_branch}
GRADLE_TASK=${task}
EOF
  fi
}

load_settings() {
  if [ -f  "${_arg_settings}" ]; then
    # shellcheck source=/dev/null # this file is created by the user so nothing for shellcheck to check
    source "${_arg_settings}"

    if [ -z "${_arg_git_url}" ]; then
      _arg_git_url="${GIT_URL}"
    fi
    if [ -z "${_arg_branch}" ]; then
      _arg_branch="${GIT_BRANCH}"
    fi
    if [ -z "${_arg_task}" ]; then
      _arg_task="${GRADLE_TASK}"
    fi

    info
    info "Loaded settings from ${_arg_settings}"
  fi
}

make_experiment_dir() {
  mkdir -p "${experiment_dir}"
}

clone_project() {
   info
   info "Cloning ${project_name}"

   local clone_dir="${experiment_dir}/${project_name}"

   local branch=""
   if [ -n "${project_branch}" ]; then
      branch="--branch ${project_branch}"
   fi

   rm -rf "${clone_dir}"
   # shellcheck disable=SC2086  # we want $branch to expand into multiple arguments
   git clone --depth=1 ${branch} "${project_url}" "${clone_dir}" || die "Unable to clone from ${project_url} Aborting!" 1
   cd "${clone_dir}" || die "Unable to access ${clone_dir}. Aborting!" 1
   info
}

execute_first_build() {
  info "Running first build (invoking clean)."
  info 
  info "./gradlew --no-build-cache -Dscan.tag.exp1 -Dscan.tag.${run_id} clean ${task}"

  invoke_gradle --no-build-cache clean "${task}"
}

execute_second_build() {
  info "Running second build (without invoking clean)."
  info 
  info "./gradlew --no-build-cache -Dscan.tag.exp1 -Dscan.tag.${run_id} ${task}"

  invoke_gradle --no-build-cache "${task}"
}

invoke_gradle() {
  # The gradle --init-script flag only accepts a relative directory path. ¯\_(ツ)_/¯
  local script_dir_rel
  script_dir_rel=$(realpath --relative-to="$( pwd )" "${script_dir}")
  ./gradlew \
      --init-script "${script_dir_rel}/lib/verify-ge-configured.gradle" \
      --init-script "${script_dir_rel}/lib/capture-build-scan-info.gradle" \
      -Dscan.tag.exp1 \
      -Dscan.tag."${run_id}" \
      "$@" \
      || exit 1
}

read_scan_info() {
  base_url=()
  scan_url=()
  scan_id=()
  # This isn't the most robust way to read a CSV,
  # but we control the CSV so we don't have to worry about various CSV edge cases
  while IFS=, read -r field_1 field_2 field_3; do
     base_url+=("$field_1")
     scan_id+=("$field_2")
     scan_url+=("$field_3")
  done < scans.csv
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
 infof "$fmt" "Gradle Task(s):" "${task}"
 infof "$fmt" "Experiment Dir:" "${experiment_dir}"
 infof "$fmt" "Experiment Tag:" "exp1"
 infof "$fmt" "Experiment Run ID:" "${run_id}"
 print_build_scans
 print_starting_points
}

print_build_scans() {
 local fmt="%-25s%-10s"
 infof "$fmt" "First Build Scan:" "${scan_url[0]}"
 infof "$fmt" "Second Build Scan:" "${scan_url[1]}"
}

print_starting_points() {
 local fmt="%-25s%-10s"
 info 
 info "SUGGESTED STARTING POINTS"
 info "----------------------------"
 infof "$fmt" "Scan Comparision:" "${base_url[0]}/c/${scan_id[0]}/${scan_id[1]}/task-inputs?cacheability=cacheable"
 infof "$fmt" "Longest-running tasks:" "${base_url[0]}/s/${scan_id[1]}/timeline?outcome=SUCCESS,FAILED&sort=longest"
 info
}

info() {
  printf "${YELLOW}${BOLD}%s${RESTORE}\n" "$1"
}

infof() {
  local format_string="$1"
  shift
  # the format string is constructed from the caller's input. There is no
  # good way to rewrite this that will not trigger SC2059, so outright
  # disable it here.
  # shellcheck disable=SC2059  
  printf "${YELLOW}${BOLD}${format_string}${RESTORE}\n" "$@"
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
${CYAN}xXXXXXXXXXXXXXXXXXXXXXXXXXXXXXc          Experiment 01:
${CYAN}KXXXXXXXXXXXXXXXXXXXXXXXXXXXXl           Validate Incremental Build
${CYAN}XXXXXXklclkXXXXXXXklclxKXXXXK
${CYAN}OXXXk.     .OXXX0'     .xXXXx
${CYAN}oKKK'       ,KKK:       .KKKo

Wecome! This is the first of several experiments that are part of your
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
EOF

  print_in_box "${text}"
  wizard_pause "Press enter when you're ready to get started."
}

explain_scan_tags() {
  local text
  IFS='' read -r -d '' text <<EOF
Below are some tags we are going to add to the build scans for this
experiment. 
$(print_scan_tags)

Every time you run this script, we'll generate a new unique ID. This ID is
added as a tag on the build scans from this run, which makes it easy to find
the build scans for each run of the experiment. 

You can use the 'exp1' tag to easily find all of the build scans for all
runs of this experiment.
EOF
  print_in_box "${text}"
}

explain_experiment_dir() {
  wizard "All of the work we do for this experiment will be stored in
${YELLOW}${experiment_dir}"
}

explain_collect_gradle_task() {
  if [ -z "$_arg_task" ]; then
    wizard "We need a build task (or tasks) to run on each build of the experiment. If this is the first \
time you are running the experiment, then you may want to run a task that doesn't take very long to \
complete. You can run more complete (and longer) builds after you become more comfortable with running \
the experiment."
  fi
}

explain_clone_project() {
  wizard "We are going to create a fresh checkout of your project. That way, the experiment will be \
infleunced by as few outside factors as possible)."
}

explain_first_build() {
 local build_command
  build_command="${YELLOW}./gradlew --no-build-cache \\
  ${YELLOW}-Dscan.tag.exp1 \\
  ${YELLOW}-Dscan.tag.${run_id} \\
  ${YELLOW} clean ${task}"

  local text
  IFS='' read -r -d '' text <<EOF
OK! We are ready to run our first build!

For this run, we'll execute 'clean ${task}'. 

We are invoking clean even though we just created a fresh clone because
sometimes the clean task changes the order other tasks run in, which can
impact how incremental building works.

We will also add a flag to make sure build caching is disabled (since we are
just focused on incremental building for now), and we will add the build
scan tags we talked about before.

Effectively, this is what we are going to run:

${build_command}
EOF
  print_in_box "${text}"
  wizard_pause "Press enter to run the first build."
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
EOF
  print_in_box "$text"
  wizard_pause "Press enter to run the second build."
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

$(info "./${script_name}")

Congrats! You have completed this experiment.
EOF
  print_in_box "${text}"
}

wizard() {
  local text
  text=$(echo "${1}" | fmt -w 78)

  print_in_box "${text}"
}

wizard_pause() {
  echo "${YELLOW}"
  read -r -p "$1"
  echo "${RESTORE}"
}


function print_in_box()
{
  local lines b w

  # Convert the input into an array
  #   In bash, this is tricky, expecially if you want to preserve leading 
  #   whitespace and blank lines!
  ifs_bak=$IFS
  IFS=''
  while read -r line; do
    lines+=( "$line" )
  done <<< "$*"
  IFS=${ifs_bak}

  # Calculate the longest text width (w is witdh), excluding color codes
  # Also save the longest line in b ('b' for buffer)
  #    We'll use 'b' later to fill in the top and bottom borders
  for l in "${lines[@]}"; do
    local no_color
    # shellcheck disable=SC2001  # I could only get this to work with sed
    no_color="$(echo "$l" | sed $'s,\x1b\\[[0-9;]*[a-zA-Z],,g')"
    ((w<${#no_color})) && { b="$no_color"; w="${#no_color}"; }
  done

  echo -n "${BOX_COLOR}"
  echo "┌─${b//?/─}─┐"
  for l in "${lines[@]}"; do
    # Adjust padding for color codes (add spaces for removed color codes)
    local no_color padding
    # shellcheck disable=SC2001  # I could only get this to work with sed
    no_color="$(echo "$l" | sed $'s,\x1b\\[[0-9;]*[a-zA-Z],,g')"
    padding=$((w+${#l}-${#no_color}))
    printf '│ %s%*s%s │\n' "${WIZ_COLOR}" "-$padding" "$l" "${BOX_COLOR}"
  done
  echo "│ ${b//?/ } │"
  echo "└─${b//?/─}─┘"
  echo -n "${RESTORE}"
}

# Color and text escape sequences
RESTORE=$(echo -en '\033[0m')
YELLOW=$(echo -en '\033[00;33m')
BLUE=$(echo -en '\033[00;34m')
CYAN=$(echo -en '\033[00;36m')

BOLD=$(echo -en '\033[1m')

WIZ_COLOR="${BLUE}${BOLD}"
BOX_COLOR="${CYAN}"

main

