package com.gradle.enterprise.model;

import java.time.Duration;

public class BuildTimeMetrics {

    public final Duration initialBuildTime;
    public final Duration instantSavings;
    public final Duration instantSavingsBuildTime;
    public final Duration pendingSavings;
    public final Duration pendingSavingsBuildTime;

    private BuildTimeMetrics(
            Duration initialBuildTime,
            Duration instantSavings,
            Duration instantSavingsBuildTime,
            Duration pendingSavings,
            Duration pendingSavingsBuildTime) {
        this.initialBuildTime = initialBuildTime;
        this.instantSavings = instantSavings;
        this.instantSavingsBuildTime = instantSavingsBuildTime;
        this.pendingSavings = pendingSavings;
        this.pendingSavingsBuildTime = pendingSavingsBuildTime;
    }

    public static BuildTimeMetrics from(BuildValidationData firstBuild, BuildValidationData secondBuild) {
        if (firstBuild.getBuildTime() == null ||
                secondBuild.getBuildTime() == null ||
                secondBuild.getExecutedCacheableSummary() == null ||
                secondBuild.getSerializationFactor() == null) {
            return null;
        }

        final Duration instantSavings = firstBuild.getBuildTime().minus(secondBuild.getBuildTime());
        final Duration pendingSavings =
                Duration.ofMillis((long) (secondBuild.getExecutedCacheableSummary().totalDuration().toMillis()
                        / secondBuild.getSerializationFactor().doubleValue()));
        final Duration pendingSavingsBuildTime = firstBuild.getBuildTime().minus(pendingSavings);

        return new BuildTimeMetrics(
                firstBuild.getBuildTime(),
                instantSavings,
                secondBuild.getBuildTime(),
                pendingSavings,
                pendingSavingsBuildTime);
    }
}
