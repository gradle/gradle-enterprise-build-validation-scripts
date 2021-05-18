#!/usr/bin/env bash
#
# Runs Experiment 04 - Validate remote build caching - different CI agents
#
# Invoke this script with --help to get a description of the command line arguments
#
readonly EXP_NAME="Validate remote build caching - different CI agents"
readonly EXP_DESCRIPTION="Validating that a Maven build is optimized for remote build caching when invoked from different CI agents"
readonly EXP_NO="03"
readonly EXP_SCAN_TAG=exp3-maven
readonly BUILD_TOOL="Maven"
readonly SCRIPT_VERSION="<HEAD>"

# Needed to bootstrap the script
readonly SCRIPT_NAME=$(basename "$0")
readonly SCRIPT_DIR="$(cd "$(dirname "$(readlink -e "${BASH_SOURCE[0]}")")" && pwd)"
readonly LIB_DIR="${SCRIPT_DIR}/../lib"

# Include and parse the command line arguments
# shellcheck source=build-validation/scripts/lib/maven/03-cli-parser.sh
source "${LIB_DIR}/maven/${EXP_NO}-cli-parser.sh" || { echo "Couldn't find '${LIB_DIR}/maven/${EXP_NO}-cli-parser.sh' parsing library."; exit 1; }
# shellcheck source=build-validation/scripts/lib/libs.sh
# shellcheck disable=SC2154 # the libs include scripts that reference CLI arguments that this script does not create
source "${LIB_DIR}/libs.sh" || { echo "Couldn't find '${LIB_DIR}/libs.sh'"; exit 1; }

# These will be set by the config functions (see lib/config.sh)
git_repo=''
project_name=''
git_branch=''
project_dir=''
tasks=''
interactive_mode=''
mapping_file=''

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
  validate_required_args

  parse_build_scan_urls
  fetch_extended_build_scan_data
  make_experiment_dir

  print_bl
  print_summary
  print_bl
}

wizard_execute() {
  print_bl
  print_introduction

  print_bl
  explain_prerequisites

  print_bl
  explain_first_build
  print_bl
  collect_first_build_scan

  print_bl
  explain_second_build
  print_bl
  collect_second_build_scan

  print_bl
  explain_collect_mapping_file
  print_bl
  collect_mapping_file

  print_bl
  explain_fetch_build_scan_data
  print_bl
  parse_build_scan_urls
  fetch_extended_build_scan_data
  make_experiment_dir

  print_bl
  explain_measure_build_results
  print_bl
  explain_and_print_summary
  print_bl
}

validate_required_args() {
  if [ -z "${_arg_first_build}" ]; then
    _PRINT_HELP=yes die "ERROR: Missing required argument: --first-build" 1
  fi
  if [ -z "${_arg_second_build}" ]; then
    _PRINT_HELP=yes die "ERROR: Missing required argument: --second_build" 1
  fi
  build_scan_urls+=("${_arg_first_build}")
  build_scan_urls+=("${_arg_second_build}")
}

parse_build_scan_urls() {
  # From https://stackoverflow.com/a/63993578/106189
  # See also https://stackoverflow.com/a/45977232/106189
  readonly URI_REGEX='^(([^:/?#]+):)?(//((([^:/?#]+)@)?([^:/?#]+)(:([0-9]+))?))?((/|$)([^?#]*))(\?([^#]*))?(#(.*))?$'
  #                    ↑↑            ↑  ↑↑↑            ↑         ↑ ↑            ↑↑    ↑        ↑  ↑        ↑ ↑
  #                    ||            |  |||            |         | |            ||    |        |  |        | |
  #                    |2 scheme     |  ||6 userinfo   7 host    | 9 port       ||    12 rpath |  14 query | 16 fragment
  #                    1 scheme:     |  |5 userinfo@             8 :...         ||             13 ?...     15 #...
  #                                  |  4 authority                             |11 / or end-of-string
  #                                  3  //...                                   10 path

  local protocol ge_host port build_scan_id

  for url in "${build_scan_urls[@]}"; do
    if [[ "${url}" =~ $URI_REGEX ]]; then
      protocol="${BASH_REMATCH[2]}"
      ge_host="${BASH_REMATCH[7]}"
      port="${BASH_REMATCH[8]}"
      build_scan_id="$(basename "${BASH_REMATCH[10]}")"

      base_urls+=("${protocol}://${ge_host}${port}")
      build_scan_ids+=("$build_scan_id")
    else
      die "${url} is not a parsable URL." 4
    fi
  done
}

