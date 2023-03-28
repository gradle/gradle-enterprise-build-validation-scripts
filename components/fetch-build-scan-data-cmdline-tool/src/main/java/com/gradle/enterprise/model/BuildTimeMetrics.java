package com.gradle.enterprise.model;

import java.math.BigDecimal;
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

    private static Duration calculatePendingSavings(
            TaskExecutionSummary secondBuildExecutedCacheableSummary,
            BigDecimal secondBuildSerializationFactor) {
        final long executedCacheableDuration = secondBuildExecutedCacheableSummary.totalDuration().toMillis();
        return Duration.ofMillis((long) (executedCacheableDuration / secondBuildSerializationFactor.doubleValue()));
    }
}
