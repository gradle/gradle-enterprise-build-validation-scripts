#!/usr/bin/env bash
#
# Runs Experiment 01 -  Optimize incremental build
#
# TODO Provide usage and help
# TODO Accept some paramters as command-line arguments
set -e
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" > /dev/null && pwd )"
current_dir="$( pwd )"
script_dir_rel=$(realpath --relative-to="${current_dir}" "${script_dir}")

exp_id=$(uuidgen)
echo "Experiment 3: ${exp_id}"

main() {
 collect_gradle_task
 execute_first_build
 execute_second_build
 open_build_scan

 printf "\n\033[00;32mDONE\033[0m\n"
}

collect_gradle_task() {
  read -p "What gradle task do you want to run (default: build)? " task
  if [[ "$task" == "" ]]; then
    task=build
  fi

  echo
  echo
}

execute_first_build() {
  info "Running first build with build caching disabled"
  invoke_gradle "./gradlew --no-build-cache -Dscan.tag.exp1 -Dscan.tag.${exp_id} clean ${task}"
  echo
}

execute_second_build() {
  info "Running 2nd build without invoking clean"
  invoke_gradle "./gradlew --no-build-cache -Dscan.tag.exp1 -Dscan.tag.${exp_id} ${task}"
  echo
}

open_build_scan() {
  read -p "Press enter to to open the build scan in your default browser."
  OS=$(uname)
  case $OS in
    'Darwin') browse=open ;;
    'WindowsNT') browse=start ;;
    *) browse=xdg-open ;;
  esac
  $browse "${build_scan_url}/timeline?outcomeFilter=SUCCESS"
}

invoke_gradle() {
  cmd=$1
  exec 5>&1
  output=$($cmd | tee >(cat - >&5))
  build_scan_url=$(echo -e "$output" | grep "Publishing build scan..." -A 1 | tail -n 1)
}

info () {
  printf "\033[00;34m...\033[0m$1\n"
}


main

