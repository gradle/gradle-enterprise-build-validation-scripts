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

It is recommended that you run a given script in _interactive_ mode for the first time to make yourself familiar
with the flow of the experiment. In the example below, the script is executed interactively.

```bash
./01-validate-incremental-building.sh -i
```

Once you are familiar with a given script, you can run it in _non-interactive_ mode. In the example below,
the script is run autonomously with the provided configuration options.

```bash
./01-validate-incremental-building.sh -r https://github.com/etiennestuder/java-ordered-properties -b master -t build
```

You can also combine the _interactive_ mode with some configuration options already provided upfront, as shown
in the example below.

```bash
./01-validate-incremental-building.sh -i -r https://github.com/etiennestuder/java-ordered-properties
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
