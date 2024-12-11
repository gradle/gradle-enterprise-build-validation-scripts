package com.gradle

import spock.lang.Shared
import spock.lang.Specification
import spock.lang.TempDir

import java.nio.file.Files
import java.util.concurrent.TimeUnit

abstract class BaseScriptsTest extends Specification {

    final static String develocityServer = System.getProperty("build-validation.test.develocity.server")
    final static String jdk8HomeDirectory = System.getProperty("build-validation.test.jdk8-home")

    @TempDir
    @Shared
    private File workingDirectory

    // Common 'where' conditions
    boolean hasDevelocityConfigured = true
    boolean hasInvalidServerConfigured = false

    // Test project components
    @TempDir
    File testProjectDirectory
    File gitignore

    // Script arguments
    String[] tasks = ["build"]
    String[] goals = ["verify"]
    private File gitRepo

    // Outcomes
    int exitCode
    String output

    void setupSpec() {
        unpackGradleScripts()
    }

    private void unpackGradleScripts() {
        def gradleScriptsResource = new File(this.class.getResource("/develocity-gradle-build-validation-dev.zip").toURI())
        def gradleScriptsArchive = new File(workingDirectory, "develocity-gradle-build-validation-dev.zip")
        copy(gradleScriptsResource, gradleScriptsArchive)
        unzip(gradleScriptsArchive)
    }

    void setup() {
        gitignore = new File(testProjectDirectory, ".gitignore")
        gitRepo = testProjectDirectory
    }

    String ifDevelocityConfigured(String value) {
        return hasDevelocityConfigured ? value : ""
    }

    static enum Experiment {
        GRADLE_EXP_1("01-validate-incremental-building", "exp1-gradle"),
        GRADLE_EXP_2("02-validate-local-build-caching-same-location", "exp2-gradle"),
        GRADLE_EXP_3("03-validate-local-build-caching-different-locations", "exp3-gradle"),
        MAVEN_EXP_1("01-validate-local-build-caching-same-location", "exp1-maven"),
        MAVEN_EXP_2("02-validate-local-build-caching-different-locations", "exp2-maven");

        static final List<Experiment> ALL_GRADLE_EXPERIMENTS = [GRADLE_EXP_1, GRADLE_EXP_2, GRADLE_EXP_3]
        static final List<Experiment> ALL_MAVEN_EXPERIMENTS = [MAVEN_EXP_1, MAVEN_EXP_2]

        private final String scriptName
        private final String shortName

        Experiment(String scriptName, String shortName) {
            this.scriptName = scriptName
            this.shortName = shortName
        }

        boolean isGradle() {
            return [GRADLE_EXP_1, GRADLE_EXP_2, GRADLE_EXP_3].contains(this)
        }

        String getContainingDirectory() {
            return "develocity-${isGradle() ? "gradle" : "maven"}-build-validation"
        }

        @Override
        String toString() {
            return shortName
        }

    }

    void run(Experiment experiment, String... args) {
        buildTestProject()
        initializeTestProjectRepository()

        String[] command = new String[] {
            "./${experiment.scriptName}.sh",
            "--git-repo", "file://${gitRepo.absolutePath}"
        }
        command += experiment.isGradle() ? ["--tasks", tasks.join(" ")] : ["--goals", goals.join(" ")]
        command += args
        println("\n\$ ${command.join(" ")}")

        def result = runProcess(new File(workingDirectory, experiment.containingDirectory), command)
        exitCode = result.exitCode
        output = result.output
    }

    abstract void buildTestProject()

    private void initializeTestProjectRepository() {
        runProcess(testProjectDirectory, "git", "init")
        runProcess(testProjectDirectory, "git", "config", "user.email", "bill@example.com")
        runProcess(testProjectDirectory, "git", "config", "user.name", "Bill D. Tual")
        runProcess(testProjectDirectory, "git", "add", ".")
        runProcess(testProjectDirectory, "git", "commit", "-m", "'Create project'")
    }

    private static ProcessResult runProcess(File workingDirectory, String... args) {
        def processBuilder = new ProcessBuilder(args).directory(workingDirectory).redirectErrorStream(true)
        processBuilder.environment()["JAVA_HOME"] = jdk8HomeDirectory
        def process = processBuilder.start()
        def output = new StringBuilder()
        try (def reader = new BufferedReader(new InputStreamReader(process.inputStream))) {
            reader.eachLine {
                println(it)
                output.append(it).append('\n')
            }
        }
        process.waitFor(3, TimeUnit.SECONDS)
        return new ProcessResult(process.exitValue(), output.toString())
    }

    private static void copy(File target, File destination) {
        Files.copy(target.toPath(), destination.toPath())
    }

    private static void unzip(File target) {
        runProcess(target.parentFile, "unzip", "-q", "-o", target.name)
    }

    private static class ProcessResult {

        final int exitCode
        final String output

        ProcessResult(int exitCode, String output) {
            this.exitCode = exitCode
            this.output = output
        }
    }

    void scriptCompletesSuccessfullyWithSummary() {
        assert exitCode == 0
        assert output.contains("Summary")
        assert output.contains("Performance Characteristics")
        assert output.contains("Investigation Quick Links")
    }

}
