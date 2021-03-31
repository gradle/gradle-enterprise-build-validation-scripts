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

run_id=$(uuidgen)
echo "Experiment 1: Optimize Incremental Building"
echo "Experiment Run ID: ${run_id}"

main() {
 collect_gradle_task
 execute_first_build
 execute_second_build
 open_build_scan

 printf "\n\033[00;32mDONE\033[0m\n"
}

collect_gradle_task() {
  read -p "What gradle task do you want to run? (build) " task
  if [[ "$task" == "" ]]; then
    task=build
  fi

  echo
  echo
}

execute_first_build() {
  info "Running first build (invoking clean)"
  invoke_gradle "./gradlew \
      --init-script ${script_dir_rel}/capture-build-scan-info.gradle \
      --no-build-cache \
      -Dscan.tag.exp1 \
      -Dscan.tag.${run_id} \
      clean ${task}"
  echo
}

execute_second_build() {
  info "Running second build (without invoking clean)"
  invoke_gradle "./gradlew --init-script ${script_dir_rel}/capture-build-scan-info.gradle --no-build-cache -Dscan.tag.exp1 -Dscan.tag.${run_id} ${task}"
  echo
}

open_build_scan() {
  scan_url=""
  while IFS=, read -r base_url id url; do
     scan_url=$url
  done <<< "$(tail -n 1 scans.csv)"

  read -p "Press enter to to open the build scan in your default browser."
  OS=$(uname)
  case $OS in
    'Darwin') browse=open ;;
    'WindowsNT') browse=start ;;
    *) browse=xdg-open ;;
  esac
  $browse "${scan_url}/timeline?outcomeFilter=SUCCESS"
}

invoke_gradle() {
  cmd=$1
  echo $cmd
  $cmd
}

info () {
  printf "\033[00;34m$1\033[0m\n"
}


main

