plugins {
    `kotlin-dsl`
}

kotlin {
    jvmToolchain {
        languageVersion.set(JavaLanguageVersion.of(8))

        // Azul has been chosen due to its wide range of supported platforms for
        // Java 8, including arm64 for macOS.
        // See: https://foojay.io/almanac/jdk-8
        vendor.set(JvmVendorSpec.AZUL)
    }
}

repositories {
    mavenCentral()
}
