# Composite Github Actions

The composite actions provided here will simplify running the validation scripts in your Github Action workflow.

## Usage

Create a Github Action workflow, fulfilling the build requirements (add JDK...) and then add the following steps (replacing the placeholders):

```yaml
steps:
  # Download scripts latest version
  - uses: gradle/gradle-enterprise-build-validation-scripts/.github/actions/gradle/download@v1.0.2
    with:
      token: ${{ secrets.GITHUB_TOKEN }}
  # Run experiment 1
  - uses: gradle/gradle-enterprise-build-validation-scripts/.github/actions/gradle/exp1@v1.0.2
    with:
      repositoryUrl: <PROJECT_GIT_URL>
      branch: <PROJECT_BRANCH>
      task: <PROJECT_BUILD_TASK>
      gradleEnterpriseUrl: <GRADLE_ENTERPRISE_URL>
  # Run experiment 2
  - uses: gradle/gradle-enterprise-build-validation-scripts/.github/actions/gradle/exp2@v1.0.2
    with:
      repositoryUrl: <PROJECT_GIT_URL>
      branch: <PROJECT_BRANCH>
      task: <PROJECT_BUILD_TASK>
      gradleEnterpriseUrl: <GRADLE_ENTERPRISE_URL>
  # Run experiment 3
  - uses: gradle/gradle-enterprise-build-validation-scripts/.github/actions/gradle/exp3@v1.0.2
    with:
      repositoryUrl: <PROJECT_GIT_URL>
      branch: <PROJECT_BRANCH>
      task: <PROJECT_BUILD_TASK>
      gradleEnterpriseUrl: <GRADLE_ENTERPRISE_URL>
```

You can then navigate the workflow output and click the investigation links provided by the script.
