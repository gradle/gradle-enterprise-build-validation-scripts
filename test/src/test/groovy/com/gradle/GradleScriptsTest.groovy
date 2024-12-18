//file:noinspection GroovyAssignabilityCheck
package com.gradle

import org.gradle.testkit.runner.GradleRunner
import org.gradle.util.GradleVersion

import static com.gradle.BaseScriptsTest.Experiment.ALL_GRADLE_EXPERIMENTS
import static com.gradle.BaseScriptsTest.Experiment.GRADLE_EXP_2
import static com.gradle.BaseScriptsTest.Experiment.GRADLE_EXP_3

final class GradleScriptsTest extends BaseScriptsTest {

    private static final GradleVersion GRADLE_5_X = GradleVersion.version("5.6.4")
    private static final GradleVersion GRADLE_6_X = GradleVersion.version("6.9.4")
    private static final GradleVersion GRADLE_7_X = GradleVersion.version("7.6.2")
    private static final GradleVersion GRADLE_8_0 = GradleVersion.version("8.0.2")
    private static final GradleVersion GRADLE_8_X = GradleVersion.version("8.11")

    private static final List<GradleVersion> ALL_GRADLE_VERSIONS = [
        GRADLE_5_X,
        GRADLE_6_X,
        GRADLE_7_X,
        GRADLE_8_0,
        GRADLE_8_X,
    ]

    static final List<GradleVersion> CONFIGURATION_CACHE_GRADLE_VERSIONS =
            [GRADLE_6_X, GRADLE_7_X, GRADLE_8_0, GRADLE_8_X]

    private static final String DEVELOCITY_PLUGIN_VERSION = "3.18.2"

    // Gradle-specific 'where' conditions
    private GradleVersion gradleVersion
    private boolean hasTaskWithVolatileInput = false

    private File buildFile
    private File gradleProperties
    private File settingsFile

    def setup() {
        buildFile = new File(testProjectDirectory, "build.gradle")
        gradleProperties = new File(testProjectDirectory, "gradle.properties")
        settingsFile = new File(testProjectDirectory, "settings.gradle")
    }

    def "experiment completes successfully"() {
        given:
        gradleVersion = version

        when:
        run experiment

        then:
        scriptCompletesSuccessfullyWithSummary()

        where:
        [version, experiment] << [ALL_GRADLE_VERSIONS, ALL_GRADLE_EXPERIMENTS].combinations()
    }

    def "can set Develocity server using --develocity-server"() {
        given:
        gradleVersion = version
        hasInvalidServerConfigured = true

        when:
        run experiment, "--develocity-server", develocityServer

        then:
        scriptCompletesSuccessfullyWithSummary()

        where:
        [version, experiment] << [ALL_GRADLE_VERSIONS, GRADLE_EXP_3].combinations()
    }

    def "can inject Develocity plugin using --enable-develocity"() {
        given:
        gradleVersion = version
        hasDevelocityConfigured = false

        when:
        run experiment, "--enable-develocity", "--develocity-server", develocityServer

        then:
        scriptCompletesSuccessfullyWithSummary()

        where:
        [version, experiment] << [ALL_GRADLE_VERSIONS, GRADLE_EXP_3].combinations()
    }

    def "can inject Develocity plugin using --enable-develocity when Develocity is already configured"() {
        given:
        gradleVersion = version
        hasDevelocityConfigured = true

        when:
        run experiment, "--enable-develocity", "--develocity-server", develocityServer

        then:
        scriptCompletesSuccessfullyWithSummary()

        where:
        [version, experiment] << [ALL_GRADLE_VERSIONS, GRADLE_EXP_3].combinations()
    }

    /*
     * We must use experiment 2 for this test because it is the only experiment
     * that invokes both builds using the same tasks in the same directory.
     */
    def "experiments and injection are compatible with Gradle configuration cache"() {
        given:
        gradleVersion = version
        hasDevelocityConfigured = true

        when:
        run experiment, "--enable-develocity", "--develocity-server", develocityServer, "--args", "--configuration-cache"

        then:
        scriptCompletesSuccessfullyWithSummary()
        firstBuildCachesConfiguration()
        secondBuildRestoresConfigurationFromCache()

        where:
        [version, experiment] << [CONFIGURATION_CACHE_GRADLE_VERSIONS, GRADLE_EXP_2].combinations()
    }

