package com.gradle.enterprise.cli;

import com.gradle.enterprise.model.BuildValidationData;
import com.gradle.enterprise.model.TaskExecutionSummary;

import java.math.BigDecimal;
import java.time.Duration;
import java.util.Arrays;
import java.util.function.Function;
import java.util.stream.Stream;

public enum BuildValidationFields {
    // The order the enums are defined controls the order the fields are printed in the CSV
    RUN_NUM("Run Num", d -> toStringSafely(d.runNum())),
    ROOT_PROJECT_NAME("Root Project Name", BuildValidationData::getRootProjectName),
    GE_SERVER("Gradle Enterprise Server", d -> toStringSafely(d.getGradleEnterpriseServerUrl())),
    BUILD_SCAN("Build Scan", d -> toStringSafely(d.getBuildScanUrl())),
    BUILD_SCAN_ID("Build Scan ID", BuildValidationData::getBuildScanId),
    GIT_URL("Git URL", BuildValidationData::getGitUrl),
    GIT_BRANCH("Git Branch", BuildValidationData::getGitBranch),
    GIT_COMMIT_ID("Git Commit ID", BuildValidationData::getGitCommitId),
    REQUESTED_TASKS("Requested Tasks", d -> String.join(" ", d.getRequestedTasks())),
    BUILD_OUTCOME("Build Outcome", BuildValidationData::getBuildOutcome),
    REMOTE_BUILD_CACHE_URL("Remote Build Cache URL", d -> toStringSafely(d.getRemoteBuildCacheUrl())),
    REMOTE_BUILD_CACHE_SHARD("Remote Build Cache Shard", BuildValidationData::getRemoteBuildCacheShard),
    AVOIDED_UP_TO_DATE("Avoided Up To Date", d -> totalTasks(d, "avoided_up_to_date")),
    AVOIDED_UP_TO_DATE_AVOIDANCE_SAVINGS("Avoided up-to-date avoidance savings", d -> totalAvoidanceSavings(d, "avoided_up_to_date")),
    AVOIDED_FROM_CACHE("Avoided from cache", d -> totalTasks(d, "avoided_from_cache")),
    AVOIDED_FROM_CACHE_AVOIDANCE_SAVINGS("Avoided from cache avoidance savings", d -> totalAvoidanceSavings(d, "avoided_from_cache")),
    EXECUTED_CACHEABLE("Executed cacheable", d -> totalTasks(d, "executed_cacheable")),
    EXECUTED_CACHEABLE_DURATION("Executed cacheable duration", d -> totalDuration(d, "executed_cacheable")),
    EXECUTED_NOT_CACHEABLE("Executed not cacheable", d -> totalTasks(d, "executed_not_cacheable")),
    EXECUTED_NOT_CACHEABLE_DURATION("Executed not cacheable duration", d -> totalDuration(d, "executed_not_cacheable")),
    BUILD_TIME("Build time", d -> formatDuration(d.getBuildTime())),
    SERIALIZATION_FACTOR("Serialization factor", d -> toStringSafely(d.getSerializationFactor())),
    ;

    private static final String NO_VALUE = "";

    public final String label;
    public final Function<BuildValidationData, String> value;

    BuildValidationFields(String label, Function<BuildValidationData, String> value) {
        this.label = label;
        this.value = value;
    }

    public static Stream<BuildValidationFields> ordered() {
        return Arrays.stream(BuildValidationFields.values());
    }

    private static String toStringSafely(Object object) {
        return object == null ? NO_VALUE : object.toString();
    }

    private static String toStringSafely(BigDecimal value) {
        return value == null ? NO_VALUE : value.toPlainString();
    }

    private static String totalTasks(BuildValidationData data, String avoidanceOutcome) {
        return summaryTotal(data, avoidanceOutcome, t -> String.valueOf(t.totalTasks()));
    }

    private static String totalAvoidanceSavings(BuildValidationData data, String avoidanceOutcome) {
        return summaryTotal(data, avoidanceOutcome, t -> formatDuration(t.totalAvoidanceSavings()));
    }

    private static String totalDuration(BuildValidationData data, String avoidanceOutcome) {
        return summaryTotal(data, avoidanceOutcome, t -> formatDuration(t.totalDuration()));
    }

    private static String summaryTotal(BuildValidationData data, String avoidanceOutcome, Function<TaskExecutionSummary, String> toString) {
        if (data.getTasksByAvoidanceOutcome().containsKey(avoidanceOutcome)) {
            return toString.apply(data.getTasksByAvoidanceOutcome().get(avoidanceOutcome));
        }
        return NO_VALUE;
    }

    private static String formatDuration(Duration duration) {
        return duration == null ? NO_VALUE : String.valueOf(duration.toMillis());
    }
}
