import com.gradle.enterprise.gradleplugin.internal.extension.BuildScanExtensionWithHiddenFeatures

plugins {
    id("com.gradle.enterprise") version "3.8.1"
    id("com.gradle.common-custom-user-data-gradle-plugin") version "1.6.4"
}

rootProject.name = "build-validation"

val isCI = System.getenv("GITHUB_ACTIONS") != null

gradleEnterprise {
    server = "https://ge.solutions-team.gradle.com"
    buildScan {
        capture { isTaskInputFiles = true }
        isUploadInBackground = !isCI
        publishAlways()
        this as BuildScanExtensionWithHiddenFeatures
        publishIfAuthenticated()
    }
}

include("components/capture-build-scan-url-maven-extension")
include("components/fetch-build-scan-data-cmdline-tool")

project(":components/capture-build-scan-url-maven-extension").name = "capture-build-scan-url-maven-extension"
project(":components/fetch-build-scan-data-cmdline-tool").name = "fetch-build-scan-data-cmdline-tool"
