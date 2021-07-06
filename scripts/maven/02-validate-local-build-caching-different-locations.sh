#!/usr/bin/env bash
#
# Runs Experiment 03 - Validate local build caching - different project locations
#
# Invoke this script with --help to get a description of the command line arguments
#
readonly EXP_NAME="Validate local build caching - different project locations"
readonly EXP_DESCRIPTION="Validating that a Maven build is optimized for local build caching when invoked from different locations"
readonly EXP_NO="02"
readonly EXP_SCAN_TAG=exp2-maven
readonly BUILD_TOOL="Maven"
readonly SCRIPT_VERSION="<HEAD>"

# Needed to bootstrap the script
SCRIPT_NAME=$(basename "$0")
readonly SCRIPT_NAME
SCRIPT_DIR="$(cd "$(dirname "$(readlink -e "${BASH_SOURCE[0]}")")" && pwd)"
readonly SCRIPT_DIR
readonly LIB_DIR="${SCRIPT_DIR}/../lib"

# Include and parse the command line arguments
# shellcheck source=lib/maven/02-cli-parser.sh
source "${LIB_DIR}/maven/${EXP_NO}-cli-parser.sh" || { echo "Couldn't find '${LIB_DIR}/maven/${EXP_NO}-cli-parser.sh' parsing library."; exit 1; }
# shellcheck source=lib/libs.sh
source "${LIB_DIR}/libs.sh" || { echo "Couldn't find '${LIB_DIR}/libs.sh'"; exit 1; }

# These will be set by the config functions (see lib/config.sh)
git_repo=''
project_name=''
git_branch=''
project_dir=''
tasks=''
extra_args=''
enable_ge=''
ge_server=''
interactive_mode=''

main() {
  if [ "${interactive_mode}" == "on" ]; then
    wizard_execute
  else
    execute
  fi
  create_receipt_file
}

execute() {
  print_bl
  validate_required_config

  make_experiment_dir
  make_local_cache_dir
  git_checkout_project "first-build_${project_name}"
  print_bl
  git_copy_project "first-build_${project_name}" "second-build_${project_name}"

  print_bl
  execute_first_build

  print_bl
  execute_second_build

  print_bl
  print_summary
  print_bl
}

wizard_execute() {
  print_bl
  print_introduction

  print_bl
  explain_collect_git_details
  print_bl
  collect_git_details

  print_bl
  explain_collect_maven_details
  print_bl
  collect_maven_details

  print_bl
  explain_first_clone_project
  print_bl
  make_experiment_dir
  make_local_cache_dir
  git_checkout_project "first-build_${project_name}"

  print_bl
  explain_copy_project
  print_bl
  git_copy_project "first-build_${project_name}" "second-build_${project_name}"

  print_bl
  explain_first_build
  print_bl
  execute_first_build

  print_bl
  explain_second_build
  print_bl
  execute_second_build

  print_bl
  explain_measure_build_results
  print_bl
  explain_and_print_summary
  print_bl
}

execute_first_build() {
  info "Running first build:"
  info "./mvnw -Dscan.tag.${EXP_SCAN_TAG} -Dscan.value.runId=${RUN_ID} clean ${tasks}$(print_extra_args)"

  # shellcheck disable=SC2086  # we want tasks to expand with word splitting in this case
  invoke_maven \
     -Dgradle.cache.local.enabled=true \
     -Dgradle.cache.remote.enabled=false \
     -Dgradle.cache.local.directory="${BUILD_CACHE_DIR}" \
     clean ${tasks}
}

execute_second_build() {
  info "Running second build:"
  info "./mvnw -Dscan.tag.${EXP_SCAN_TAG} -Dscan.value.runId=${RUN_ID} clean ${tasks}$(print_extra_args)"

  cd "${EXP_DIR}/second-build_${project_name}" || die "Unable to cd to ${EXP_DIR}/second-build_${project_name}" 2

  # shellcheck disable=SC2086  # we want tasks to expand with word splitting in this case
  invoke_maven \
     -Dgradle.cache.local.enabled=true \
     -Dgradle.cache.remote.enabled=false \
     -Dgradle.cache.local.directory="${BUILD_CACHE_DIR}" \
     clean ${tasks}
}

print_summary() {
  read_build_scan_metadata
  print_experiment_info
  print_build_scans
  print_warnings
  print_bl
  print_quick_links
}

print_build_scans() {
  summary_row "Build scan first build:" "${build_scan_urls[0]}"
  summary_row "Build scan second build:" "${build_scan_urls[1]}"
}

print_quick_links() {
  info "Investigation Quick Links"
  info "-------------------------"
  summary_row "Goal execution overview:" "${base_urls[0]}/s/${build_scan_ids[1]}/performance/execution"
  summary_row "Executed goals timeline:" "${base_urls[0]}/s/${build_scan_ids[1]}/timeline?outcome=successful,failed&sort=longest"
  summary_row "Executed cacheable goals:" "${base_urls[0]}/s/${build_scan_ids[1]}/timeline?cacheability=cacheable&outcome=successful,failed&sort=longest"
  summary_row "Executed non-cacheable goals:" "${base_urls[0]}/s/${build_scan_ids[1]}/timeline?cacheability=any_non-cacheable&outcome=successful,failed&sort=longest"
  summary_row "Build caching statistics:" "${base_urls[0]}/s/${build_scan_ids[1]}/performance/build-cache"
  summary_row "Goal inputs comparison:" "${base_urls[0]}/c/${build_scan_ids[0]}/${build_scan_ids[1]}/goal-inputs?cacheability=cacheable"
}

