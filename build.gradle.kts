import com.felipefzdz.gradle.shellcheck.Shellcheck
import org.gradle.crypto.checksum.Checksum

plugins {
    id("base")
    id("com.felipefzdz.gradle.shellcheck") version "1.4.6"
    id("com.github.breadmoirai.github-release") version "2.4.1"
    id("org.gradle.crypto.checksum") version "1.4.0"
    id("org.gradle.wrapper-upgrade") version "0.11.1"
}

repositories {
    exclusiveContent {
        forRepository {
            ivy {
                url = uri("https://github.com/matejak/")
                patternLayout {
                    artifact("[module]/archive/refs/tags/[revision].[ext]")
                }
                metadataSources {
                    artifact()
                }
            }
        }
        filter {
            includeModule("argbash", "argbash")
        }
    }
    mavenCentral()
}

val releaseVersion = releaseVersion()
val releaseNotes = releaseNotes()

allprojects {
    version = releaseVersion.get()
}

val argbash by configurations.creating
val commonComponents by configurations.creating
val mavenComponents by configurations.creating

dependencies {
    argbash("argbash:argbash:2.10.0@zip")
    commonComponents(project(path = ":fetch-build-scan-data-cmdline-tool", configuration = "shadow"))
    mavenComponents(project(":configure-gradle-enterprise-maven-extension"))
    mavenComponents("com.gradle:gradle-enterprise-maven-extension:1.16.6")
    mavenComponents("com.gradle:common-custom-user-data-maven-extension:1.11.1")
}

shellcheck {
    additionalArguments = "-a -x"
    shellcheckVersion = "v0.8.0"
}

wrapperUpgrade {
    gradle {
        create("gradle-enterprise-build-validation-scripts") {
            repo.set("gradle/gradle-enterprise-build-validation-scripts")
        }
    }
}

val unpackArgbash by tasks.registering(Copy::class) {
    group = "argbash"
    description = "Unpacks Argbash."
    from(zipTree(argbash.singleFile)) {
        // All files in the zip are under an "argbash-VERSION/" directory. We only want everything under this directory.
        // We can remove the top-level directory while unpacking the zip by dropping the first directory in each file's relative path.
        eachFile {
            relativePath = RelativePath(true, *relativePath.segments.drop(1).toTypedArray())
        }
        includeEmptyDirs = false
    }
    into(layout.buildDirectory.dir("argbash"))
}

val generateBashCliParsers by tasks.registering(ApplyArgbash::class) {
    group = "argbash"
    description = "Uses Argbash to generate Bash command line argument parsing code."
    argbashHome.set(layout.dir(unpackArgbash.map { it.outputs.files.singleFile }))
    scriptTemplates.set(fileTree("components/scripts") {
        include("**/*-cli-parser.m4")
        exclude("gradle/.data/")
        exclude("maven/.data/")
    })
    supportingTemplates.set(fileTree("components/scripts") {
        include("**/*.m4")
        exclude("gradle/.data/")
        exclude("maven/.data/")
    })
}

val copyGradleScripts by tasks.registering(Copy::class) {
    group = "build"
    description = "Copies the Gradle source and generated scripts to output directory."

    // local variable required for configuration cache compatibility
    // https://docs.gradle.org/current/userguide/configuration_cache.html#config_cache:not_yet_implemented:accessing_top_level_at_execution
    val releaseVersion = releaseVersion
    inputs.property("project.version", releaseVersion)

    from(layout.projectDirectory.file("LICENSE"))
    from(layout.projectDirectory.dir("release").file("version.txt"))
    rename("version.txt", "VERSION")

    from(layout.projectDirectory.dir("components/scripts/gradle")) {
        exclude("gradle-init-scripts")
        filter { line: String -> line.replace("<HEAD>", releaseVersion.get()) }
    }
    from(layout.projectDirectory.dir("components/scripts/gradle")) {
        include("gradle-init-scripts/**")
        into("lib/")
    }
    from(layout.projectDirectory.dir("components/scripts")) {
        include("README.md")
        include("mapping.example")
        include("network.settings")
        include("lib/**")
        exclude("lib/cli-parsers")
        filter { line: String -> line.replace("<HEAD>", releaseVersion.get()) }
    }
    from(generateBashCliParsers.map { it.outputDir.file("lib/cli-parsers/gradle") }) {
        into("lib/")
    }
    from(commonComponents) {
        into("lib/export-api-clients/")
    }
    into(layout.buildDirectory.dir("scripts/gradle"))
}

