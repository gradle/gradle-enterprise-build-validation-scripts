# Composite GitHub Actions

The composite actions provided here will simplify running the build validation scripts from your GitHub Actions workflow.

## Usage

Create a GitHub Actions workflow, add the steps to configure the build requirements like JDK, etc., and then add the
following steps to invoke the actual experiments:

```yaml
steps:
  # Download the latest version of the build validation scripts
  - uses: gradle/gradle-enterprise-build-validation-scripts/.github/actions/maven/download@v2.1
    with:
      token: ${{ secrets.GITHUB_TOKEN }}
  # Run experiment 1
  - uses: gradle/gradle-enterprise-build-validation-scripts/.github/actions/maven/experiment-1@v2.1
    with:
      gitRepo: <PROJECT_GIT_URL>
      gitBranch: <PROJECT_BRANCH>
      goals: <PROJECT_BUILD_GOAL>
      ...
  # Run experiment 2
  - uses: gradle/gradle-enterprise-build-validation-scripts/.github/actions/maven/experiment-2@v2.1
    with:
      gitRepo: <PROJECT_GIT_URL>
      gitBranch: <PROJECT_BRANCH>
      goals: <PROJECT_BUILD_GOAL>
      ...
```

Once the workflow has been triggered and finishes executing, you can navigate to the workflow's output and investigate the summary
produced by the build validation scripts.
