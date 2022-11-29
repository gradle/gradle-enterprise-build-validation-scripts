# Composite GitHub Actions

## Build cache compatibility

Composite actions that will simplify running the build validation scripts that validate Build Cache compatibility
from your GitHub Actions workflow.

### Usage

Create a GitHub Actions workflow with the following steps:
- Configure the build requirements like JDK, etc.
- Add the following composite steps to invoke the actual experiments

```yaml
steps:
  # Download the latest version of the build validation scripts
  - uses: gradle/gradle-enterprise-build-validation-scripts/.github/actions/gradle/download@actions-stable
    with:
      token: ${{ secrets.GITHUB_TOKEN }}
  # Run experiment 1
  - uses: gradle/gradle-enterprise-build-validation-scripts/.github/actions/gradle/experiment-1@actions-stable
    with:
      gitRepo: <PROJECT_GIT_URL>
      gitBranch: <PROJECT_BRANCH>
      tasks: <PROJECT_BUILD_TASK>
      ...
  # Run experiment 2
  - uses: gradle/gradle-enterprise-build-validation-scripts/.github/actions/gradle/experiment-2@actions-stable
    with:
      gitRepo: <PROJECT_GIT_URL>
      gitBranch: <PROJECT_BRANCH>
      tasks: <PROJECT_BUILD_TASK>
      ...
  # Run experiment 3
  - uses: gradle/gradle-enterprise-build-validation-scripts/.github/actions/gradle/experiment-3@actions-stable
    with:
      gitRepo: <PROJECT_GIT_URL>
      gitBranch: <PROJECT_BRANCH>
      tasks: <PROJECT_BUILD_TASK>
      ...
```

Once the workflow has been triggered and finishes executing, you can navigate to the workflow's output and investigate
the summary produced by the build validation scripts.

## Configuration cache compatibility

Composite actions that will simplify validating Configuration Cache compatibility 
from your GitHub Actions workflow.

### Usage
Create a GitHub Actions workflow with the following steps:
- Clone the project source code
- Configure the build requirements like JDK, etc.
- Add the `experiment-config-cache` composite step

```yaml
steps:
  # Run configuration cache experiment
  - uses: gradle/gradle-enterprise-build-validation-scripts/.github/actions/gradle/experiment-config-cache@actions-stable
    with:
      tasks: "build"
      args: "-Pfoo=bar"
```

Once the workflow has been triggered and finishes executing, the workflow will either have succeeded if the invoked 
build is Configuration Cache compatible, or it will have failed if the invoked build is not Configuration Cache compatible.