fetch_extended_build_scan_data() {
  fetch_and_read_build_validation_data "${build_scan_urls[@]}"
}

print_summary() {
 print_experiment_info
 print_build_scans
 print_warning_if_values_different
 print_warnings_for_failed_builds
 print_bl
 print_quick_links
}

# Overrides the info.sh#print_experiment_info
print_experiment_info() {
 info "Summary"
 info "-------"
 comparison_summary_row "Project:" "${project_names[@]}"
 comparison_summary_row "Git repo:" "${git_repos[@]}"
 comparison_summary_row "Git branch:" "${git_branches[@]}"
 comparison_summary_row "Git commit id:" "${git_commit_ids[@]}"
 summary_row "Project dir:" ""
 comparison_summary_row "Maven goals:" "${requested_tasks[@]}"
 summary_row "Maven arguments:" ""
 summary_row "Experiment:" "${EXP_NO} ${EXP_NAME}"
 summary_row "Experiment id:" "${EXP_SCAN_TAG}"
 summary_row "Experiment run id:" "<not applicable>"
 summary_row "Experiment artifact dir:" "<not applicable>"
 summary_row "Custom value mapping file:" "${mapping_file:-<none>}"
}

comparison_summary_row() {
    local header value
    header="$1"
    shift;

  if [[ "$1" == "$2" ]]; then
    value="$1"
  else
    value_mismatch_detected=true
    value="${ORANGE}${1} | ${2}${RESTORE}"
  fi

  summary_row "${header}" "${value}"
}

