rootProject.name = "build-validation"

include("components/capture-build-scan-url-maven-extension")
include("components/fetch-build-scan-data-cmdline-tool")

project(":components/capture-build-scan-url-maven-extension").name = "capture-build-scan-url-maven-extension"
project(":components/fetch-build-scan-data-cmdline-tool").name = "fetch-build-scan-data-cmdline-tool"

