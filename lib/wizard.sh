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
