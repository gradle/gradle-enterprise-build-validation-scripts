package com.gradle.enterprise.model;

import java.math.BigDecimal;
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

    public static BuildTimeMetricsData from(BuildValidationData firstBuild, BuildValidationData secondBuild) {
        return from(firstBuild.getBuildTime(), secondBuild.getBuildTime(), secondBuild.getExecutedCacheableSummary(), secondBuild.getSerializationFactor());
    }

    private static BuildTimeMetricsData from(
            Duration firstBuildTime,
            Duration secondBuildTime,
            TaskExecutionSummary secondBuildExecutedCacheableSummary,
            BigDecimal secondBuildSerializationFactor) {
        if (firstBuildTime == null || secondBuildTime == null || secondBuildExecutedCacheableSummary == null || secondBuildSerializationFactor == null) {
            return null;
        }
        final Duration instantSavings = firstBuildTime.minus(secondBuildTime);
        final Duration pendingSavings = calculatePendingSavings(secondBuildExecutedCacheableSummary, secondBuildSerializationFactor);
        final Duration pendingSavingsBuildTime = firstBuildTime.minus(pendingSavings);
        return new BuildTimeMetricsData(firstBuildTime, instantSavings, secondBuildTime, pendingSavings, pendingSavingsBuildTime);
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

    private static Duration calculatePendingSavings(
            TaskExecutionSummary secondBuildExecutedCacheableSummary,
            BigDecimal secondBuildSerializationFactor) {
        final long executedCacheableDuration = secondBuildExecutedCacheableSummary.totalDuration().toMillis();
        return Duration.ofMillis((long) (executedCacheableDuration / secondBuildSerializationFactor.doubleValue()));
    }
}
