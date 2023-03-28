package com.gradle.enterprise.model;

import java.time.Duration;

public class BuildTimeMetricsData {

    private final Duration initialBuildTime;
    private final Duration instantSavings;
    private final Duration instantSavingsBuildTime;
    private final Duration pendingSavings;
    private final Duration pendingSavingsBuildTime;

    private BuildTimeMetricsData(
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

    public static BuildTimeMetricsData from(BuildValidationData first, BuildValidationData second) {
        final Duration initialBuildTime = first.getBuildTime();
        final Duration instantSavings = first.getBuildTime().minus(second.getBuildTime());
        final Duration instantSavingsBuildTime = second.getBuildTime();
        final Duration pendingSavings = calculatePendingSavings(second);
        final Duration pendingSavingsBuildTime = first.getBuildTime().minus(pendingSavings);
        return new BuildTimeMetricsData(
                initialBuildTime,
                instantSavings,
                instantSavingsBuildTime,
                pendingSavings,
                pendingSavingsBuildTime);
    }

    /**
     * @return the build time of the first build.
     */
    public Duration getInitialBuildTime() {
        return initialBuildTime;
    }

    /**
     * @return the difference in the wall-clock build time between the first and
     * second build.
     */
    public Duration getInstantSavings() {
        return instantSavings;
    }

    /**
     * @return the build time of the second build.
     */
    public Duration getInstantSavingsBuildTime() {
        return instantSavingsBuildTime;
    }

    /**
     * @return an estimation of the savings if all cacheable tasks had been avoided.
     */
    public Duration getPendingSavings() {
        return pendingSavings;
    }

    /**
     * @return an estimation of the build time if all cacheable tasks had been
     * avoided.
     */
    public Duration getPendingSavingsBuildTime() {
        return pendingSavingsBuildTime;
    }

    private static Duration calculatePendingSavings(BuildValidationData data) {
        final long executedCacheableDuration = data.getTasksByAvoidanceOutcome().get("executed_cacheable").totalDuration().toMillis();
        return Duration.ofMillis((long) (executedCacheableDuration / data.getSerializationFactor().doubleValue()));
    }
}
