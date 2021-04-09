#!/usr/bin/env bash
#
# Runs Experiment 02 - Validate Build Caching - Local - In Place 
#
# Invoke this script with --help to get a description of the command line arguments
#
script_dir="$(cd "$(dirname "$(readlink -e "${BASH_SOURCE[0]}")")" && pwd)"
script_name=$(basename "$0")

# Experiment-speicifc constants
EXP_NAME="Validate Build Caching - Local - In Place"
EXP_NO="02"
EXP_SCAN_TAG=exp2
RUN_ID=$(uuidgen)
experiment_dir="${script_dir}/data/${script_name%.*}"
scan_file="${experiment_dir}/scans.csv"

build_cache_dir="${experiment_dir}/build-cache"

# Include and parse the command line arguments
# shellcheck source=experiments/lib/02/parsing.sh
source "${script_dir}/lib/02/parsing.sh" || { echo "Couldn't find '${script_dir}/lib/01/parsing.sh' parsing library."; exit 1; }

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
 make_local_cache_dir
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

 explain_local_cache_dir
 make_local_cache_dir

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
  info "Experiment ${EXP_NO}: ${EXP_NAME}"
  info "-----------------------------------------"
}

print_scan_tags() {
  local fmt="%-20s%-10s"

  info
  infof "$fmt" "Experiment Tag:" "${EXP_SCAN_TAG}"
  infof "$fmt" "Experiment Run ID:" "${RUN_ID}"
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
  rm -f "${scan_file}"
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

make_local_cache_dir() {
  rm -rf "${build_cache_dir}"
  mkdir -p "${build_cache_dir}"
}

execute_first_build() {
  info "Running first build."
  info 
  info "./gradlew -Dscan.tag.${EXP_SCAN_TAG} -Dscan.tag.${RUN_ID} clean ${task}"

  invoke_gradle clean "${task}"
}

execute_second_build() {
  info "Running second build."
  info 
  info "./gradlew -Dscan.tag.${EXP_SCAN_TAG} -Dscan.tag.${RUN_ID} clean ${task}"

  invoke_gradle clean "${task}"
}

invoke_gradle() {
  # The gradle --init-script flag only accepts a relative directory path. ¯\_(ツ)_/¯
  local script_dir_rel
  script_dir_rel=$(realpath --relative-to="$( pwd )" "${script_dir}")
  ./gradlew \
      --init-script "${script_dir_rel}/lib/verify-ge-configured.gradle" \
      --init-script "${script_dir_rel}/lib/02/verify-and-configure-build-cache.gradle" \
      --init-script "${script_dir_rel}/lib/capture-build-scan-info.gradle" \
      -Dscan.tag.${EXP_SCAN_TAG} \
      -Dscan.tag."${RUN_ID}" \
      "$@" \
      || die "The experiment cannot continue because the build failed." 1
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
  done < "${scan_file}"
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
 infof "$fmt" "Gradle task(s):" "${task}"
 infof "$fmt" "Experiment dir:" "${experiment_dir}"
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
 infof "$fmt" "Cache performance:" "${base_url[0]}/s/${scan_id[1]}/performance/build-cache"
 infof "$fmt" "Executed cachable tasks:" "${base_url[0]}/s/${scan_id[1]}/timeline?cacheableFilter=cacheable&outcomeFilter=SUCCESS"
 infof "$fmt" "Uncachable tasks:" "${base_url[0]}/s/${scan_id[1]}/timeline?cacheableFilter=any_non-cacheable&outcomeFilter=SUCCESS"
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
${CYAN}xXXXXXXXXXXXXXXXXXXXXXXXXXXXXXc          Experiment ${EXP_NO}:
${CYAN}KXXXXXXXXXXXXXXXXXXXXXXXXXXXXl           ${EXP_NAME}
${CYAN}XXXXXXklclkXXXXXXXklclxKXXXXK
${CYAN}OXXXk.     .OXXX0'     .xXXXx
${CYAN}oKKK'       ,KKK:       .KKKo

This is the second of several experiments that are part of your
Gradle Enterprise Trial. Each experiment will help you to make concrete
improvements to your existing build. The experiments will also help you to
build the data necessary to recommend Gradle Enerprise to your organization.

This script (and the other experiment scripts) will run some of the
experiment steps for you, but we'll walk you through each step so that you
know exactly what we are doing, and why.

In this experiment, we will be checking your build to see how well it takes
advantage of the local build cache. When the build cache is enabled, Gradle
saves the output from tasks so that the same output can be reused if the
task is executed again with the same inputs. This is similar to incremental
build, except that the cache is used across build runs. So even if you
perform a clean, cached output will be used if the inputs to a task have not
changed.

To test out the build cache, we'll run two builds (with build caching
enabled). Both builds will invoke clean and run the same tasks. We will not
make any changes between each build run.

If the build is taking advantage of the local build cache, then very few (if
any) tasks should actually execute on the seond build (all of the task
output should be used from the local cache).

The Gradle Solutions engineer will then work with you to figure out why some
(if any) tasks ran on the second build, and how to optimize them to take
advantage of the build cache.
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

You can use the '${EXP_SCAN_TAG}' tag to easily find all of the build scans for all
runs of this experiment.
EOF
  print_in_box "${text}"
}