val copyMavenScripts by tasks.registering(Copy::class) {
    group = "build"
    description = "Copies the Maven source and generated scripts to output directory."

    // local variable required for configuration cache compatibility
    // https://docs.gradle.org/current/userguide/configuration_cache.html#config_cache:not_yet_implemented:accessing_top_level_at_execution
    val releaseVersion = releaseVersion
    inputs.property("project.version", releaseVersion)

    from(layout.projectDirectory.file("LICENSE"))
    from(layout.projectDirectory.dir("release").file("version.txt"))
    rename("version.txt", "VERSION")

    from(layout.projectDirectory.dir("components/scripts/maven")) {
        filter { line: String -> line.replace("<HEAD>", releaseVersion.get()) }
    }
    from(layout.projectDirectory.dir("components/scripts/")) {
        include("README.md")
        include("mapping.example")
        include("network.settings")
        include("lib/**")
        exclude("lib/cli-parsers")
        filter { line: String -> line.replace("<HEAD>", releaseVersion.get()) }
    }
    from(generateBashCliParsers.map { it.outputDir.file("lib/cli-parsers/maven") }) {
        into("lib/")
    }
    from(commonComponents) {
        into("lib/export-api-clients/")
    }
    from(mavenComponents) {
        into("lib/maven-libs/")
    }
    into(layout.buildDirectory.dir("scripts/maven"))
}

tasks.register<Task>("copyScripts") {
    group = "build"
    description = "Copies source scripts and autogenerated scripts to output directory."
    dependsOn(copyGradleScripts, copyMavenScripts)
}

val assembleGradleScripts by tasks.registering(Zip::class) {
    group = "build"
    description = "Packages the Gradle experiment scripts in a zip archive."
    archiveBaseName.set("gradle-enterprise-gradle-build-validation")
    archiveFileName.set("${archiveBaseName.get()}-${distributionVersion().get()}.zip")
    from(copyGradleScripts)
    into(archiveBaseName.get())
}

val assembleMavenScripts by tasks.registering(Zip::class) {
    group = "build"
    description = "Packages the Maven experiment scripts in a zip archive."
    archiveBaseName.set("gradle-enterprise-maven-build-validation")
    archiveFileName.set("${archiveBaseName.get()}-${distributionVersion().get()}.zip")
    from(copyMavenScripts)
    into(archiveBaseName.get())
}

tasks.assemble {
    dependsOn(assembleGradleScripts, assembleMavenScripts)
}

val shellcheckGradleScripts by tasks.registering(Shellcheck::class) {
    group = "verification"
    description = "Perform quality checks on Gradle build validation scripts using Shellcheck."
    sourceFiles = copyGradleScripts.get().outputs.files.asFileTree.matching {
        include("**/*.sh")
        // scripts in lib/ are checked when Shellcheck checks the top-level scripts because the top-level scripts include (source) the scripts in lib/
        exclude("lib/")
    }
    // scripts in lib/ are still inputs to this task (we want shellcheck to run if they change) even though we don't include them explicitly in sourceFiles
    inputs.files(copyGradleScripts.get().outputs.files.asFileTree.matching {
        include("lib/**/*.sh")
    }).withPropertyName("libScripts")
        .withPathSensitivity(PathSensitivity.RELATIVE)
    workingDir = layout.buildDirectory.file("scripts/gradle").get().asFile
    reports {
        html.outputLocation.set(layout.buildDirectory.file("reports/shellcheck-gradle/shellcheck.html"))
        xml.outputLocation.set(layout.buildDirectory.file("reports/shellcheck-gradle/shellcheck.xml"))
        txt.outputLocation.set(layout.buildDirectory.file("reports/shellcheck-gradle/shellcheck.txt"))
    }
}

