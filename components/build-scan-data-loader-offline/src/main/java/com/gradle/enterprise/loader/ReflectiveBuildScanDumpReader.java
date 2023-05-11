package com.gradle.enterprise.loader;

import com.gradle.enterprise.api.model.GradleAttributes;
import com.gradle.enterprise.api.model.GradleBuildCachePerformance;
import com.gradle.enterprise.api.model.MavenAttributes;
import com.gradle.enterprise.api.model.MavenBuildCachePerformance;
import com.gradle.enterprise.loader.BuildScanDataLoader.Pair;

import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.nio.file.FileSystems;
import java.nio.file.Path;

import static com.gradle.enterprise.loader.BuildScanDataLoader.*;

final class ReflectiveBuildScanDumpReader {

    private final Object buildScanDumpReader;

    private ReflectiveBuildScanDumpReader(Object buildScanDumpReader) {
        this.buildScanDumpReader = buildScanDumpReader;
    }

    static ReflectiveBuildScanDumpReader newInstance(Path licenseFile) {
        try {
            Class<?> buildScanDumpExtractorClass = Class.forName("com.gradle.enterprise.scans.supporttools.scandump.BuildScanDumpReader");
            Method newInstance = buildScanDumpExtractorClass.getMethod("newInstance", Path.class);
            Object instance = newInstance.invoke(null, licenseFile);
            return new ReflectiveBuildScanDumpReader(instance);
        } catch (ClassNotFoundException e) {
            throw new IllegalStateException("Unable to find the Build Scan dump extractor", e);
        } catch (InvocationTargetException e) {
            // We know that the real BuildScanDumpExtractor can only throw runtime exceptions (no checked exceptions are declared)
            throw (RuntimeException) e.getCause();
        } catch (NoSuchMethodException | IllegalAccessException e) {
            throw new RuntimeException("Unable to read Build Scan dumps: " + e.getMessage(), e);
        }
    }

    BuildToolType readBuildToolType(Path scanDump) {
        try {
            Method readBuildToolType = buildScanDumpReader.getClass().getMethod("readBuildToolType", Path.class);
            String buildToolType = (String) readBuildToolType.invoke(null, scanDump);
            return BuildToolType.valueOf(buildToolType);
        } catch (InvocationTargetException e) {
            // We know that the real BuildScanDumpExtractor can only throw runtime exceptions (no checked exceptions are declared)
            throw (RuntimeException) e.getCause();
        } catch (NoSuchMethodException | IllegalAccessException e) {
            throw new RuntimeException("Unable to read Build Scan dumps: " + e.getMessage(), e);
        }
    }

    Pair<GradleAttributes, GradleBuildCachePerformance> readGradleBuildScanDump(Path scanDump) {
        try {
            Method extractGradleBuildScanDump = buildScanDumpReader.getClass().getMethod("readGradleBuildScanDump", Path.class);
            Object gradleBuild = extractGradleBuildScanDump.invoke(buildScanDumpReader, scanDump);

            GradleAttributes attributes = (GradleAttributes) gradleBuild.getClass().getField("attributes").get(gradleBuild);
            GradleBuildCachePerformance buildCachePerformance = (GradleBuildCachePerformance) gradleBuild.getClass().getField("buildCachePerformance").get(gradleBuild);

            return new Pair<>(attributes, buildCachePerformance);
        } catch (InvocationTargetException e) {
            // We know that the real BuildScanDumpExtractor can only throw runtime exceptions (no checked exceptions are declared)
            throw (RuntimeException) e.getCause();
        } catch (NoSuchMethodException | NoSuchFieldException | IllegalAccessException e) {
            throw new RuntimeException("Unable to read Build Scan dump: " + e.getMessage(), e);
        }
    }

    @SuppressWarnings({"WeakerAccess", "unused"})
    Pair<MavenAttributes, MavenBuildCachePerformance> readMavenBuildScanDump(Path scanDump) {
        try {
            Method extractMavenBuildScanDump = buildScanDumpReader.getClass().getMethod("readMavenBuildScanDump", Path.class);
            Object mavenBuild = extractMavenBuildScanDump.invoke(buildScanDumpReader, scanDump);

            MavenAttributes attributes = (MavenAttributes) mavenBuild.getClass().getField("attributes").get(mavenBuild);
            MavenBuildCachePerformance buildCachePerformance = (MavenBuildCachePerformance) mavenBuild.getClass().getField("buildCachePerformance").get(mavenBuild);

            return new Pair<>(attributes, buildCachePerformance);
        } catch (InvocationTargetException e) {
            // We know that the real BuildScanDumpExtractor can only throw runtime exceptions (no checked exceptions are declared)
            throw (RuntimeException) e.getCause();
        } catch (NoSuchMethodException | NoSuchFieldException | IllegalAccessException e) {
            throw new RuntimeException("Unable to read Build Scan dump: " + e.getMessage(), e);
        }
    }

    // TODO Remove
    public static void main(String[] args) {
        ReflectiveBuildScanDumpReader extractor = ReflectiveBuildScanDumpReader.newInstance(FileSystems.getDefault().getPath("/Users/jhurne/Projects/road-tests/build-validation/gradle-enterprise.aux.prod.license"));
        Pair<GradleAttributes, GradleBuildCachePerformance> result = extractor.readGradleBuildScanDump(FileSystems.getDefault().getPath("/Users/jhurne/Projects/road-tests/build-validation/gradle-enterprise-gradle-build-validation/.data/02-validate-local-build-caching-same-location/20230511T111441-645cb201/second-build_ge-solutions/sample-projects/gradle/8.x/no-ge/build-scan-8.0.2-3.12.6-1683796487697-104c8ac5-cf01-4eb6-8b2d-f447d4803249.scan"));
        System.out.println("Successfully fetched build scan dump data: " + result);
    }

}
