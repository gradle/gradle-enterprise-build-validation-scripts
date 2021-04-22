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


function print_wizard_text()
{
  echo
  printf '=%.0s' {1..80}
  echo
  echo -n "$@"
  echo
}

explain_scan_tags() {
  local text
  IFS='' read -r -d '' text <<EOF

We are going to add a few scan tags to make it easy to find the build scans
generated during this experiment:

$(print_experiment_info)

Every time you run this script, we'll generate a unique run ID. You can use
the run ID to find the build scans from a specific run of the experiment.

You can use the '${EXP_SCAN_TAG}' tag to find all of the build scans for all
runs of this experiment.
EOF
  print_wizard_text "${text}"
}

print_experiment_info() {
  local fmt="%-20s%-10s"

  infof "$fmt" "Experiment id:" "${EXP_SCAN_TAG}"
  infof "$fmt" "Experiment run id:" "${RUN_ID}"
}

print_introduction_title() {
  cat <<EOF
${WHITE}Gradle Enterprise
Experiment ${EXP_NO}: ${EXP_NAME}${RESTORE}
EOF
}

explain_experiment_dir() {
  wizard "All of the work we do for this experiment will be stored in
$(info "${EXPERIMENT_DIR}")"
}

explain_collect_gradle_details() {
  wizard "We need the Gradle task (or tasks) to run on each build of the experiment. If this is the first \
time you are running the experiment, then you may want to run a task that doesn't take very long to \
complete. You can run more complete (and longer) builds after you become more comfortable with running \
the experiment."
}

explain_collect_maven_details() {
  wizard "We need a Maven goal (or goals) to run on each build of the experiment. If this is the first \
time you are running the experiment, then you may want to run a goal that doesn't take very long to \
complete. You can run more complete (and longer) builds after you become more comfortable with running \
the experiment."
}

explain_clone_project() {
  local text
  IFS='' read -r -d '' text <<EOF
We are going to create a fresh clone of your project. That way, the experiment will be
infleunced by as few outside factors as possible."

${USER_ACTION_COLOR}Press enter to clone the project.
EOF
  print_wizard_text "${text}"
  wait_for_enter
}

explain_warnings() {
  local warnings_file="${EXPERIMENT_DIR}/${project_name}/warnings.txt"

  if [ -f "${warnings_file}" ]; then
    local text
    IFS='' read -r -d '' text <<EOF
^^^

When running the builds, I detected some suboptimal configurations, which
are listed above (^^^) as WARNINGs. These things aren't necessarily
problems, but resolving these warnings will allow you to take full advantage
of Gradle Enterprise.

${USER_ACTION_COLOR}Press enter to continue.
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

