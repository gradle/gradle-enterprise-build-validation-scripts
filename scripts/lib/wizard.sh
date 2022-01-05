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


print_wizard_text() {
  echo -n "${RESTORE}"
  echo -n "$@"
}

print_separator() {
  printf '=%.0s' {1..80}
  echo
}

print_introduction_title() {
  cat <<EOF
${HEADER_COLOR}Gradle Enterprise - Build Validation

Experiment ${EXP_NO}: ${EXP_DESCRIPTION}${RESTORE}
EOF
}

explain_prerequisites_ccud_gradle_plugin() {
  local text preparation_step

  if [ -n "$1" ]; then
    preparation_step="$1 "
  else
    preparation_step=""
  fi

  IFS='' read -r -d '' text <<EOF
$(print_separator)
${HEADER_COLOR}Preparation ${preparation_step}- Configure build with Common Custom User Data Gradle plugin${RESTORE}

To get the most out of this experiment and also when building with Gradle
Enterprise during daily development, it is advisable that you apply the Common
Custom User Data Gradle plugin to your build, if not already the case. Gradle
provides the Common Custom User Data Gradle plugin as a free, open-source add-on.

https://plugins.gradle.org/plugin/com.gradle.common-custom-user-data-gradle-plugin

An extract of a typical build configuration is described below.

settings.gradle:
plugins {
    id 'com.gradle.enterprise' version '<latest version>'
    id 'com.gradle.common-custom-user-data-gradle-plugin' version '<latest version>'
}

Your updated build configuration should be pushed before proceeding.

${USER_ACTION_COLOR}Press <Enter> once you have (optionally) configured your build with the Common Custom User Data Gradle plugin and pushed the changes.${RESTORE}
EOF
  print_wizard_text "${text}"
  wait_for_enter
}

explain_prerequisites_ccud_maven_extension() {
  local text preparation_step

  if [ -n "$1" ]; then
    preparation_step="$1 "
  else
    preparation_step=""
  fi

  IFS='' read -r -d '' text <<EOF
$(print_separator)
${HEADER_COLOR}Preparation ${preparation_step}- Configure build with Common Custom User Data Maven extension${RESTORE}

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
        <version>{latest version}</version>
    </extension>
    <extension>
        <groupId>com.gradle</groupId>
        <artifactId>common-custom-user-data-maven-extension</artifactId>
        <version>{latest version}</version>
    </extension>
</extensions>

Your updated build configuration should be pushed before proceeding.

${USER_ACTION_COLOR}Press <Enter> once you have (optionally) configured your build with the Common Custom User Data Maven extension and pushed the changes.${RESTORE}
EOF
  print_wizard_text "${text}"
  wait_for_enter
}

explain_prerequisites_gradle_remote_build_cache_config() {
  local text preparation_step

  if [ -n "$1" ]; then
    preparation_step="$1 "
  else
    preparation_step=""
  fi

  IFS='' read -r -d '' text <<EOF
$(print_separator)
${HEADER_COLOR}Preparation ${preparation_step}- Configure build for remote build caching${RESTORE}

You must first configure your build for remote build caching. An extract of a
typical build configuration is described below.

gradle.properties:
org.gradle.caching=true

settings.gradle:
def isCi = System.getenv('BUILD_URL') != null   // adjust to an env var that is always present in your CI environment
buildCache {
  local { enabled = false }                     // must be false for this experiment
  remote(HttpBuildCache) {
    url = 'https://ge.example.com/cache/exp4/'  // adjust to your GE hostname, and note the trailing slash
    allowUntrustedServer = true                 // set to false if a trusted certificate is configured for the GE server
    credentials { creds ->
      // inject credentials with read-write access to the remote build cache via env vars set in your CI environment
      creds.username = System.getenv('GRADLE_ENTERPRISE_CACHE_USERNAME')
      creds.password = System.getenv('GRADLE_ENTERPRISE_CACHE_PASSWORD')
    }
    enabled = true                              // must be true for this experiment
    push = isCI                                 // must be true when the build runs in CI
}}

Your updated build configuration needs to be pushed to a separate branch that
is only used for running the experiments.

${USER_ACTION_COLOR}Press <Enter> once you have configured your build for remote build caching and pushed the changes.${RESTORE}
EOF
  print_wizard_text "${text}"
  wait_for_enter
}

