#!/usr/bin/env bash

wizard() {
  local text
  text="$(echo "${1}" | fmt -w 78)"

  print_in_box "${text}" "
"
}

wait_for_enter() {
  read -r
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
  echo "└─${b//?/─}─┘"
  echo -n "${RESTORE}"
}

explain_experiment_info() {
  local text
  IFS='' read -r -d '' text <<EOF
Below is some basic information about the experiment:

$(print_experiment_info)

We will add the "Experiment id" and "Experiment run id" as scan tags on the
build scans.

Every time you run this script, we'll generate a new unique run ID.
You can use the run ID to find the build scans from a specific run of the
experiment.

You can use the '${EXP_SCAN_TAG}' tag to find all of the build scans for all
runs of this experiment.
EOF
  print_in_box "${text}"
}

print_introduction_title() {
  cat <<EOF
${CYAN}                              ;x0K0d,
${CYAN}                            kXOxx0XXO,
${CYAN}              ....                '0XXc
${CYAN}       .;lx0XXXXXXXKOxl;.          oXXK
${CYAN}      xXXXXXXXXXXXXXXXXXX0d:.     ,KXX0
${CYAN}     .,KXXXXXXXXXXXXXXXXXO0XXKOxkKXXXX:
${CYAN}   lKX:'0XXXXXKo,dXXXXXXO,,XXXXXXXXXK;   Gradle Enterprise
${CYAN} ,0XXXXo.oOkl;;oKXXXXXXXXXXXXXXXXXKo.
${CYAN}:XXXXXXXKdllxKXXXXXXXXXXXXXXXXXX0c.
${CYAN}'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXk'
${CYAN}xXXXXXXXXXXXXXXXXXXXXXXXXXXXXXc          Experiment ${EXP_NO}:
${CYAN}KXXXXXXXXXXXXXXXXXXXXXXXXXXXXl           ${EXP_NAME}
${CYAN}XXXXXXklclkXXXXXXXklclxKXXXXK
${CYAN}OXXXk.     .OXXX0'     .xXXXx
${CYAN}oKKK'       ,KKK:       .KKKo
EOF
}

explain_experiment_dir() {
  wizard "All of the work we do for this experiment will be stored in
$(info "${EXPERIMENT_DIR}")"
}

explain_collect_gradle_task() {
  if [ -z "$_arg_tasks" ]; then
    wizard "We need a build task (or tasks) to run on each build of the experiment. If this is the first \
time you are running the experiment, then you may want to run a task that doesn't take very long to \
complete. You can run more complete (and longer) builds after you become more comfortable with running \
the experiment."
  fi
}

explain_collect_maven_goals() {
  if [ -z "$_arg_task" ]; then
    wizard "We need a Maven goal (or goals) to run on each build of the experiment. If this is the first \
time you are running the experiment, then you may want to run a goal that doesn't take very long to \
complete. You can run more complete (and longer) builds after you become more comfortable with running \
the experiment."
  fi
}

explain_clone_project() {
  local text
  IFS='' read -r -d '' text <<EOF
We are going to create a fresh clone of your project. That way, the experiment will be
infleunced by as few outside factors as possible."

${USER_ACTION_COLOR}Press enter to clone the project.
EOF
  print_in_box "${text}"
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
    print_in_box "${text}"
    wait_for_enter
 fi
}
