## Build Validation Scripts

### Overview

The purpose of the _Build Validation Scripts_ is to assist you in validating that your build is in an optimal state in terms of maximizing work avoidance. The validation scripts do not actually modify your build, but they surface what can be improved in your build to avoid unnecessary work in several scenarios.

Each script represents a so-called _experiment_. Each experiment has a very specific focus of what it validates in your build. The experiments are organized in a logical sequence that should be followed diligently to achieve incremental build improvements in an efficient manner. The experiments can be run on a fully unoptimized build, and they can also be run on a build that had already been optimized in the past in order to surface potential regressions.

There are currently five experiments for Gradle and four experiments for Maven. You could also perform these experiments fully manually, but relying on the automation of the validation scripts will be less error-prone, reproducible, and faster.

> Gradle Enterprise and its Build Scan:tm: service are instrumental to running these validation scripts. You can learn more about Gradle Enterprise at https://gradle.com.

### Gradle

#### Installation

On macOS and Linux, use the following command to download and unpack the build validation scripts
for Gradle to the current directory:

```bash
curl -s -L -O https://github.com/gradle/gradle-enterprise-build-config-samples/releases/download/build-validation-development-latest/gradle-enterprise-gradle-build-validation.zip && unzip -q -o gradle-enterprise-gradle-build-validation.zip
```

#### Structure

In the top-level folder, there are five different scripts that you can execute, each one representing
a specific experiment of the build validation process:

- 01-validate-incremental-building.sh
- 02-validate-local-build-caching-same-location.sh
- 03-validate-local-build-caching-different-locations.sh
- 04-validate-remote-build-caching-ci-ci.sh
- 05-validate-remote-build-caching-ci-local.sh

<details>
  <summary>Click to see more details about the experiment that each script represents.</summary>

| Script | Experiment |
| :----- | :------ |
| 01-validate-incremental-building.sh | Validates that a Gradle build is optimized for incremental building, implicitly invoked from the same location. |
| 02-validate-local-build-caching-same-location.sh | Validates that a Gradle build is optimized for local build caching when invoked from the same location. |
| 03-validate-local-build-caching-different-locations.sh | Validates that a Gradle build is optimized for local build caching when invoked from different locations. |
| 04-validate-remote-build-caching-ci-ci.sh | Validates that a Gradle build is optimized for remote build caching when invoked from different CI agents. |
| 05-validate-remote-build-caching-ci-local.sh | Validates that a Gradle build is optimized for remote build caching when invoked on CI agent and local machine. |
</details>

All intermediate and final output produced while running a given script is stored under ./.data/<script_name>/&lt;timestamp>-<run_id>.

#### Invocation

The scripts accept command line arguments of which some are the same for all scripts and some are
specific to a given script. The following arguments are present on all scripts:

- `-h`, `--help`: Shows a help message including all command line arguments supported by the script
- `-v`, `--version`: Shows the version number of the script
- `-i`, `--interactive`: Runs the script in interactive mode, providing extra context and guidance along the way

It is recommended that you run a given script in _interactive_ mode for the first time to make yourself familiar
with the flow of that experiment. In the example below, the script is executed interactively.

```bash
./01-validate-incremental-building.sh -i
```

Once you are familiar with a given experiment, you can run the script in _non-interactive_ mode. In the example below,
the script is run autonomously with the provided configuration options.

```bash
./01-validate-incremental-building.sh -r https://github.com/gradle/gradle-build-scan-quickstart -b master -t build
```

You can also combine the _interactive_ mode with some configuration options already provided at the time the script
is invoked, as shown in the example below.

```bash
./01-validate-incremental-building.sh -i -r https://github.com/gradle/gradle-build-scan-quickstart
```

#### Redirecting build scan publishing

The scripts that run one or more builds locally can be configured to publish build scans to a different
Gradle Enterprise server than the one that the builds point to by passing the `-s` or `--gradle-enterprise-server`
command line argument. In the example below, the script will configure the local builds to publish their build scans
to ge.example.io regardless of what server is configured in the build.

```bash
./01-validate-incremental-building.sh -i -s https://ge.example.io
```

#### Instrumenting the build with Gradle Enterprise

The scripts that run one or more builds locally can be configured to connect the builds to a given Gradle Enterprise
instance in case the builds are not already connected to Gradle Enterprise by passing the `-e` or `--enable-gradle-enterprise`
command line argument. In the example below, the script will configure the non-instrumented builds to connect to the
Gradle Enterprise server at ge.example.io.

```bash
./01-validate-incremental-building.sh -i -e -s https://ge.example.io
```

#### Analyzing the results

