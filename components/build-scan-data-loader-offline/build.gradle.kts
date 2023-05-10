plugins {
    id("java-library")
}

dependencies {
    api(project(":build-scan-data-loader-api"))
}

java {
    toolchain {
        languageVersion.set(JavaLanguageVersion.of(8))
        vendor.set(JvmVendorSpec.AZUL)
    }
}
