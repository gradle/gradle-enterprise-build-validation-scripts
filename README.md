## Gradle Enterprise - Build Validation Scripts

Intro on what this is about.

### Gradle

#### Installation

On macOS and Linux, use the following command to download and unpack the build validation scripts
for Gradle to the current directory:

```bash
curl -s -L -O https://github.com/gradle/gradle-enterprise-build-config-samples/releases/download/build-validation-development-latest/gradle-enterprise-gradle-build-validation.zip && unzip -q -o gradle-enterprise-gradle-build-validation.zip
```

#### Structure

In the top-level folder, there are five different scripts that you can execute, each one representing
a discrete step in the build validation process:

- 01-validate-incremental-building.sh
- 02-validate-local-build-caching-same-location.sh
- 03-validate-local-build-caching-different-locations.sh
- 04-validate-remote-build-caching-ci-ci.sh
- 05-validate-remote-build-caching-ci-local.sh

<details>
  <summary>Click to see more details on the purpose of each script in the table below.</summary>

| Script | Purpose |
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

It is recommended that you run a given script in _interactive_ mode for the first time. In the example below, 
the script is executed interactively and already provides the GitHub repository where the project to validate can be found.

```bash
./01-validate-incremental-building.sh -i -r https://github.com/etiennestuder/java-ordered-properties
```

Once you are familiar with a given script, you can run it in _non-interactive_ mode. In the example below,
the script is run autonomously with all configuration passed at script invocation time.

```bash
./01-validate-incremental-building.sh -r https://github.com/etiennestuder/java-ordered-properties -b master -t build
```

#### Redirecting build scan publishing

The scripts that run one or more builds locally can be configured to publish build scans to a different
Gradle Enterprise server than the one that the builds point to by passing the `-s` or `--gradle-enterprise-server`
command line argument. In the example below, the script will configure the local builds to publish their build scans
to https://ge.example.io regardless of what server is configured in the build.

```bash
./01-validate-incremental-building.sh -i -s https://ge.example.io
```

#### Instrumenting build with Gradle Enterprise

The scripts that run one or more builds locally can be configured to connect the builds to a Gradle Enterprise
instance in case the builds are not already connected to Gradle Enterprise by passing the `-e` or `--enable-gradle-enterprise`
command line argument. In the example below, the script will configure the non-instrumented build to connect to the
Gradle Enterprise server at https://ge.example.io.

```bash
./01-validate-incremental-building.sh -i -e -s https://ge.example.io
```

### Maven

#### Installation

On macOS and Linux, use the following command to download and unpack the build validation scripts for Maven to the current directory:

```bash
curl -s -L -O https://github.com/gradle/gradle-enterprise-build-config-samples/releases/download/build-validation-development-latest/gradle-enterprise-maven-build-validation.zip && unzip -q -o gradle-enterprise-maven-build-validation.zip
```

You can then navigate into the extracted folder that contains the validation scripts:

```bash
cd gradle-enterprise-maven-build-validation
```

#### Executions

Validation steps (incl. link to videos)
Common functionality (-i, -h, -v)
Example







# Gradle Enterprise - Build Validation

A software development team can gain a lot of efficiency and productivity by optimizing their build to avoid performing
unnecessary work, or work that has been performed already. Shorter builds allow software developers to get feedback
quicker about their changes (does the code compile, do the tests pass?) and helps to reduce context switching (a known
productivity killer).

