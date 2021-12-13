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
# shellcheck source=lib/03-cli-parser.sh
source "${LIB_DIR}/${EXP_NO}-cli-parser.sh" || { echo "Couldn't find '${LIB_DIR}/${EXP_NO}-cli-parser.sh' parsing library."; exit 1; }
# shellcheck source=lib/libs.sh
# shellcheck disable=SC2154 # the libs include scripts that reference CLI arguments that this script does not create
source "${LIB_DIR}/libs.sh" || { echo "Couldn't find '${LIB_DIR}/libs.sh'"; exit 1; }

# These will be set by the config functions (see lib/config.sh)
git_repo=''
project_name=''
git_branch=''
project_dir='<not available>'
extra_args='<not available>'
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
  fetch_build_scan_data
  make_experiment_dir

  print_bl
  print_summary
  print_bl
}

wizard_execute() {
  print_bl
  print_introduction

  print_bl
  explain_prerequisites_ccud_maven_plugin

  print_bl
  explain_prerequisites_remote_build_cache_config

  print_bl
  explain_prerequisites_empty_remote_build_cache

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
  parse_build_scan_urls
  fetch_build_scan_data
  make_experiment_dir

  print_bl
  explain_measure_build_results
  print_bl
  explain_and_print_summary
  print_bl
}

validate_required_args() {
  if [ -z "${_arg_first_build_ci}" ]; then
    _PRINT_HELP=yes die "ERROR: Missing required argument: --first-build-ci" 1
  fi
  if [ -z "${_arg_second_build_ci}" ]; then
    _PRINT_HELP=yes die "ERROR: Missing required argument: --second-build-ci" 1
  fi
  build_scan_urls+=("${_arg_first_build_ci}")
  build_scan_urls+=("${_arg_second_build_ci}")
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

fetch_build_scan_data() {
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
twice in a row with build caching enabled and, during the second invocation, all
cacheable goals avoid performing any work because:

  * The goals' inputs have not changed since their last invocation and
  * The goals' outputs are present in the remote build cache and
  * No cacheable goals were excluded from build caching to ensure correctness

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

  1. Enable only remote build caching and use an empty remote build cache
  2. On a given CI agent, run a typical CI configuration from a fresh checkout
  3. On another CI agent, run the same CI configuration with the same commit id from a fresh checkout
  4. Determine which cacheable goals are still executed in the second run and why
  5. Assess which of the executed, cacheable goals are worth improving
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

explain_prerequisites_ccud_maven_plugin() {
  local text
  IFS='' read -r -d '' text <<EOF
$(print_separator)
${HEADER_COLOR}Preparation I. - Configure build with Common Custom User Data Maven extension${RESTORE}

To get the most out of this experiment and also when building with Gradle
Enterprise during daily development, it is advisable that you apply the Common
Custom User Data Maven extension to your build, if not already the case. Gradle
provides the Common Custom User Data Maven extension as a free, open-source add-on.

https://github.com/gradle/gradle-enterprise-build-config-samples/tree/master/common-custom-user-data-maven-extension

An extract of a typical build configuration is described below.

.mvn/extensions.xml:
<?xml version="1.0" encoding="UTF-8"?>
<extensions>
    <extension>
        <groupId>com.gradle</groupId>
        <artifactId>gradle-enterprise-maven-extension</artifactId>
        <version>1.11.1</version>
    </extension>
    <extension>
        <groupId>com.gradle</groupId>
        <artifactId>common-custom-user-data-maven-extension</artifactId>
        <version>1.9</version>
    </extension>
</extensions>

Your updated build configuration should be pushed before proceeding.

${USER_ACTION_COLOR}Press <Enter> once you have (optionally) configured your build with the Common Custom User Data Maven extension and pushed the changes.${RESTORE}
EOF
  print_wizard_text "${text}"
  wait_for_enter
}

explain_prerequisites_remote_build_cache_config() {
  local text
  IFS='' read -r -d '' text <<EOF
$(print_separator)
${HEADER_COLOR}Preparation II. - Configure build for remote build caching${RESTORE}

You must first configure your build for remote build caching. An extract of a
typical build configuration is described below.

.mvn/gradle-enterprise.xml:
<gradleEnterprise>
  <buildCache>
    <local>
      <enabled>false</enabled>                         <!-- must be false for this experiment -->
    </local>
    <remote>
      <server>
        <url>https://ge.example.com/cache/exp3/</url>  <!-- adjust to your GE hostname, and note the trailing slash -->
        <allowUntrusted>true</allowUntrusted>          <!-- set to false if a trusted certificate is configured for the GE server -->
        <credentials>
          <username>\${env.GRADLE_ENTERPRISE_CACHE_USERNAME}</username>
          <password>\${env.GRADLE_ENTERPRISE_CACHE_PASSWORD}</password>
        </credentials>
      </server>
      <enabled>true</enabled>                          <!-- must be true for this experiment -->
    </remote>
  </buildCache>
</gradleEnterprise>

On CI, you will also need to pass -Dgradle.cache.remote.storeEnabled=true to the Maven invocation
so that the CI build populates the remote build cache.

Your updated build configuration needs to be pushed to a separate branch that
is only used for running the experiments.

${USER_ACTION_COLOR}Press <Enter> once you have configured your build for remote build caching and pushed the changes.${RESTORE}
EOF
  print_wizard_text "${text}"
  wait_for_enter
}

explain_prerequisites_empty_remote_build_cache() {
  local text
  IFS='' read -r -d '' text <<EOF
$(print_separator)
${HEADER_COLOR}Preparation III. - Purge remote build cache${RESTORE}

It is important to use an empty remote build cache and to avoid that other
builds write to the same remote build cache while this experiment is running.
Ensuring that these preconditions are met will maximize the reproducibility
and reliability of the experiment. Two different ways to meet these conditions
are described below.

a) If none of your builds are yet writing to the remote build cache besides
the builds of this experiment, purge the remote build cache that your build
is configured to connect to. You can purge the remote build cache by navigating
in the browser to the 'Build Cache' admin section from the user menu of your
Gradle Enterprise UI, selecting the build cache node the build is pointing to,
and then clicking the 'Purge cache' button.

b) If you are not in a position to purge the remote build cache, you can connect
to a unique shard of the remote build cache each time you run this experiment.
A shard is accessed via an identifier that is appended to the path of the remote
build cache URL, for example https://ge.example.com/cache/exp4-2021-Dec31-take1/
which encodes the experiment type, the current date, and a counter that needs
to be increased every time the experiment is rerun. Using such an encoding
schema ensures that for each run of the experiment an empty remote build cache
will be used. You need to push the changes to the path of the remote build cache
URL every time before you run the experiment.

If you choose option b) and do not want to interfere with an already existing
build caching configuration in your build and you are using the Common Custom
User Data Maven extension, you can override the local and remote build cache
configuration via system properties or environment variables right when
triggering the build on CI. Details on how to provide the overrides are
available from the documentation of the extension.