print_build_scans() {
 if [[ "${build_outcomes[0]}" == "FAILED" ]]; then
   summary_row "Build scan first build:" "${WARNING_COLOR}${build_scan_urls[0]} FAILED${RESTORE}"
 else
   summary_row "Build scan first build:" "${build_scan_urls[0]}"
 fi
 if [[ "${build_outcomes[2]}" == "FAILED" ]]; then
   summary_row "Build scan second build:" "${WARNING_COLOR}${build_scan_urls[1]} FAILED${RESTORE}"
 else
   summary_row "Build scan second build:" "${build_scan_urls[1]}"
 fi
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

print_warning_if_values_different() {
  if [[ "${value_mismatch_detected}" == "true" ]]; then
    print_bl
    warn "Differences were detected between the two builds that may skew the outcome of the experiment."
  fi
}

print_warnings_for_failed_builds() {
  if [[ "${build_outcomes[0]}" == "FAILED" ]]; then
    print_bl
    warn "The first build failed and may skew the outcome of the experiment."
  fi
  if [[ "${build_outcomes[1]}" == "FAILED" ]]; then
    print_bl
    warn "The second build failed and may skew the outcome of the experiment."
  fi
}

print_introduction() {
  local text
  IFS='' read -r -d '' text <<EOF
$(print_introduction_title)

In this experiment, you will validate how well a given project leverages
Gradle Enterprise's remote caching functionality in your CI environment to avoid doing
unnecessary work that has already been done on a CI server.

A build is considered fully remote cache enabled if all tasks avoid performing
any work because:

  * The goals' inputs have not changed since their last invocation and
  * The goals' outputs are present in the remote cache

The goal of the experiment is to first identify those goals that do not reuse
outputs from the remote cache, to then make an informed decision which of those
goals are worth improving to make your build faster, to then investigate why
they did not reuse outputs, and to finally fix them once you understand the root
cause.

This experiment consists of the following steps:

	1. On a CI server, run the Maven build with a typical goal invocation
	2. On a CI server, run the Maven build against the same commit with the same goal invocation
	3. Determine which goals are still executed in the second run and why
	4. Assess which of the executed goals are worth improving

Unlike other scripts, the script you have invoked does not automate the
execution of step 1 and step 2. You will need to complete step 1 and 2. This
script will provide a list of quick links to support your investigation in step
3 and step 4.

After improving the build to make it more incremental, you can run the
experiment again. This creates a cycle of run → measure → improve → run → …

${USER_ACTION_COLOR}Press <Enter> to get started with the experiment.${RESTORE}
EOF

  print_wizard_text "${text}"
  wait_for_enter
}

explain_prerequisites() {
  local text
  IFS='' read -r -d '' text <<EOF
$(print_separator)
${HEADER_COLOR}Purge remote build cache and disable the local build cache${RESTORE}

Before you can run the first build, you should purge the remote cache on your
Gradle Enterprise server to ensure any existing cache entries do not influence
the experiment.

Alternatively, run the first Maven build with -DrerunGoals command line
argument. This will ensure that the first build does not use any existing build
cache entries.

For this experiment, you also need to disable the local build cache so that only
the remote build cache is used.

${USER_ACTION_COLOR}Press <Enter> when you have purged the remote cache and disabled the local cache.${RESTORE}
EOF
  print_wizard_text "${text}"
  wait_for_enter
}

explain_first_build() {
  local text
  IFS='' read -r -d '' text <<EOF
$(print_separator)
${HEADER_COLOR}Run first build on CI${RESTORE}

It is now time to run the first build on the CI server. The Maven goals to
invoked by the build should resemble what CI typically invokes when building the
project.

Once the build completes, make a note of the commit the build ran against, and
enter the URL to the build scan produced by the build.
EOF
  print_wizard_text "${text}"
}

collect_first_build_scan() {
  prompt_for_setting "What is the build scan for the first CI server build?" "${_arg_first_build}" "" build_scan_url
  build_scan_urls+=("${build_scan_url}")
}

explain_second_build() {
  local text
  IFS='' read -r -d '' text <<EOF
$(print_separator)
${HEADER_COLOR}Run second build on CI${RESTORE}

Now that the first build has finished successfully, the second build can be run
on CI against the same commit and with the same Maven goals. Make sure to NOT
run the second build with -DrerunGoals. Otherwise, the second build will not
use the remote cache entries populated by the first build.

Once the build completes, enter the URL to the build scan produced by the build.
EOF
  print_wizard_text "${text}"
}

collect_second_build_scan() {
  prompt_for_setting "What is the build scan for the second CI server build?" "${_arg_second_build}" "" build_scan_url
  build_scan_urls+=("${build_scan_url}")
}

explain_collect_mapping_file() {
  local text
  IFS='' read -r -d '' text <<EOF
$(print_separator)
${HEADER_COLOR}Fetch build scan data${RESTORE}

This script is going to fetch the build scans you have provided and extract some
information from the build scans to assist you in your investigation.

Some of the data is stored as custom values on the build scan. By default, this
script assumes the values have been created by the Common Custom User Data
Maven extension. If you are not using the plugin but the builds still publish the
same data using different names, then you can provide a mapping file so that the
script can still find the data.
EOF
  print_wizard_text "${text}"
}

explain_fetch_build_scan_data() {
  local text
  IFS='' read -r -d '' text <<EOF
${USER_ACTION_COLOR}Press <Enter> to fetch the build scans.${RESTORE}
EOF
  print_wizard_text "${text}"
  wait_for_enter
}


explain_measure_build_results() {
  local text
  IFS='' read -r -d '' text <<EOF
$(print_separator)
${HEADER_COLOR}Measure build results${RESTORE}

At this point, you are ready to measure in Gradle Enterprise how well your build
leverages the remote build cache for the invoked set of Maven goals.

${USER_ACTION_COLOR}Press <Enter> to measure the build results.${RESTORE}
EOF
  print_wizard_text "${text}"
  wait_for_enter
}

print_command_to_repeat_experiment() {
  local cmd
  cmd=("./${SCRIPT_NAME}")
  cmd+=("--first-build" "${build_scan_urls[0]}")
  cmd+=("--second-build" "${build_scan_urls[1]}")

  if [ -n "${mapping_file}" ]; then
    cmd+=("-m" "${mapping_file}")
  fi

  info "Command Line Invocation"
  info "-----------------------"
  info "$(printf '%q ' "${cmd[@]}")"
}
explain_and_print_summary() {
  local text
  IFS='' read -r -d '' text <<EOF
The 'Summary' section below captures the configuration of the experiment and the
two build scans that were published as part of running the experiment.  The
build scan of the second build is particularly interesting since this is where
you can inspect what goals were not leveraging the remote build cache.

The 'Investigation Quick Links' section below allows quick navigation to the
most relevant views in build scans to investigate what goal outputs were fetched
from the remote cache and what goals executed in the second build with cache
misses, which of those goals had the biggest impact on build performance, and
what caused the cache misses.

The 'Command Line Invocation' section below demonstrates how you can rerun the
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

