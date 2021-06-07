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
readonly SHOW_RUN_ID=false

# Needed to bootstrap the script
SCRIPT_NAME=$(basename "$0")
readonly SCRIPT_NAME
SCRIPT_DIR="$(cd "$(dirname "$(readlink -e "${BASH_SOURCE[0]}")")" && pwd)"
readonly SCRIPT_DIR
readonly LIB_DIR="${SCRIPT_DIR}/../lib"

# Include and parse the command line arguments
# shellcheck source=lib/maven/03-cli-parser.sh
source "${LIB_DIR}/maven/${EXP_NO}-cli-parser.sh" || { echo "Couldn't find '${LIB_DIR}/maven/${EXP_NO}-cli-parser.sh' parsing library."; exit 1; }
# shellcheck source=lib/libs.sh
# shellcheck disable=SC2154 # the libs include scripts that reference CLI arguments that this script does not create
source "${LIB_DIR}/libs.sh" || { echo "Couldn't find '${LIB_DIR}/libs.sh'"; exit 1; }

# These will be set by the config functions (see lib/config.sh)
git_repo=''
project_name=''
git_branch=''
project_dir='<not available>'
tasks=''
extra_args='<not available>'
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
  if [ -z "${_arg_first_ci_build}" ]; then
    _PRINT_HELP=yes die "ERROR: Missing required argument: --first-ci-build" 1
  fi
  if [ -z "${_arg_second_ci_build}" ]; then
    _PRINT_HELP=yes die "ERROR: Missing required argument: --second-ci-build" 1
  fi
  build_scan_urls+=("${_arg_first_ci_build}")
  build_scan_urls+=("${_arg_second_ci_build}")
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

# Overrides info.sh#print_experiment_specific_info
print_experiment_specific_info() {
  summary_row "Custom value mapping file:" "${mapping_file:-<none>}"
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
Gradle Enterprise's remote build caching functionality when running the build from
different CI agents. A build is considered fully cacheable if it can be invoked
twice in a row with build caching enabled and all cacheable goals avoid
performing any work because:

  * No cacheable goals were excluded from build caching to ensure correctness and
  * The goals' inputs have not changed since their last invocation and
  * The goals' outputs are present in the remote build cache

The experiment will reveal goals with volatile inputs, for example goals that
contain a timestamp in one of their inputs. It will also reveal goals that
produce non-deterministic outputs consumed by cacheable goals downstream, for
example goals generating code with non-deterministic method ordering or goals
producing artifacts that include timestamps.

The experiment will assist you to first identify those goals whose outputs are
not taken from the remote build cache due to changed inputs or to ensure
correctness of the build, to then make an informed decision which of those goals
are worth improving to make your build faster, to then investigate why they are
not taken from the remote build cache, and to finally fix them once you
understand the root cause.

The experiment needs to be run in your CI environment. It logically consists of
the following steps:

  1. Enable remote build caching and use an empty remote build cache node
  2. On a given CI agent, run a typical CI configuration from a fresh checkout
  3. On another CI agent, run the same CI configuration with the same commit id from a fresh checkout
  4. Determine which cacheable goals are still executed in the second run and why
  5. Assess which of the executed goals are worth improving
  6. Fix identified goals

The script you have invoked does not automate the execution of step 1, step 2,
and step 3. You will need to complete these steps manually. Build scans support
your investigation in step 4 and step 5.

After improving the build to make it better leverage the remote build cache, you
can push your changes and run the experiment again. This creates a cycle of run
→ measure → improve → run.

${USER_ACTION_COLOR}Press <Enter> to get started with the experiment.${RESTORE}
EOF

  print_wizard_text "${text}"
  wait_for_enter
}

explain_prerequisites() {
  local text
  IFS='' read -r -d '' text <<EOF
$(print_separator)
${HEADER_COLOR}Purge remote build cache node and configure build caching${RESTORE}

Right before running the first build, you need to purge the remote build cache
node that your build is configured to connect to. This will minimize the risk
that any build cache entries from other builds influence the experiment.

Alternatively, if you do not want to affect the build caching benefits for all
your ongoing CI builds by purging the connected remote build cache node, you can
set up an extra, empty build cache node that is used exclusively for this
experiment, and configure your build to connect to it.

In addition, configure your build with remote build caching enabled and local
build caching disabled.

The build configuration changes mentioned above are best made on a dedicated
branch in order to not impact your CI pipeline and your team's daily
development.

${USER_ACTION_COLOR}Press <Enter> once you have purged the remote build cache node, enabled remote build caching, and disabled local build caching.${RESTORE}
EOF
  print_wizard_text "${text}"
  wait_for_enter
}

explain_first_build() {
  local text
  IFS='' read -r -d '' text <<EOF
$(print_separator)
${HEADER_COLOR}Run first build on CI agent${RESTORE}

You can now trigger the first build on one of your CI agents. The invoked CI
configuration should be a configuration that is typically triggered when
building the project as part of your pipeline during daily development.

Make sure the CI configuration performs a fresh checkout to avoid any build
artifacts lingering around from a previous build that could influence the
experiment.

Once the build completes, make a note of the commit id the build ran against,
and enter the URL of the build scan produced by the build.
EOF
  print_wizard_text "${text}"
}

collect_first_build_scan() {
  prompt_for_setting "What is the build scan for the first CI server build?" "${_arg_first_ci_build}" "" build_scan_url
  build_scan_urls+=("${build_scan_url}")
}

explain_second_build() {
  local text
  IFS='' read -r -d '' text <<EOF
$(print_separator)
${HEADER_COLOR}Run second build on another CI agent${RESTORE}

Now that the first build has finished successfully, the second build can be
triggered on another CI agent for the same CI configuration and with the same
commit id the first build ran against.

Make sure the CI configuration performs a fresh checkout to avoid any build
artifacts lingering around from a previous build that could influence the
experiment.

Once the build completes, enter the URL of the build scan produced by the build.
EOF
  print_wizard_text "${text}"
}

collect_second_build_scan() {
  prompt_for_setting "What is the build scan for the second CI server build?" "${_arg_second_ci_build}" "" build_scan_url
  build_scan_urls+=("${build_scan_url}")
}

explain_collect_mapping_file() {
  local text
  IFS='' read -r -d '' text <<EOF
$(print_separator)
${HEADER_COLOR}Fetch build scan data${RESTORE}

Now that the second build has finished successfully, some of the build scan data
will be fetched from the two provided build scans to assist you in your
investigation.

Some of the fetched build scan data is expected to be present as custom values.
By default, the script assumes that these custom values have been created by the
Common Custom User Data Maven extension that Gradle provides as a free,
open-source add-on.

https://github.com/gradle/gradle-enterprise-build-config-samples/tree/master/common-custom-user-data-maven-extension

If you are not using that extension but your build still captures the same data
under different custom value names, you can provide a mapping file so that the
script can still extract that data from your build scans. An example mapping
file named 'mapping.example' can be found at the same location as the script.
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

