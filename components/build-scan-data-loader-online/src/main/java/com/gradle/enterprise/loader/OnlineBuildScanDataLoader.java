package com.gradle.enterprise.loader;

import com.gradle.enterprise.api.model.GradleAttributes;
import com.gradle.enterprise.api.model.GradleBuildCachePerformance;
import com.gradle.enterprise.api.model.MavenAttributes;
import com.gradle.enterprise.api.model.MavenBuildCachePerformance;

import java.net.URI;

public final class OnlineBuildScanDataLoader implements BuildScanDataLoader {

    @Override
    public BuildToolType determineBuildToolType(URI resource) {
        return BuildToolType.GRADLE;
    }

    @Override
    public Pair<GradleAttributes, GradleBuildCachePerformance> loadDataForGradle(URI resource) {
        return null;
    }

    @Override
    public Pair<MavenAttributes, MavenBuildCachePerformance> loadDataForMaven(URI resource) {
        return null;
    }

}