The scripts in this project can help you optimize your Gradle and Maven builds to run faster by avoiding unnecessary
work. Each script runs a controlled, reproducible experiment. The output of each experiment is a set
of [build scans](https://scans.gradle.com/get-started). You can use the build scans to investigate what tasks ran
unnecessarily, and to make informed decisions about what tasks are worth improving to make your build faster.

Some of the experiments require [Gradle Enterprise](https://gradle.com/), which provides several features useful for
reducing build times (such
as [remote build cachin and distributed test execution](https://gradle.com/gradle-enterprise-solution-overview/build-cache-test-distribution/)).

You may want to repeat the experiments on a regular basis to validate any optimizations you have made or to detect
regressions that may sneak into your builds over time.

## Validating Gradle Builds

### Running the first validation for the first time

Once you have installed the scripts, you can run the first experiment for Gradle:

```bash
cd gradle-enterprise-gradle-build-validation
./01-validate-incremental-build.sh --interactive
```

The above command will run the script in interactive mode. When run in interactive mode, the script will prompt you for
the information it needs to execute the experiment. To help you understand what the script does, and why, the script
will explain each step (when run in interactive mode). It is a good idea to use interactive mode for the first one or
two times you run an experiment, but afterwards, you can run the script normally to save time.

### Scripts for Gradle

The following scripts are available for validating Gradle builds:

- `01-validate-incremental-build.sh` - Validate how well a given project leverages Gradle’s incremental build
  functionality.

- `02-validate-build-caching-local-in-place.sh` - Validate how well a given project leverages the local build cache when
  run in-place.

- `03-validate-build-caching-local-diff-place.sh` - Validate how well a given project leverages the local build cache
  when run from different locations on the same workstation.

### Command Line Arguments

The scripts accept the following command line arguments:

```
-i, --interactive                  Enables interactive mode.
-r, --git-repo                     Specifies the URL for the Git repository to validate.
-b, --git-branch                   Specifies the branch for the Git repository to validate.
-p, --project-dir                  Specifies the build invocation directory within the Git repository.
-t, --tasks                        Declares the Gradle tasks to invoke.
-a, --args                         Declares additional arguments to pass to Gradle.
-s, --gradle-enterprise-server     Enables Gradle Enterprise on a project not already connected.
-e, --enable-gradle-enterprise     Enables Gradle Enterprise on a project that it is not already enabled on.
-h, --help                         Shows this help message.
```

## Validating Maven Builds

### Running the first validation for the first time

Once you have installed the scripts, you can run the first experiment for Maven:

```bash
cd gradle-enterprise-maven-build-validation
./01-validate-build-caching-local-in-place.sh --interactive
```

The above command will run the script in interactive mode. When run in interactive mode, the script will prompt you for
the information it needs to execute the experiment. To help you understand what the script does, and why, the script
will explain each step (when run in interactive mode). It is a good idea to use interactive mode for the first one or
two times you run an experiment, but afterwards, you can run the script normally to save time.

### Scripts for Maven

The following scripts are available for validating Maven builds:

- `01-validate-build-caching-local-in-place.sh` - Validate how well a given project leverages the local build cache when
  run in-place.

### Command Line Arguments

The scripts accept the following command line arguments:

```
-i, --interactive                  Enables interactive mode.
-r, --git-repo                     Specifies the URL for the Git repository to validate.
-b, --git-branch                   Specifies the branch for the Git repository to validate.
-p, --project-dir                  Specifies the build invocation directory within the Git repository.
-t, --tasks                        Declares the Maven goals to invoke.
-a, --args                         Sets additional arguments to pass to Maven.
-s, --gradle-enterprise-server     Enables Gradle Enterprise on a project not already connected.
-h, --help                         Shows this help message.
```

## Custom Value Mapping File

Some of the build validation scripts look up data about existing build scans.
Some of the data is extracted from custom values published with the build
scans:

   * The Git repository
   * The Git branch
   * The Git commit

All of custom values are published by the Common Custom User Data Gradle Plugin
and the Common Custom User Data Maven Extension by default. If your builds do
not use these plugins but your builds make some or all of these values
available, then you can specify a Custom Value mapping file to tell the scripts
what custom values contain the data.  Below is an example custom value mapping
file:

```
git.repository=Git repository
git.branch=Git branch
git.commitId=Git commit id
```

The following scirpts accept a custom mapping file using the
`-m/--mapping-file` command line argument:

  * Gradle 04-validate-remote-build-caching-ci-ci.sh
  * Gradle 05-validate-remote-build-caching-ci-local.sh
  * Maven 03-validate-remote-build-caching-ci-ci.sh
  * Maven 04-validate-remote-build-caching-ci-local.sh

## Authenticating with Gradle Enterprise to retrieve build scan data

Some of the build validation scripts use the
[Gradle Enterprise Export API](https://docs.gradle.com/enterprise/export-api/)
to look up data about existing build scans. In order for the the lookup to
succeed, you will need the 'Access build data via the Export API' permission.
Additionally, this scripts need an access key to authenticate with Gradle
Enterprise. By default, the scripts try to find the access key in the
`enterprise/keys.properties` file within the Gradle user home directory
(`~/.gradle` by default).

See [Authenticating with Gradle Enterprise](https://docs.gradle.com/enterprise/gradle-plugin/#authenticating_with_gradle_enterprise)
for details on how to create an access key.

Alternatively, the access key can be specified via the
`GRADLE_ENTERPRISE_ACCESS_KEY` environment variable, but this is less secure
and therefore not recommended.

You can also authenticate with the Export API using a username and password
instead bu setting the `GRADLE_ENTERPRISE_USERNAME` and
`GRADLE_ENTERPRISE_PASSWORD` environment variables.

_WARNING: When using a username and password, the scripts authenticate with
Gradle Enterprise using HTTP Basic Authentication._

If all three environment variables are present, then the access key is used.

