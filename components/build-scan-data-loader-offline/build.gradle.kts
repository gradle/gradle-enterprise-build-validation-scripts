plugins {
    id("java-library")
}

dependencies {
    api(project(":build-scan-data-loader-api"))
    "runtimeOnly"(files("build-scan-dump-reader.jar"))
}

java {
    toolchain {
        languageVersion.set(JavaLanguageVersion.of(8))
        vendor.set(JvmVendorSpec.AZUL)
    }
}
