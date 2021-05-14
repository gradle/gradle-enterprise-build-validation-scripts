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

### Installing on Linux and MacOS

Use the following command to download and unpack the validation scripts for Gradle:

```bash
curl -s -L -O https://github.com/gradle/gradle-enterprise-build-config-samples/releases/download/build-validation-development-latest/gradle-enterprise-gradle-build-validation.zip && unzip -q -o gradle-enterprise-gradle-build-validation.zip
```

The command will download and unpack the scripts to the current directory.

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

### Installing on Linux and MacOS

Use the following command to download and unpack the validation scripts for Maven:

```bash
curl -s -L -O https://github.com/gradle/gradle-enterprise-build-config-samples/releases/download/build-validation-development-latest/gradle-enterprise-maven-build-validation.zip && unzip -q -o gradle-enterprise-maven-build-validation.zip
```

The command will download and unpack the scripts to the current directory.

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