explain_prerequisites_maven_remote_build_cache_config() {
  local text preparation_step

  if [ -n "$1" ]; then
    preparation_step="$1 "
  else
    preparation_step=""
  fi

  IFS='' read -r -d '' text <<EOF
$(print_separator)
${HEADER_COLOR}Preparation ${preparation_step}- Configure build for remote build caching${RESTORE}

You must first configure your build for remote build caching. An extract of a
typical build configuration is described below.

.mvn/gradle-enterprise.xml:
<gradleEnterprise>
  <buildCache>
    <local>
      <enabled>false</enabled>                                  <!-- must be false for this experiment -->
    </local>
    <remote>
      <server>
        <url>https://ge.example.com/cache/exp3/</url>           <!-- adjust to your GE hostname, and note the trailing slash -->
        <allowUntrusted>true</allowUntrusted>                   <!-- set to false if a trusted certificate is configured for the GE server -->
        <credentials>
          <username>\${env.GRADLE_ENTERPRISE_CACHE_USERNAME}</username>
          <password>\${env.GRADLE_ENTERPRISE_CACHE_PASSWORD}</password>
        </credentials>
      </server>
      <enabled>true</enabled>                                   <!-- must be true for this experiment -->
      <storeEnabled>#{env['BUILD_URL'] != null}</storeEnabled>  <!-- must be true when the build runs in CI -->
    </remote>
  </buildCache>
</gradleEnterprise>

Your updated build configuration needs to be pushed to a separate branch that
is only used for running the experiments.

${USER_ACTION_COLOR}Press <Enter> once you have configured your build for remote build caching and pushed the changes.${RESTORE}
EOF
  print_wizard_text "${text}"
  wait_for_enter
}

explain_prerequisites_empty_remote_build_cache() {
  local text preparation_step build_tool_instructions

  if [ -n "$1" ]; then
    preparation_step="$1 "
  else
    preparation_step=""
  fi

  if [[ "${BUILD_TOOL}" == "Maven" ]]; then
    IFS='' read -r -d '' build_tool_instructions <<EOF
If you choose option b) and do not want to interfere with an already existing
build caching configuration in your build, you can override the local and
remote build cache configuration via system properties right when triggering
the build on CI. Details on how to provide the overrides are available from
the documentation of the the Gradle Enterprise Maven extension.

https://docs.gradle.com/enterprise/maven-extension/#configuring_the_remote_cache
EOF
  else
    IFS='' read -r -d '' build_tool_instructions <<EOF
If you choose option b) and do not want to interfere with an already existing
build caching configuration in your build and you are using the Common Custom
User Data Gradle plugin, you can override the local and remote build cache
configuration via system properties or environment variables right when
triggering the build on CI. Details on how to provide the overrides are
available from the documentation of the plugin.

https://github.com/gradle/gradle-enterprise-build-config-samples/blob/master/common-custom-user-data-gradle-plugin/README.md#configuration-overrides
EOF
  fi

  IFS='' read -r -d '' text <<EOF
$(print_separator)
${HEADER_COLOR}Preparation ${preparation_step}- Purge remote build cache${RESTORE}

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

${build_tool_instructions}
${USER_ACTION_COLOR}Press <Enter> once you have prepared the experiment to run with an empty remote build cache.${RESTORE}
EOF
  print_wizard_text "${text}"
  wait_for_enter
}

