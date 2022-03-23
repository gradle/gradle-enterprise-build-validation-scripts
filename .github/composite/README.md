# Composite Github Actions

The composite actions provided here will simplify running the validation scripts in your Github Action workflow.

## Usage

Create a Github Action workflow, fulfilling the build requirements (add JDK...) and then add the following steps (replacing the placeholders):

```yaml
steps:
  - uses: gradle/gradle-enterprise-build-validation-scripts/.github/composite/getLatest@v1.0.2
    with:
      token: ${{ secrets.GITHUB_TOKEN }}
  - uses: gradle/gradle-enterprise-build-validation-scripts/.github/composite/exp1@v1.0.2
    with:
      repositoryUrl: <PROJECT_GIT_URL>
      branch: <PROJECT_BRANCH>
      task: <PROJECT_BUILD_TASK>
      gradleEnterpriseUrl: <GRADLE_ENTERPRISE_URL>
  - uses: gradle/gradle-enterprise-build-validation-scripts/.github/composite/exp2@v1.0.2
    with:
      repositoryUrl: <PROJECT_GIT_URL>
      branch: <PROJECT_BRANCH>
      task: <PROJECT_BUILD_TASK>
      gradleEnterpriseUrl: <GRADLE_ENTERPRISE_URL>
  - uses: gradle/gradle-enterprise-build-validation-scripts/.github/composite/exp3@v1.0.2
    with:
      repositoryUrl: <PROJECT_GIT_URL>
      branch: <PROJECT_BRANCH>
      task: <PROJECT_BUILD_TASK>
      gradleEnterpriseUrl: <GRADLE_ENTERPRISE_URL>
```

You can then navigate the workflow output and click the investigation links provided by the script.
