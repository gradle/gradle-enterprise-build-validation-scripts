package com.gradle.enterprise.loader;

import com.gradle.enterprise.api.model.GradleAttributes;
import com.gradle.enterprise.api.model.GradleBuildCachePerformance;
import com.gradle.enterprise.api.model.MavenAttributes;
import com.gradle.enterprise.api.model.MavenBuildCachePerformance;

import java.net.URI;

public class OnlineBuildScanDataLoader implements BuildScanDataLoader {

    @Override
    public Pair<GradleAttributes, GradleBuildCachePerformance> loadDataForGradle(URI resource) {
        return null;
    }

    @Override
    public Pair<MavenAttributes, MavenBuildCachePerformance> loadDataForMaven(URI resource) {
        return null;
    }

}
