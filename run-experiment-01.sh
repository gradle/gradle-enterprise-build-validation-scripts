#!/usr/bin/env bash
#
# Runs Experiment 01 -  Optimize for incremental building
#
set -e
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" > /dev/null && pwd )"
project_dir="$( pwd )"
project_name=$( basename ${project_dir} )
experiment_dir="$project_dir/build/enterprise-trial-experiments/experiment-01"

run_id=$(uuidgen)

main() {
 info "Experiment 1: Optimize for Incremental Building"
 info "Experiment Run ID: ${run_id}"
 info

 collect_gradle_task
 make_experiment_dir
 clone_project
 execute_first_build
 execute_second_build
 open_build_scan_comparison

 cd ${project_dir}
 printf "\n\033[00;32mDONE\033[0m\n"
}

collect_gradle_task() {
  read -p "What Gradle task do you want to run? (build) " task
  if [[ "${task}" == "" ]]; then
    task=build
  fi

  echo
  echo
}

make_experiment_dir() {
  mkdir -p "${experiment_dir}"
}

clone_project() {
   info "Creating a clean clone of the project."

   local clone_dir="${experiment_dir}/${project_name}"

   rm -rf "${clone_dir}"
   git clone "${project_dir}" "${clone_dir}"
   cd "${clone_dir}"
}

execute_first_build() {
  info "Running first build (invoking clean)."
  invoke_gradle clean ${task}
  echo
}

execute_second_build() {
  info "Running second build (without invoking clean)."
  invoke_gradle ${task}
  echo
}

open_build_scan_comparison() {
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

  read -p "Press enter to to open the build scan in your default browser."
  local OS=$(uname)
  case $OS in
    'Darwin') browse=open ;;
    'WindowsNT') browse=start ;;
    *) browse=xdg-open ;;
  esac
  $browse "${base_url[0]}/c/${scan_id[0]}/${scan_id[1]}/task-inputs"
}

invoke_gradle() {
  # The gradle --init-script flag only accepts a relative directory path. ¯\_(ツ)_/¯
  local script_dir_rel=$(realpath --relative-to="$( pwd )" "${script_dir}")
  local cmd="./gradlew --init-script ${script_dir_rel}/capture-build-scan-info.gradle -Dscan.tag.exp1 -Dscan.tag.${run_id} $@"
  echo $cmd
  $cmd
}

info () {
  printf "\033[00;34m$1\033[0m\n"
}


main
