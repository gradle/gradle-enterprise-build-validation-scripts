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

#### Usage with an authenticated repository

The first step performed by the Develocity Build Validation Scripts is to clone the repository containing the build to validate. If the repository requires authentication to clone, you can use the [`actions/checkout`](https://github.com/marketplace/actions/checkout) action to perform the clone yourself. You can then configure value of the `gitRepo` input parameter for each experiment to the directory containing the local checkout.

```yaml
steps:
  - name: Checkout
    uses: actions/checkout@v4
    with:
      path: project-to-validate # check out the project to a subdirectory
  - uses: gradle/gradle-enterprise-build-validation-scripts/.github/actions/maven/download@actions-stable
    with:
      token: ${{ secrets.GITHUB_TOKEN }}
  - name: Run experiment 2
    uses: gradle/gradle-enterprise-build-validation-scripts/.github/actions/maven/experiment-2@actions-stable
    with:
      gitRepo: "file://$GITHUB_WORKSPACE/project-to-validate" # use the local checkout
      goals: <PROJECT_BUILD_GOAL>
```