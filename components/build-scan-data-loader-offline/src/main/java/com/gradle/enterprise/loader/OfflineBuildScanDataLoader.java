package com.gradle.enterprise.loader;

import com.gradle.enterprise.api.model.GradleAttributes;
import com.gradle.enterprise.api.model.GradleBuildCachePerformance;
import com.gradle.enterprise.api.model.MavenAttributes;
import com.gradle.enterprise.api.model.MavenBuildCachePerformance;

import java.net.URI;
import java.nio.file.Path;
import java.nio.file.Paths;

public final class OfflineBuildScanDataLoader implements BuildScanDataLoader {

    private final ReflectiveBuildScanDumpReader reader;

    private OfflineBuildScanDataLoader(ReflectiveBuildScanDumpReader reader) {
        this.reader = reader;
    }

    public static OfflineBuildScanDataLoader newInstance(Path licenseFile) {
        return new OfflineBuildScanDataLoader(ReflectiveBuildScanDumpReader.newInstance(licenseFile));
    }

    @Override
    public BuildToolType determineBuildToolType(URI resource) {
        return reader.readBuildToolType(Paths.get(resource));
    }

    @Override
    public BuildScanData<GradleAttributes, GradleBuildCachePerformance> loadDataForGradle(URI resource) {
        return reader.readGradleBuildScanDump(Paths.get(resource));
    }

    @Override
    public BuildScanData<MavenAttributes, MavenBuildCachePerformance> loadDataForMaven(URI resource) {
        return reader.readMavenBuildScanDump(Paths.get(resource));
    }

}
