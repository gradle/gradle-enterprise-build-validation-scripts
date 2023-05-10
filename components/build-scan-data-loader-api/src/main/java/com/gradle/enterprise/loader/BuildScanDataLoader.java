package com.gradle.enterprise.loader;

import com.gradle.enterprise.api.model.GradleAttributes;
import com.gradle.enterprise.api.model.GradleBuildCachePerformance;
import com.gradle.enterprise.api.model.MavenAttributes;
import com.gradle.enterprise.api.model.MavenBuildCachePerformance;

public interface BuildScanDataLoader {

    Pair<GradleAttributes, GradleBuildCachePerformance> loadDataForGradle();

    Pair<MavenAttributes, MavenBuildCachePerformance> loadDataForMaven();

    final class Pair<S, T> {

        public final S first;
        public final T second;

        public Pair(S first, T second) {
            this.first = first;
            this.second = second;
        }

    }

}
