package com.gradle.enterprise.model;

import java.math.BigDecimal;
import java.time.Duration;

public class BuildTimeMetrics {

    private final Duration initialBuildTime;
    private final Duration instantSavings;
    private final Duration instantSavingsBuildTime;
    private final Duration pendingSavings;
    private final Duration pendingSavingsBuildTime;

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
        final Duration buildTimeFirstBuild = firstBuild.getBuildTime();
        final Duration buildTimeSecondBuild = secondBuild.getBuildTime();
        final TaskExecutionSummary executedCacheableTaskSummarySecondBuild = secondBuild.getExecutedCacheableSummary();
        final BigDecimal serializationFactorSecondBuild = secondBuild.getSerializationFactor();

        if (buildTimeFirstBuild == null || buildTimeSecondBuild == null || executedCacheableTaskSummarySecondBuild == null || serializationFactorSecondBuild == null) {
            return null;
        }

        final Duration instantSavings = buildTimeFirstBuild.minus(buildTimeSecondBuild);
        final Duration pendingSavings = calculatePendingSavings(executedCacheableTaskSummarySecondBuild, serializationFactorSecondBuild);
        final Duration pendingSavingsBuildTime = buildTimeFirstBuild.minus(pendingSavings);

        return new BuildTimeMetrics(buildTimeFirstBuild, instantSavings, buildTimeSecondBuild, pendingSavings, pendingSavingsBuildTime);
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
