# Build Validation Automation

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
curl https://raw.githubusercontent.com/gradle/gradle-enterprise-build-config-samples/jhurne/experiment-automation/build-validation/distributions/build-validation-automation-for-gradle.zip --output build-validation-automation-for-gradle.zip && unzip build-validation-automation-for-gradle.zip -d build-validation-automation-for-gradle
```

The command will download and unpack the scripts to the current directory.

### Running the first validation for the first time

Once you have installed the scripts, you can run the first experiment for Gradle:

```bash
cd build-validation-automation-for-gradle
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

Each script accepts the following command line arguments:

```
-i, --interactive                  Enables interactive mode.
-r, --git-repo                     Specifies the URL for the Git repository to validate.
-b, --git-branch                   Specifies the branch for the Git repository to validate.
-t, --tasks                        Declares the Gradle tasks to invoke.
-a, --args                         Declares additional arguments to pass to Gradle.
-p, --project-dir                  Specifies the start directory within the Git repo.
-s, --gradle-enterprise-server     Enables Gradle Enterprise on a project not already connected.
-e, --enable-gradle-enterprise     Enables Gradle Enterprise on a project that it is not already enabled on.
-h, --help                         Shows this help message.
```

## Validating Maven Builds

### Installing on Linux and MacOS

Use the following command to download and unpack the validation scripts for Maven:

```bash
curl https://raw.githubusercontent.com/gradle/gradle-enterprise-build-config-samples/jhurne/experiment-automation/build-validation/distributions/build-validation-automation-for-maven.zip --output build-validation-automation-for-maven.zip && unzip build-validation-automation-for-maven.zip -d build-validation-automation-for-maven
```

The command will download and unpack the scripts to the current directory.

### Running the first validation for the first time

Once you have installed the scripts, you can run the first experiment for Maven:

```bash
cd build-validation-automation-for-maven
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

Each script accepts the following command line arguments:

```
-i, --interactive                  Enables interactive mode.
-r, --git-repo                     Specifies the URL for the Git repository to validate.
-b, --git-branch                   Specifies the branch for the Git repository to validate.
-t, --tasks                        Declares the Maven goals to invoke.
-a, --args                         Sets additional arguments to pass to Maven.
-p, --project-dir                  Specifies the start directory within the Git repo.
-s, --gradle-enterprise-server     Enables Gradle Enterprise on a project not already connected.
-h, --help                         Shows this help message.
```
