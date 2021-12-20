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
./02-validate-local-build-caching-same-location.sh -i
```

Once you are familiar with a given experiment, you can run the script in _non-interactive_ mode. In the example below,
the script is run autonomously with the provided configuration options.

```bash
./02-validate-local-build-caching-same-location.sh -r https://github.com/gradle/gradle-build-scan-quickstart -t build
```

You can also combine the _interactive_ mode with some configuration options already provided at the time the script
is invoked, as shown in the example below.

```bash
./02-validate-local-build-caching-same-location.sh -i -r https://github.com/gradle/gradle-build-scan-quickstart
```

#### Authenticating with Gradle Enterprise

Some scripts fetch data from build scans that were published as part of running an experiment. The build scan data is fetched by leveraging the [Gradle Enterprise Export API](https://docs.gradle.com/enterprise/export-api/). It is not strictly necessary that you have permission to call the Export API to execute a script successfully, but the summary provided once the script has finished running its experiment will be more comprehensive if the build scan data is accessible.

You can check your granted permissions by navigating in the browser to the 'My Settings' section from the user menu of your Gradle Enterprise UI. You need the 'Access build data via the Export API' permission. Additionally, the script needs an access key to authenticate with the Gradle Enterprise Export API. See [Authenticating with Gradle Enterprise](https://docs.gradle.com/enterprise/gradle-plugin/#authenticating_with_gradle_enterprise) for details on how to create an access key and storing it locally.

By default, the scripts fetching build scan data try to find the access key in the `enterprise/keys.properties` file within the Gradle user home directory (`~/.gradle` by default). Alternatively, the access key can be specified via the `GRADLE_ENTERPRISE_ACCESS_KEY` environment variable. You can also authenticate with the Export API using username and password instead by setting the `GRADLE_ENTERPRISE_USERNAME` and `GRADLE_ENTERPRISE_PASSWORD` environment variables.

#### Configuring custom value lookup names

The scripts that fetch build scan data expect some of it to be present as custom values (Git repository, branch name, and commit id). By default, the scripts assume that these custom values have been created by the [Common Custom User Data Gradle plugin](https://plugins.gradle.org/plugin/com.gradle.common-custom-user-data-gradle-plugin). If you are not using that plugin but your build still captures the same data under different custom value names, you can provide a mapping file so that the required data can be extracted from your build scans. An example mapping file named mapping.example can be found at the same location as where the scripts are located.

#### Redirecting build scan publishing

The scripts that run one or more builds locally can be configured to publish build scans to a different
Gradle Enterprise server than the one that the builds point to by passing the `-s` or `--gradle-enterprise-server`
command line argument. In the example below, the script will configure the local builds to publish their build scans
to ge.example.io regardless of what server is configured in the build.

```bash
./02-validate-local-build-caching-same-location.sh -i -s https://ge.example.io
```

#### Instrumenting the build with Gradle Enterprise

The scripts that run one or more builds locally can be configured to connect the builds to a given Gradle Enterprise
instance in case the builds are not already connected to Gradle Enterprise by passing the `-e` or `--enable-gradle-enterprise`
command line argument. In the example below, the script will configure the non-instrumented builds to connect to the
Gradle Enterprise server at ge.example.io.

```bash
./02-validate-local-build-caching-same-location.sh -i -e -s https://ge.example.io
```

#### Analyzing the results

Once a script has finished running its experiment, a summary of what was run and what the outcome was is printed on
the console. The outcome is primarily a set of links pointing to build scans that were captured as part of running the
builds of the experiment. Some links also point to build scan comparison. The links have been carefully crafted such that
they bring you right to where it is revealed how well your build avoids unnecessary work.

The summary looks typically like in the screenshot below.

![image](https://user-images.githubusercontent.com/231070/146644509-7b071436-3d04-46ee-a327-ea16ecfe9c76.png)

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
./01-validate-local-build-caching-same-location.sh -r https://github.com/gradle/maven-build-scan-quickstart -g install
```

You can also combine the _interactive_ mode with some configuration options already provided at the time the script
is invoked, as shown in the example below.

```bash
./01-validate-local-build-caching-same-location.sh -i -r https://github.com/gradle/maven-build-scan-quickstart
```

#### Authenticating with Gradle Enterprise

Some scripts fetch data from build scans that were published as part of running an experiment. The build scan data is fetched by leveraging the [Gradle Enterprise Export API](https://docs.gradle.com/enterprise/export-api/). It is not strictly necessary that you have permission to call the Export API to execute a script successfully, but the summary provided once the script has finished running its experiment will be more comprehensive if the build scan data is accessible.

You can check your granted permissions by navigating in the browser to the 'My Settings' section from the user menu of your Gradle Enterprise UI. You need the 'Access build data via the Export API' permission. Additionally, the script needs an access key to authenticate with the Gradle Enterprise Export API. See [Authenticating with Gradle Enterprise](https://docs.gradle.com/enterprise/maven-extension/#authenticating_with_gradle_enterprise) for details on how to create an access key and storing it locally.

By default, the scripts fetching build scan data try to find the access key in the `gradle-enterprise/keys.properties` file within the Maven user home directory (~/.m2 by default). Alternatively, the access key can be specified via the `GRADLE_ENTERPRISE_ACCESS_KEY` environment variable. You can also authenticate with the Export API using username and password instead by setting the `GRADLE_ENTERPRISE_USERNAME` and `GRADLE_ENTERPRISE_PASSWORD` environment variables.

#### Configuring custom value lookup names

The scripts that fetch build scan data expect some of it to be present as custom values (Git repository, branch name, and commit id). By default, the scripts assume that these custom values have been created by the [Common Custom User Data Maven extension](https://search.maven.org/artifact/com.gradle/common-custom-user-data-maven-extension). If you are not using that extension but your build still captures the same data under different custom value names, you can provide a mapping file so that the required data can be extracted from your build scans. An example mapping file named mapping.example can be found at the same location as where the scripts are located.

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

![image](https://user-images.githubusercontent.com/231070/146644224-698f6dbe-fa1c-4632-8051-0e512226f577.png)

