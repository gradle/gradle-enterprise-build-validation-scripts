# Composite Github Actions

The composite actions provided here will simplify running the validation scripts in your Github Action workflow.

## Usage

Create a Github Action workflow, fulfilling the build requirements (add JDK...) and then add the following steps (replacing the placeholders):

```yaml
steps:
  # Download scripts latest version
  - uses: gradle/gradle-enterprise-build-validation-scripts/.github/composite/getLatest@v1.0.2
    with:
      token: ${{ secrets.GITHUB_TOKEN }}
  # Run experiment 1
  - uses: gradle/gradle-enterprise-build-validation-scripts/.github/composite/exp1@v1.0.2
    with:
      repositoryUrl: <PROJECT_GIT_URL>
      branch: <PROJECT_BRANCH>
      task: <PROJECT_BUILD_TASK>
      gradleEnterpriseUrl: <GRADLE_ENTERPRISE_URL>
  # Run experiment 2
  - uses: gradle/gradle-enterprise-build-validation-scripts/.github/composite/exp2@v1.0.2
    with:
      repositoryUrl: <PROJECT_GIT_URL>
      branch: <PROJECT_BRANCH>
      task: <PROJECT_BUILD_TASK>
      gradleEnterpriseUrl: <GRADLE_ENTERPRISE_URL>
  # Run experiment 3
  - uses: gradle/gradle-enterprise-build-validation-scripts/.github/composite/exp3@v1.0.2
    with:
      repositoryUrl: <PROJECT_GIT_URL>
      branch: <PROJECT_BRANCH>
      task: <PROJECT_BUILD_TASK>
      gradleEnterpriseUrl: <GRADLE_ENTERPRISE_URL>
```

You can then navigate the workflow output and click the investigation links provided by the script.

## Automated validation

You may want to periodically run the experiments above and automatically check that there are no performance regressions (aka more tasks running or more cache misses than expected).
- ```gradleEnterpriseUrl``` is the URL of your Gradle Enterprise server
- ```token``` is the Gradle Enterprise token
- ```buildId1``` is the first build identifier (used to check that build was successful)
- ```buildId2``` is the second build identifier
- ```executionStatus``` execution status, can be ```"executed_"``` to check for tasks which actually run or ```"executed_cacheable"``` if you'd like to check specifically for cacheable tasks
- ```expectedTasks``` is the lexicographically ordered csv list of tasks which should normally match the ```executionStatus``` (can be omitted if no task should match the status)
- ```continueOnError: true``` can optionally be set if you'd like your workflow to keep running no matter if a failure has been encountered

```yaml
  - uses: gradle/gradle-enterprise-build-validation-scripts/.github/composite/exp1@v1.0.2
    id: run1
    with:
      repositoryUrl: <PROJECT_GIT_URL>
      branch: <PROJECT_BRANCH>
      task: <PROJECT_BUILD_TASK>
      gradleEnterpriseUrl: <GRADLE_ENTERPRISE_URL>
  - uses: gradle/gradle-enterprise-build-validation-scripts/.github/composite/assert@v1.0.2
    with:
      gradleEnterpriseUrl: <GRADLE_ENTERPRISE_URL>
      token: <GRADLE_ENTERPRISE_API_KEY>
      buildId1: ${{ steps.run1.outputs.buildScanId1 }}
      buildId2: ${{ steps.run1.outputs.buildScanId2 }}
      executionStatus: "executed_"
      expectedTasks: <ORDERED_CSV_LIST>
```