Once a script has finished running its experiment, a summary of what was run and what the outcome was is printed on
the console. The outcome is primarily a set of links pointing to build scans that were captured as part of running the
builds of the experiment. Some links also point to build scan comparison. The links have been carefully crafted such that
they bring you right to where it is revealed how well your build avoids unnecessary work.

The summary looks typically like in the screenshot below.

![image](https://user-images.githubusercontent.com/231070/146643607-78c39ad1-d30a-4dfc-b20d-5761d6dc0d0c.png)

### Maven

#### Installation

On macOS and Linux, use the following command to download and unpack the build validation scripts
for Maven to the current directory:

```bash
curl -s -L -O https://github.com/gradle/gradle-enterprise-build-config-samples/releases/download/build-validation-development-latest/gradle-enterprise-maven-build-validation.zip && unzip -q -o gradle-enterprise-maven-build-validation.zip
```

#### Structure

In the top-level folder, there are four different scripts that you can execute, each one representing
a specific experiment of the build validation process:

- 01-validate-local-build-caching-same-location.sh
- 02-validate-local-build-caching-different-locations.sh
- 03-validate-remote-build-caching-ci-ci.sh
- 04-validate-remote-build-caching-ci-local.sh

<details>
  <summary>Click to see more details about the experiment that each script represents.</summary>

| Script                                                 | Experiment                                                                                                      |
|:-------------------------------------------------------|:----------------------------------------------------------------------------------------------------------------|
| 01-validate-local-build-caching-same-location.sh       | Validates that a Maven build is optimized for local build caching when invoked from the same location.          |
| 02-validate-local-build-caching-different-locations.sh | Validates that a Maven build is optimized for local build caching when invoked from different locations.       |
| 03-validate-remote-build-caching-ci-ci.sh              | Validates that a Maven build is optimized for remote build caching when invoked from different CI agents.      |
| 04-validate-remote-build-caching-ci-local.sh           | Validates that a Maven build is optimized for remote build caching when invoked on CI agent and local machine. |
</details>

All intermediate and final output produced while running a given script is stored under ./.data/<script_name>/&lt;timestamp>-<run_id>.

#### Invocation

The scripts accept command line arguments of which some are the same for all scripts and some are
specific to a given script. The following arguments are present on all scripts:

- `-h`, `--help`: Shows a help message including all command line arguments supported by the script
- `-v`, `--version`: Shows the version number of the script
- `-i`, `--interactive`: Runs the script in interactive mode, providing extra context and guidance along the way

It is recommended that you run a given script in _interactive_ mode for the first time to make yourself familiar
with the flow of that experiment. In the example below, the script is executed interactively.

```bash
./01-validate-local-build-caching-same-location.sh -i
```

Once you are familiar with a given experiment, you can run the script in _non-interactive_ mode. In the example below,
the script is run autonomously with the provided configuration options.

```bash
./01-validate-local-build-caching-same-location.sh -r https://github.com/gradle/maven-build-scan-quickstart -b master -g install
```

You can also combine the _interactive_ mode with some configuration options already provided at the time the script
is invoked, as shown in the example below.

```bash
./01-validate-local-build-caching-same-location.sh -i -r https://github.com/gradle/maven-build-scan-quickstart
```

#### Redirecting build scan publishing

The scripts that run one or more builds locally can be configured to publish build scans to a different
Gradle Enterprise server than the one that the builds point to by passing the `-s` or `--gradle-enterprise-server`
command line argument. In the example below, the script will configure the local builds to publish their build scans
to ge.example.io regardless of what server is configured in the build.

```bash
./01-validate-local-build-caching-same-location.sh -i -s https://ge.example.io
```

#### Instrumenting the build with Gradle Enterprise

The scripts that run one or more builds locally can be configured to connect the builds to a given Gradle Enterprise
instance in case the builds are not already connected to Gradle Enterprise by passing the `-e` or `--enable-gradle-enterprise`
command line argument. In the example below, the script will configure the non-instrumented builds to connect to the
Gradle Enterprise server at ge.example.io.

```bash
./01-validate-local-build-caching-same-location.sh -i -e -s https://ge.example.io
```

#### Analyzing the results

Once a script has finished running its experiment, a summary of what was run and what the outcome was is printed on
the console. The outcome is primarily a set of links pointing to build scans that were captured as part of running the
builds of the experiment. Some links also point to build scan comparison. The links have been carefully crafted such that
they bring you right to where it is revealed how well your build avoids unnecessary work.

The summary looks typically like in the screenshot below.

![image](https://user-images.githubusercontent.com/231070/146584894-cd51becc-7052-4067-aefa-7aff4c61d728.png)

