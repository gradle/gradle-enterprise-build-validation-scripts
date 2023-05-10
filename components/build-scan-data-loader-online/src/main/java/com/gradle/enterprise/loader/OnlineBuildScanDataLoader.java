package com.gradle.enterprise.loader;

import com.gradle.enterprise.api.model.GradleAttributes;
import com.gradle.enterprise.api.model.GradleBuildCachePerformance;
import com.gradle.enterprise.api.model.MavenAttributes;
import com.gradle.enterprise.api.model.MavenBuildCachePerformance;

public class OnlineBuildScanDataLoader implements BuildScanDataLoader {

    @Override
    public Pair<GradleAttributes, GradleBuildCachePerformance> loadDataForGradle() {
        return null;
    }

    @Override
    public Pair<MavenAttributes, MavenBuildCachePerformance> loadDataForMaven() {
        return null;
    }

}
