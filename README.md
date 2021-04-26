# Build Validation Automation

A software development team can gain a lot of efficiency and productivity by optimizing their build to avoid performing
unnecessary work, or work that has been performed already. Shorter builds allow software developers to get feedback
quicker about their changes (does the code compile, do the tests pass?) and helps to reduce context switching (a known
productivity killer).

You can optimize your Gradle and Maen builds to avoid unnecessary work by running controlled, reproducible experiments
and then use [Gradle Enterprise](https://gradle.com/) to understand what ran unnecessarily and why it ran.

This script (and the other experiment scripts) will run many of the steps for you. When run with
`-i/--interactive`, the scripts will explain each step so that you know exactly what the script is doing, and why.

It is a good idea to use interactive mode for the first one or two times you run an experiment, but afterwards, you can
run the script normally to save time.

You may want to repeat these experiments on a regular basis to validate any optimizations you have made or to detect
regressions that may sneak into your builds over time.

## Getting Started

### Installing on Linux and MacOS

Use the following command to download and unpack the validation scripts for Gradle:

```bash
curl https://raw.githubusercontent.com/gradle/gradle-enterprise-build-config-samples/jhurne/experiment-automation/build-validation-automation/distributions/build-validation-automation-for-gradle.zip --output build-automation-for-gradle.zip && unzip build-automation-for-gradle.zip -d build-automation-for-gradle
```

Use the following command to download and unpack the validation scripts for Maven:

```bash
curl https://raw.githubusercontent.com/gradle/gradle-enterprise-build-config-samples/jhurne/experiment-automation/build-validation-automation/distributions/build-validation-automation-for-maven.zip --output build-automation-for-maven.zip && unzip build-automation-for-maven.zip -d build-automation-for-maven
```

Both commands will download the scripts to the current directory and unpack them into an appropriate subdirectory.

### Running the first validation for the first time

Once you have installed the scripts, you can run the first experiment for Gradle by:

```
cd build-validation-automation-for-gradle
./01-validate-incremental-build.sh -i
```

To run the first experiment for Maven:

```
cd build-validation-automation-for-maven
./01-validate-build-caching-local-in-place.sh -i
```

