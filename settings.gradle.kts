plugins {
    id("com.gradle.develocity") version "3.17"
    id("com.gradle.common-custom-user-data-gradle-plugin") version "2.0"
    id("org.gradle.toolchains.foojay-resolver-convention") version "0.8.0"
}

val isCI = System.getenv("GITHUB_ACTIONS") != null

develocity {
    server = "https://ge.solutions-team.gradle.com"
    buildScan {
        uploadInBackground = !isCI
        publishing.onlyIf { it.isAuthenticated }
        obfuscation.ipAddresses { addresses -> addresses.map { "0.0.0.0" } }
    }
}

buildCache {
    remote(develocity.buildCache) {
        isEnabled = true
        // Check access key presence to avoid build cache errors on PR builds when access key is not present
        val accessKey = System.getenv("GRADLE_ENTERPRISE_ACCESS_KEY")
        isPush = isCI && !accessKey.isNullOrEmpty()
    }
}

rootProject.name = "build-validation-scripts"

include("components/configure-gradle-enterprise-maven-extension")
include("components/fetch-build-scan-data-cmdline-tool")

project(":components/configure-gradle-enterprise-maven-extension").name = "configure-gradle-enterprise-maven-extension"
project(":components/fetch-build-scan-data-cmdline-tool").name = "fetch-build-scan-data-cmdline-tool"
