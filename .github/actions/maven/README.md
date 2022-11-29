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
  - uses: gradle/gradle-enterprise-build-validation-scripts/.github/actions/maven/download@actions-stable
    with:
      token: ${{ secrets.GITHUB_TOKEN }}
  # Run experiment 1
  - uses: gradle/gradle-enterprise-build-validation-scripts/.github/actions/maven/experiment-1@actions-stable
    with:
      gitRepo: <PROJECT_GIT_URL>
      gitBranch: <PROJECT_BRANCH>
      goals: <PROJECT_BUILD_GOAL>
      ...
  # Run experiment 2
  - uses: gradle/gradle-enterprise-build-validation-scripts/.github/actions/maven/experiment-2@actions-stable
    with:
      gitRepo: <PROJECT_GIT_URL>
      gitBranch: <PROJECT_BRANCH>
      goals: <PROJECT_BUILD_GOAL>
      ...
```

Once the workflow has been triggered and finishes executing, you can navigate to the workflow's output and investigate
the summary produced by the build validation scripts.
