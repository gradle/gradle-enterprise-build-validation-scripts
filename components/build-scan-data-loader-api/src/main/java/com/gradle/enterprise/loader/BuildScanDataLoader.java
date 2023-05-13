package com.gradle.enterprise.loader;

import com.gradle.enterprise.api.model.GradleAttributes;
import com.gradle.enterprise.api.model.GradleBuildCachePerformance;
import com.gradle.enterprise.api.model.MavenAttributes;
import com.gradle.enterprise.api.model.MavenBuildCachePerformance;

import java.net.MalformedURLException;
import java.net.URI;
import java.net.URL;
import java.util.Optional;

public interface BuildScanDataLoader {

    BuildToolType determineBuildToolType(URI resource);

    // TODO add static factory method to build the BuildScanDataLoader

    // todo in online mode, fetch the two models in parallel (for both Gradle and Maven)
    BuildScanData<GradleAttributes, GradleBuildCachePerformance> loadDataForGradle(URI resource);

    BuildScanData<MavenAttributes, MavenBuildCachePerformance> loadDataForMaven(URI resource);

    static

    enum BuildToolType {GRADLE, MAVEN}

    final class BuildScanData<A, B> {

        public final Optional<URI> gradleEnterpriseServerUri;
        public final A attributes;
        public final B buildCachePerformance;

        public BuildScanData(Optional<URI> gradleEnterpriseServerUri, A attributes, B buildCachePerformance) {
            this.gradleEnterpriseServerUri = gradleEnterpriseServerUri;
            this.attributes = attributes;
            this.buildCachePerformance = buildCachePerformance;
        }

        public Optional<URL> gradleEnterpriseServerURL() {
            return gradleEnterpriseServerUri.map(u -> {
                try {
                    return u.toURL();
                } catch (MalformedURLException e) {
                    // Should never get here
                    throw new RuntimeException(e);
                }
            });
        }
    }

}