explain_prerequisites_api_access() {
  local text preparation_step documentation_link

  if [ -n "$1" ]; then
    preparation_step="$1 "
  else
    preparation_step=""
  fi

  if [[ "${BUILD_TOOL}" == "Maven" ]]; then
    documentation_link="https://github.com/gradle/gradle-enterprise-build-validation-scripts/blob/main/Maven.md#authenticating-with-gradle-enterprise"
  else
    documentation_link="https://github.com/gradle/gradle-enterprise-build-validation-scripts/blob/main/Gradle.md#authenticating-with-gradle-enterprise"
  fi

  IFS='' read -r -d '' text <<EOF
$(print_separator)
${HEADER_COLOR}Preparation ${preparation_step}- Ensure Gradle Enterprise API access${RESTORE}

Some build scan data will be fetched from the invoked builds via the Gradle
Enterprise API. It is not strictly necessary that you have permission to
call the Gradle Enterprise API while doing this experiment, but the summary
provided at the end of the experiment will be more comprehensive if the build
scan data is accessible. Details on how to check your access permissions and
how to provide the necessary API credentials when running the experiment are
available from the documentation of the build validation scripts.

${documentation_link}

${USER_ACTION_COLOR}Press <Enter> once you have (optionally) adjusted your access permissions and configured the API credentials on your machine.${RESTORE}
EOF
  print_wizard_text "${text}"
  wait_for_enter
}

explain_experiment_dir() {
  wizard "All of the work we do for this experiment will be stored in
$(info "${EXP_DIR}")"
}

explain_collect_git_details() {
  local text
  IFS='' read -r -d '' text <<EOF
$(print_separator)
${HEADER_COLOR}Configure experiment${RESTORE}

The experiment will run using a fresh checkout of a given project stored in
Git. The fresh checkout ensures reproducibility of the experiment across
machines and users since no local changes and commits will be accidentally
included in the validation process.

Optionally, the project can be validated and optimized on an existing
branch and only merged back to the main line once all improvements are
completed.
EOF
  print_wizard_text "${text}"
}

explain_collect_gradle_details() {
  local text
  IFS='' read -r -d '' text <<EOF
Once the project is checked out from Git, the experiment will invoke the
project’s contained Gradle build with a given set of tasks and an optional
set of arguments. The Gradle tasks to invoke should resemble what users
typically invoke when building the project.

The build will be invoked from the project’s root directory or from a given
sub-directory.

In order to become familiar with the experiment, it is advisable to
initially choose a task that does not take too long to complete, for example
the 'assemble' task.
EOF
  print_wizard_text "${text}"
}

explain_collect_maven_details() {
  local text
  IFS='' read -r -d '' text <<EOF
Once the project is checked out from Git, the experiment will invoke the
project’s contained Maven build with a given set of goals and an optional
set of arguments. The Maven goals to invoke should resemble what users
typically invoke when building the project.

The build will be invoked from the project’s root directory or from a given
sub-directory.

In order to become familiar with the experiment, it is advisable to
initially choose a goal that does not take too long to complete, for example
the 'install' goal.
EOF
  print_wizard_text "${text}"
}

explain_clone_project() {
  local text
  IFS='' read -r -d '' text <<EOF
$(print_separator)
${HEADER_COLOR}Check out project from Git${RESTORE}

All configuration to run the experiment has been collected. In the first
step of the experiment, the Git repository that contains the project to
validate will be checked out.

${USER_ACTION_COLOR}Press <Enter> to check out the project from Git.${RESTORE}
EOF
  print_wizard_text "${text}"
  wait_for_enter
}

explain_command_to_repeat_experiment() {
  local text
  IFS='' read -r -d '' text <<EOF
The 'Command Line Invocation' section below demonstrates how you can rerun the
experiment with the same configuration and in non-interactive mode.
EOF
  echo -n "${text}"
}

explain_when_to_rerun_experiment() {
  local text
  IFS='' read -r -d '' text <<EOF
Once you have addressed the issues surfaced in build scans and pushed the
changes to your Git repository, you can rerun the experiment and start over
the cycle of run → measure → improve → run.
EOF
  echo -n "${text}"
}
