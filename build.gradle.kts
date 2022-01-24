import com.felipefzdz.gradle.shellcheck.Shellcheck
import org.gradle.crypto.checksum.Checksum

plugins {
    id("base")
    id("com.felipefzdz.gradle.shellcheck") version "1.4.6"
    id("com.github.breadmoirai.github-release") version "2.2.12"
    id("org.gradle.crypto.checksum") version "1.2.0"
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

val appVersion = layout.projectDirectory.file("release/version.txt").asFile.readText().trim()
allprojects {
    version = appVersion
}

val argbash by configurations.creating
val commonComponents by configurations.creating
val mavenComponents by configurations.creating

dependencies {
    argbash("argbash:argbash:2.10.0@zip")
    commonComponents(project(path = ":fetch-build-scan-data-cmdline-tool", configuration = "shadow"))
    mavenComponents(project(":capture-build-scan-url-maven-extension"))
    mavenComponents("com.gradle:gradle-enterprise-maven-extension:1.12.2")
    mavenComponents("com.gradle:common-custom-user-data-maven-extension:1.9")
}

shellcheck {
    additionalArguments = "-a -x"
    shellcheckVersion = "v0.7.2"
}

val unpackArgbash = tasks.register<Copy>("unpackArgbash") {
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

val applyArgbash = tasks.register<ApplyArgbash>("generateBashCliParsers") {
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

val copyGradleScripts = tasks.register<Copy>("copyGradleScripts") {
    group = "build"
    description = "Copies the Gradle source and generated scripts to output directory."

    from(layout.projectDirectory.file("LICENSE"))
    from(layout.projectDirectory.dir("release").file("version.txt"))
    rename("version.txt", "VERSION")

    from(layout.projectDirectory.dir("components/scripts/gradle")) {
        exclude("gradle-init-scripts")
        filter { line: String -> line.replace("<HEAD>", "${project.version}") }
    }
    from(layout.projectDirectory.dir("components/scripts/gradle")) {
        include("gradle-init-scripts/**")
        into("lib/")
    }
    from(layout.projectDirectory.dir("components/scripts")) {
        include("README.md")
        include("lib/**")
        exclude("lib/cli-parsers")
        filter { line: String -> line.replace("<HEAD>", "${project.version}") }
    }
    from(applyArgbash.map { it.outputDir.file("lib/cli-parsers/gradle") }) {
        into("lib/")
    }
    from(commonComponents) {
        into("lib/export-api-clients/")
    }
    into(layout.buildDirectory.dir("scripts/gradle"))
}

val copyMavenScripts = tasks.register<Copy>("copyMavenScripts") {
    group = "build"
    description = "Copies the Maven source and generated scripts to output directory."

    from(layout.projectDirectory.file("LICENSE"))
    from(layout.projectDirectory.dir("release").file("version.txt"))
    rename("version.txt", "VERSION")

    from(layout.projectDirectory.dir("components/scripts/maven")) {
        filter { line: String -> line.replace("<HEAD>", "${project.version}") }
    }
    from(layout.projectDirectory.dir("components/scripts/")) {
        include("README.md")
        include("lib/**")
        exclude("lib/cli-parsers")
        filter { line: String -> line.replace("<HEAD>", "${project.version}") }
    }
    from(applyArgbash.map { it.outputDir.file("lib/cli-parsers/maven") }) {
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
    dependsOn("copyGradleScripts")
    dependsOn("copyMavenScripts")
}

val assembleGradleScripts = tasks.register<Zip>("assembleGradleScripts") {
    group = "distribution"
    description = "Packages the Gradle experiment scripts in a zip archive."
    archiveBaseName.set("gradle-enterprise-gradle-build-validation")
    archiveFileName.set("${archiveBaseName.get()}-${distributionVersion()}.zip")
    from(copyGradleScripts)
    into(archiveBaseName.get())
}

val assembleMavenScripts = tasks.register<Zip>("assembleMavenScripts") {
    group = "distribution"
    description = "Packages the Maven experiment scripts in a zip archive."
    archiveBaseName.set("gradle-enterprise-maven-build-validation")
    archiveFileName.set("${archiveBaseName.get()}-${distributionVersion()}.zip")
    from(copyMavenScripts)
    into(archiveBaseName.get())
}

tasks.named("assemble") {
    dependsOn("assembleGradleScripts")
    dependsOn("assembleMavenScripts")
}

tasks.register<Shellcheck>("shellcheckGradleScripts") {
    group = "verification"
    description = "Perform quality checks on Gradle build validation scripts using Shellcheck."
    inputs.files(copyGradleScripts.get().outputs.files.asFileTree.matching {
        include("**/*.sh")
    })
    sourceFiles = copyGradleScripts.get().outputs.files.asFileTree.matching {
        include("**/*.sh")
        exclude("lib/")
    }
    workingDir = layout.buildDirectory.file("scripts/gradle").get().asFile
    reports {
        html.outputLocation.set(layout.buildDirectory.file("reports/shellcheck-gradle/shellcheck.html"))
        xml.outputLocation.set(layout.buildDirectory.file("reports/shellcheck-gradle/shellcheck.xml"))
        txt.outputLocation.set(layout.buildDirectory.file("reports/shellcheck-gradle/shellcheck.txt"))
    }
}

tasks.register<Shellcheck>("shellcheckMavenScripts") {
    group = "verification"
    description = "Perform quality checks on Maven build validation scripts using Shellcheck."
    inputs.files(copyMavenScripts.get().outputs.files.asFileTree.matching {
        include("**/*.sh")
    })
    sourceFiles = copyMavenScripts.get().outputs.files.asFileTree.matching {
        include("**/*.sh")
        exclude("lib/")
    }
    workingDir = layout.buildDirectory.file("scripts/maven").get().asFile
    reports {
        html.outputLocation.set(layout.buildDirectory.file("reports/shellcheck-maven/shellcheck.html"))
        xml.outputLocation.set(layout.buildDirectory.file("reports/shellcheck-maven/shellcheck.xml"))
        txt.outputLocation.set(layout.buildDirectory.file("reports/shellcheck-maven/shellcheck.txt"))
    }
}

tasks.named("check") {
    dependsOn("shellcheckGradleScripts")
    dependsOn("shellcheckMavenScripts")
}

val generateChecksums = tasks.register<Checksum>("generateChecksums") {
    group = "distribution"
    description = "Generates checksums for the distribution zip files."
    files = assembleGradleScripts.get().outputs.files.plus(assembleMavenScripts.get().outputs.files)
    outputDir = layout.buildDirectory.dir("distributions/checksums").get().asFile
    algorithm = Checksum.Algorithm.SHA512
    files.forEach {
        outputs.file(File(outputDir, "${it.name}.sha512"))
    }
}

val isDevelopmentRelease = !hasProperty("finalRelease")

githubRelease {
    token((findProperty("github.access.token") ?: System.getenv("GITHUB_ACCESS_TOKEN") ?: "").toString())
    owner.set("gradle")
    repo.set("gradle-enterprise-build-validation-scripts")
    targetCommitish.set("main")
    releaseName.set(releaseName())
    tagName.set(releaseTag())
    prerelease.set(isDevelopmentRelease)
    overwrite.set(isDevelopmentRelease)
    body.set(layout.projectDirectory.file("release/changes.md").asFile.readText().trim())
    releaseAssets(assembleGradleScripts, assembleMavenScripts, generateChecksums)
}

tasks.register<CreateGitTag>("createReleaseTag") {
    tagName.set(releaseTag())
    overwriteExisting.set(isDevelopmentRelease)
}

tasks.named("githubRelease") {
    dependsOn("createReleaseTag")
}

fun releaseName(): String {
    if (isDevelopmentRelease) {
        return "Development Build"
    } else {
        return version.toString()
    }
}

fun releaseTag(): String {
    if (isDevelopmentRelease) {
        return "development-latest"
    } else {
        return "v${version}"
    }
}

fun distributionVersion(): String {
    if (isDevelopmentRelease) {
        return "dev"
    } else {
        return version.toString()
    }
}