explain_experiment_dir() {
  wizard "All of the work we do for this experiment will be stored in
$(info "${experiment_dir}")"
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

explain_local_cache_dir() {
  local text
  IFS='' read -r -d '' text <<EOF
We are going to create a new empty local build cache dir (and configure
Gradle to use it instead of the default local cache dir). This way, the
first build won't find anything in the cache and all tasks will run. 

This is mportant beause we want to make sure tasks that are cachable do in
fact produce output that is stored in the cache.

Specifically, we are going to create and use this directory for the local
build cache (we'll delete it if it already exists from a previous run of the
experiment):

$(info "${build_cache_dir}")
EOF
  print_in_box "${text}"
  wizard_pause "Press enter to continue."
}

explain_first_build() {
 local build_command
  build_command="${YELLOW}./gradlew \\
  ${YELLOW}-Dscan.tag.${EXP_SCAN_TAG} \\
  ${YELLOW}-Dscan.tag.${RUN_ID} \\
  ${YELLOW} clean ${task}"

  local text
  IFS='' read -r -d '' text <<EOF
OK! We are ready to run our first build!

For this run, we'll execute 'clean ${task}'. 

We are invoking clean even though we just created a fresh clone because
sometimes the clean task changes the order other tasks run in, which can
impact how the build cache is utilized.

We will also add the build scan tags we talked about before.

Effectively, this is what we are going to run:

${build_command}
EOF
  print_in_box "${text}"
  wizard_pause "Press enter to run the first build."
}

explain_second_build() {
  local text
  IFS='' read -r -d '' text <<EOF
Now we are going to run the build again without changing anything.

In a fully optimized build, no tasks would run on this second build because
we already built everything in the first build, and the task outputs should
be in the local build cache. If some tasks do run, they will show up in the
build scan for this second build.
EOF
  print_in_box "$text"
  wizard_pause "Press enter to run the second build."
}

explain_summary() {
  read_scan_info
  local text
  IFS='' read -r -d '' text <<EOF
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

The "Cache performance" link takes you to the build cache performance page
of the 2nd build scan. This page contains various metrics related to the
build cache (such as cache hits and misses).

The "Executed cachable tasks" link shows you which tasks ran again on the
second build, but shouldn't have because they are actually cachable. If any
cachable tasks ran, then one of their inputs changed (even though we didn't
make any changes), or they may not be declaring their inputs correctly.

The last link, "Uncachable tasks", shows you which tasks ran that are not
cachable. It is not always possible, or doesn't make sense the output from
every task. For example, there's no way to cache the "output" of the clean
task because the clean task deletes output rather than creating it.

If you find something to optimize, then you will want to run this expirment
again after you have implemented the optimizations (to validate the
optimizations were effective). You will not need to run this wizard again.
All of your settings have been saved, so all you need to do to run this
experiment again without the wizard is to invoke this script without any
arguments:

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