print_introduction() {
  local text
  IFS='' read -r -d '' text <<EOF
$(print_introduction_title)

In this experiment, you will validate how well a given project leverages
Gradle Enterprise's local build caching functionality when running the build from different
locations. A build is considered fully cacheable if it can be invoked twice in a
row with build caching enabled and all cacheable goals avoid performing any work
because:

  * No cacheable goals were excluded from build caching to ensure correctness and
  * The cacheable goals’ inputs have not changed since their last invocation and
  * The cacheable goals’ outputs are present in the local build cache

The experiment will reveal goals with volatile inputs, for example goals that
contain a timestamp in one of their inputs. It will also reveal goals that produce
non-deterministic outputs consumed by cacheable goals downstream, for example
goals generating code with non-deterministic method ordering or goals producing
artifacts that include timestamps. In addition, the experiment will reveal
goals that contain an absolute file path in one of their inputs.

The experiment will assist you to first identify those goals whose outputs are
not taken from the local build cache due to changed inputs or to ensure
correctness of the build, to then make an informed decision which of those
goals are worth improving to make your build faster, to then investigate why
they are not taken from the local build cache, and to finally fix them once you
understand the root cause.

The experiment can be run on any developer’s machine. It logically consists of
the following steps:

  1. Enable local build caching and use an empty local build cache
  2. Run the build with a typical goal invocation including the ‘clean’ goal
  3. Run the build from a different location with the same goal invocation including the ‘clean’ goal
  4. Determine which cacheable goals are still executed in the second run and why
  5. Assess which of the executed, cacheable goals are worth improving
  6. Fix identified goals

The script you have invoked automates the execution of step 1, step 2, and step
3 without modifying the project. Build scans support your investigation in step
4 and step 5.

After improving the build to make it better leverage the local build cache, you
can push your changes and run the experiment again. This creates a cycle of run
→ measure → improve → run.

${USER_ACTION_COLOR}Press <Enter> to get started with the experiment.${RESTORE}
EOF

  print_wizard_text "${text}"
  wait_for_enter
}

explain_first_clone_project(){
  local text
  IFS='' read -r -d '' text <<EOF
$(print_separator)
${HEADER_COLOR}Check out project from Git for first build${RESTORE}

All configuration to run the experiment has been collected. For the first build,
the Git repository that contains the project to validate will be checked out.

${USER_ACTION_COLOR}Press <Enter> to check out the project from Git.${RESTORE}
EOF
  print_wizard_text "${text}"
  wait_for_enter
}

explain_first_build() {
  local text
  IFS='' read -r -d '' text <<EOF
$(print_separator)
${HEADER_COLOR}Run first build${RESTORE}

Now that the project has been checked out and copied to a different location,
the first build can be run with the given Maven goals. The build will be
invoked with the ‘clean’ goal included and local build caching enabled. An empty
local build cache will be used.

${USER_ACTION_COLOR}Press <Enter> to run the first build of the experiment.${RESTORE}
EOF
  print_wizard_text "${text}"
  wait_for_enter
}

explain_copy_project(){
  local text
  IFS='' read -r -d '' text <<EOF
$(print_separator)
${HEADER_COLOR}Copy project to different location for second build${RESTORE}

For the second build, the checked out Git repository that contains the project
to validate will be copied into a different location.

${USER_ACTION_COLOR}Press <Enter> to copy the project into a different location.${RESTORE}
EOF
  print_wizard_text "${text}"
  wait_for_enter
}

explain_second_build() {
  local text
  IFS='' read -r -d '' text <<EOF
$(print_separator)
${HEADER_COLOR}Run second build${RESTORE}

Now that the first build has finished successfully, the second build can be run
with the same Maven goals from a different location. The build will again be
invoked with the ‘clean’ goal included and local build caching enabled. The
local build cache populated during the first build will be used.

${USER_ACTION_COLOR}Press <Enter> to run the second build.${RESTORE}
EOF
  print_wizard_text "$text"
  wait_for_enter
}

explain_measure_build_results() {
  local text
  IFS='' read -r -d '' text <<EOF
$(print_separator)
${HEADER_COLOR}Measure build results${RESTORE}

Now that the second build has finished successfully, you are ready to measure in
Gradle Enterprise how well your build leverages the local build cache for
the invoked set of Maven goals.

${USER_ACTION_COLOR}Press <Enter> to measure the build results.${RESTORE}
EOF
  print_wizard_text "${text}"
  wait_for_enter
}

explain_and_print_summary() {
  read_build_scan_metadata
  local text
  IFS='' read -r -d '' text <<EOF
The ‘Summary’ section below captures the configuration of the experiment and the
two build scans that were published as part of running the experiment. The build
scan of the second build is particularly interesting since this is where you can
inspect what goals were not leveraging the local build cache.

The ‘Investigation Quick Links’ section below allows quick navigation to the
most relevant views in build scans to investigate what goals were avoided due to
local build caching and what goals executed in the second build, which of those
goals had the biggest impact on build performance, and what caused those goals
to not be taken from the local build cache.

The ‘Command Line Invocation’ section below demonstrates how you can rerun the
experiment with the same configuration and in non-interactive mode.

$(print_summary)

$(print_command_to_repeat_experiment)

Once you have addressed the issues surfaced in build scans and pushed the
changes to your Git repository, you can rerun the experiment and start over the
cycle of run → measure → improve → run.
EOF
  print_wizard_text "${text}"
}

process_arguments "$@"
main