    /*
     * There is a bug in versions of Gradle 7.0.2 and earlier that prevents
     * reading system properties via System.getProperty when
     * 'org.gradle.jvmargs' are overridden. To work around this, the init scripts
     * use gradle.startParameter.systemPropertyArgs to read system properties
     * instead.
     */
    def "can inject Develocity plugin using --enable-develocity for projects with org.gradle.jvmargs defined"() {
        given:
        gradleVersion = version
        hasDevelocityConfigured = false
        gradleProperties << "org.gradle.jvmargs=-Dfile.encoding=UTF-8"

        when:
        run experiment, "--enable-develocity", "--develocity-server", develocityServer

        then:
        develocityInjectionIsSuccessful()
        scriptCompletesSuccessfullyWithSummary()

        where:
        [version, experiment] << [ALL_GRADLE_VERSIONS, GRADLE_EXP_3].combinations()
    }

    def "executed cacheable tasks are reported"() {
        given:
        gradleVersion = version
        hasTaskWithVolatileInput = true

        when:
        run experiment

        then:
        //todo ensure executed cacheable tasks is 1
        scriptCompletesSuccessfullyWithSummary()

        where:
        [version, experiment] << [ALL_GRADLE_VERSIONS, GRADLE_EXP_2].combinations()
    }

    @Override
    void buildTestProject() {
        def develocityServer = hasInvalidServerConfigured ? "https://develocity-server.invalid" : develocityServer
        if (gradleVersion < GradleVersion.version("6.0")) {
            buildFile << """
                plugins {
                    id 'base'
                    ${ifDevelocityConfigured("id 'com.gradle.develocity' version '$DEVELOCITY_PLUGIN_VERSION'")}
                }

                ${ifDevelocityConfigured("develocity.server = '$develocityServer'")}
            """
        } else {
            buildFile << """
                plugins {
                    id 'base'
                }
            """
            settingsFile << """
                plugins {
                    ${ifDevelocityConfigured("id 'com.gradle.develocity' version '$DEVELOCITY_PLUGIN_VERSION'")}
                }

                ${ifDevelocityConfigured("develocity.server = '$develocityServer'")}
            """
        }
        settingsFile << "rootProject.name = 'scripts-tests'"

        if (hasTaskWithVolatileInput) {
            buildFile << """
                tasks.register('buildInfo') {
                    inputs.property('buildTime', provider { Instant.now() })
                    outputs.file('build/time.txt')
                    outputs.cacheIf { true }
                    doLast {
                        def buildInfo = new File('build/info.txt')
                        buildInfo.parentFile.mkdirs()
                        buildInfo.createNewFile()
                        buildInfo.text = inputs.properties['buildTime']
                    }
                }
                tasks.named('build').configure {
                    dependsOn('buildInfo')
                }
            """
        } else {
            buildFile << """
                tasks.register('greet') {
                    doLast { println 'Hello, Gradle!' }
                }
                tasks.named('build').configure {
                    dependsOn('greet')
                }
            """
        }
        gitignore << ".gradle/\nbuild/"

        GradleRunner.create()
                .withGradleVersion(gradleVersion.version)
                .withProjectDir(testProjectDirectory)
                .withArguments("wrapper", "--no-scan")
                .forwardOutput()
                .build()
    }

    private void develocityInjectionIsSuccessful() {
        assert !output.contains("Ignoring init script")
    }

    private void firstBuildCachesConfiguration() {
        assert 1 == output.count("Configuration cache entry stored")
    }

    private void secondBuildRestoresConfigurationFromCache() {
        assert 1 == output.count("Calculating task graph")
        assert 1 == output.count("Reusing configuration cache")
    }

}
