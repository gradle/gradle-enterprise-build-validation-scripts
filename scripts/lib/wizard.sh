#!/usr/bin/env bash

wizard() {
  local text
  text="$(echo "${1}" | fmt -w 78)"

  print_wizard_text "${text}" "
"
}

wait_for_enter() {
  read -r
  UP_ONE_LINE="\033[1A"
  ERASE_LINE="\033[2K"
  echo -en "${UP_ONE_LINE}${ERASE_LINE}"
  echo -en "${UP_ONE_LINE}${ERASE_LINE}"
  echo -en "${UP_ONE_LINE}${ERASE_LINE}"
}


print_wizard_text()
{
  echo "${RESTORE}"
  printf '=%.0s' {1..80}
  echo
  echo -n "$@"
  echo
}

print_introduction_title() {
  cat <<EOF
${WHITE}Gradle Enterprise
Experiment ${EXP_NO}: ${EXP_DESCRIPTION}${RESTORE}
EOF
}

explain_experiment_dir() {
  wizard "All of the work we do for this experiment will be stored in
$(info "${EXP_DIR}")"
}

explain_collect_git_details() {
  local text
  IFS='' read -r -d '' text <<EOF
The experiment will run against a fresh checkout of a given project stored
in Git. The fresh checkout ensures reproducibility of the experiment across
machines and users since no local changes and commits will be accidentally
included in the validation process.

You can optionally validate and optimize the project against an existing
branch until you are satisfied and only then merge any improvements back to
the main line.
EOF
  print_wizard_text "${text}"
}

explain_collect_gradle_details() {
  local text
  IFS='' read -r -d '' text <<EOF
Once the project is checked out from Git, the experiment will invoke the
project’s contained Gradle build with a given set of tasks and an optional
set of arguments. The Gradle tasks to invoke should resemble what users
and/or CI typically invoke when building the project.

The build will be invoked from the project’s root directory or from a given
sub-directory.

In order to become familiar with the experiment, you might want to initially
choose a task that does not take too long to complete.
EOF
  print_wizard_text "${text}"
}

explain_collect_maven_details() {
  local text
  IFS='' read -r -d '' text <<EOF
Once the project is checked out from Git, the experiment will invoke the
project’s contained Maven build with a given set of goals and an optional
set of arguments. The Maven goals to invoke should resemble what users
and/or CI typically invoke when building the project.

The build will be invoked from the project’s root directory or from a given
sub-directory.

In order to become familiar with the experiment, you might want to initially
choose a goal that does not take too long to complete.
EOF
  print_wizard_text "${text}"
}

explain_clone_project() {
  local text
  IFS='' read -r -d '' text <<EOF
All configuration has been collected. The experiment can now commence by
checking out the Git repository that contains the project to validate.

${USER_ACTION_COLOR}Press enter to check out the project from Git.
EOF
  print_wizard_text "${text}"
  wait_for_enter
}

explain_warnings() {
  local warnings_file="${EXP_DIR}/${project_name}/warnings.txt"

  if [ -f "${warnings_file}" ]; then
    local text
    IFS='' read -r -d '' text <<EOF
When running the builds, I detected some suboptimal configurations, which
are listed above. These aren't necessarily problems, but resolving these
warnings will allow you to take full advantage of Gradle Enterprise.

${USER_ACTION_COLOR}Press <Enter> to continue.${RESTORE}
EOF
    print_wizard_text "${text}"
    wait_for_enter
 fi
}

explain_how_to_repeat_the_experiment() {
  read_scan_info
  local text
  cat <<EOF
Below is the command you can use to repeat the experiment (without running
in interactive mode):

$(print_command_to_repeat_experiment)

You may want to repeat the experiment in order to validate optimizations you
have implemented. It is also a best practice to repeat the experiment
periodically (so as to catch regressions in the build optimization).
EOF
}

