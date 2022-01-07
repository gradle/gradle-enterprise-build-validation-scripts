rootProject.name = "build-validation"

include("components/capture-published-build-scan-maven-extension")
include("components/fetch-build-scan-data-cmdline-tool")

project(":components/capture-published-build-scan-maven-extension").name = "capture-published-build-scan-maven-extension"
project(":components/fetch-build-scan-data-cmdline-tool").name = "fetch-build-scan-data-cmdline-tool"

