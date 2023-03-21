import com.gradle.enterprise.gradleplugin.internal.extension.BuildScanExtensionWithHiddenFeatures

plugins {
    id("com.gradle.enterprise") version "3.12.5"
    id("com.gradle.common-custom-user-data-gradle-plugin") version "1.10"
}

val isCI = System.getenv("GITHUB_ACTIONS") != null

gradleEnterprise {
    server = "https://ge.solutions-team.gradle.com"
    buildScan {
        capture { isTaskInputFiles = true }
        isUploadInBackground = !isCI
        publishAlways()
        this as BuildScanExtensionWithHiddenFeatures
        publishIfAuthenticated()
        obfuscation {
            ipAddresses { addresses -> addresses.map { "0.0.0.0" } }
        }
    }
}

buildCache {
    local {
        isEnabled = true
    }

    remote(gradleEnterprise.buildCache) {
        isEnabled = true
        isPush = isCI
    }
}

rootProject.name = "build-validation-scripts"

include("components/capture-build-scan-url-maven-extension")
include("components/fetch-build-scan-data-cmdline-tool")

project(":components/capture-build-scan-url-maven-extension").name = "capture-build-scan-url-maven-extension"
project(":components/fetch-build-scan-data-cmdline-tool").name = "fetch-build-scan-data-cmdline-tool"