https://docs.gradle.com/enterprise/maven-extension/#configuring_the_remote_cache

${USER_ACTION_COLOR}Press <Enter> once you have prepared the experiment to run with an empty remote build cache.${RESTORE}
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

Make sure the CI configuration uses the proper branch and performs a fresh
checkout to avoid any build artifacts lingering around from a previous build
that could influence the experiment.

Once the build completes, make a note of the commit id that was used, and enter
the URL of the build scan produced by the build.
EOF
  print_wizard_text "${text}"
}

collect_first_build_scan() {
  prompt_for_setting "What is the build scan URL of the first build?" "${_arg_first_build_ci}" "" build_scan_url
  build_scan_urls+=("${build_scan_url}")
}

explain_second_build() {
  local text
  IFS='' read -r -d '' text <<EOF
$(print_separator)
${HEADER_COLOR}Run second build on another CI agent${RESTORE}

Now that the first build has finished successfully, the second build can be
triggered on another CI agent for the same CI configuration and with the same
commit id as was used by the first build.

Make sure the CI configuration uses the proper branch and commit id and performs
a fresh checkout to avoid any build artifacts lingering around from a previous
build that could influence the experiment.

Once the build completes, enter the URL of the build scan produced by the build.
EOF
  print_wizard_text "${text}"
}

collect_second_build_scan() {
  prompt_for_setting "What is the build scan URL of the second build?" "${_arg_second_build_ci}" "" build_scan_url
  build_scan_urls+=("${build_scan_url}")
}

explain_collect_mapping_file() {
  local text
  IFS='' read -r -d '' text <<EOF
$(print_separator)
${HEADER_COLOR}Fetch build scan data${RESTORE}

Now that the second build has finished successfully, some of the build scan
data will be fetched from the two provided build scans to assist you in your
investigation.

The build scan data will be fetched via the Gradle Enterprise Export API. It is
not strictly necessary that you have permission to call the Export API while
doing this experiment, but the summary provided at the end of the experiment
will be more comprehensive if the build scan data is accessible. You can check
your granted permissions by navigating in the browser to the 'My Settings'
section from the user menu of your Gradle Enterprise UI. Your Gradle Enterprise
access key must be specified in the ~/.m2/.gradle-enterprise/keys.properties file.

https://docs.gradle.com/enterprise/gradle-plugin/#via_file

Some of the fetched build scan data is expected to be present as custom values.
By default, this experiment assumes that these custom values have been created
by the Common Custom User Data Maven extension. If you are not using that extension
but your build still captures the same data under different custom value names,
you can provide a mapping file so that the required data can be extracted from
your build scans. An example mapping file named 'mapping.example' can be found
at the same location as the script.
EOF
  print_wizard_text "${text}"
}

explain_measure_build_results() {
  local text
  IFS='' read -r -d '' text <<EOF
$(print_separator)
${HEADER_COLOR}Measure build results${RESTORE}

At this point, you are ready to measure in Gradle Enterprise how well your
build leverages Gradle’s remote build cache for the set of Gradle tasks invoked
from two different CI agents.

${USER_ACTION_COLOR}Press <Enter> to measure the build results.${RESTORE}
EOF
  print_wizard_text "${text}"
  wait_for_enter
}

#Overrides config.sh#print_command_to_repeat_experiment
print_command_to_repeat_experiment() {
  local cmd
  cmd=("./${SCRIPT_NAME}")
  cmd+=("-1" "${build_scan_urls[0]}")
  cmd+=("-2" "${build_scan_urls[1]}")

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
two build scans that were published as part of running the experiment. The build
scan of the second build is particularly interesting since this is where you can
inspect what goals were not leveraging the remote build cache.

The ‘Investigation Quick Links’ section below allows quick navigation to the
most relevant views in build scans to investigate what goals were avoided due to
remote build caching and what goals executed in the second build, which of those
goals had the biggest impact on build performance, and what caused those goals
to not be taken from the remote build cache.

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