val shellcheckMavenScripts by tasks.registering(Shellcheck::class) {
    group = "verification"
    description = "Perform quality checks on Maven build validation scripts using Shellcheck."
    sourceFiles = copyMavenScripts.get().outputs.files.asFileTree.matching {
        include("**/*.sh")
        // scripts in lib/ are checked when Shellcheck checks the top-level scripts because the top-level scripts include (source) the scripts in lib/
        exclude("lib/")
    }
    // scripts in lib/ are still inputs to this task (we want shellcheck to run if they change) even though we don't include them explicitly in sourceFiles
    inputs.files(copyMavenScripts.get().outputs.files.asFileTree.matching {
        include("lib/**/*.sh")
    }).withPropertyName("libScripts")
        .withPathSensitivity(PathSensitivity.RELATIVE)
    workingDir = layout.buildDirectory.file("scripts/maven").get().asFile
    reports {
        html.outputLocation.set(layout.buildDirectory.file("reports/shellcheck-maven/shellcheck.html"))
        xml.outputLocation.set(layout.buildDirectory.file("reports/shellcheck-maven/shellcheck.xml"))
        txt.outputLocation.set(layout.buildDirectory.file("reports/shellcheck-maven/shellcheck.txt"))
    }
}

tasks.check {
    dependsOn(shellcheckGradleScripts, shellcheckMavenScripts)
}

val generateChecksums by tasks.registering(Checksum::class) {
    group = "distribution"
    description = "Generates checksums for the distribution zip files."
    inputFiles.setFrom(assembleGradleScripts, assembleMavenScripts)
    outputDirectory.set(layout.buildDirectory.dir("distributions/checksums").get().asFile)
    checksumAlgorithm.set(Checksum.Algorithm.SHA512)
}

val isDevelopmentRelease = !hasProperty("finalRelease")

githubRelease {
    token((findProperty("github.access.token") ?: System.getenv("GITHUB_ACCESS_TOKEN") ?: "").toString())
    owner.set("gradle")
    repo.set("gradle-enterprise-build-validation-scripts")
    targetCommitish.set("main")
    releaseName.set(gitHubReleaseName())
    tagName.set(gitReleaseTag())
    prerelease.set(isDevelopmentRelease)
    overwrite.set(isDevelopmentRelease)
    generateReleaseNotes.set(false)
    body.set(releaseNotes)
    releaseAssets(assembleGradleScripts, assembleMavenScripts, generateChecksums.map { it.outputs.files.asFileTree })
}

val createReleaseTag by tasks.registering(CreateGitTag::class) {
    // Ensure tag is created only after a successful build
    mustRunAfter("build")
    tagName.set(gitReleaseTag())
    overwriteExisting.set(isDevelopmentRelease)
}

tasks.githubRelease {
    dependsOn(createReleaseTag)
}

tasks.withType(Sign::class).configureEach {
    notCompatibleWithConfigurationCache("$name task does not support configuration caching")
}

fun gitHubReleaseName(): Provider<String> {
    return releaseVersion.map { if (isDevelopmentRelease) "Development release" else it }
}

fun gitReleaseTag(): Provider<String> {
    return releaseVersion.map { if (isDevelopmentRelease) "development-latest" else "v$it" }
}

fun distributionVersion(): Provider<String> {
    return releaseVersion.map { if (isDevelopmentRelease) "dev" else it }
}

fun releaseVersion(): Provider<String> {
    val versionFile = layout.projectDirectory.file("release/version.txt")
    return providers.fileContents(versionFile).asText.map { it.trim() }
}

fun releaseNotes(): Provider<String> {
    val releaseNotesFile = layout.projectDirectory.file("release/changes.md")
    return providers.fileContents(releaseNotesFile).asText.map { it.trim() }
}