package com.gradle.enterprise.cli;

import com.gradle.enterprise.model.BuildValidationData;
import com.gradle.enterprise.model.TaskExecutionSummary;

import java.time.Duration;
import java.util.Arrays;
import java.util.Locale;
import java.util.function.Function;
import java.util.stream.Stream;

public enum Fields {
    // The order the enums are defined controls the order the fields are printed in the CSV
    ROOT_PROJECT_NAME("Root Project Name", BuildValidationData::getRootProjectName),
    GE_SERVER("Gradle Enterprise Server", d -> toStringSafely(d.getGradleEnterpriseServerUrl())),
    BUILD_SCAN("Build Scan", d -> toStringSafely(d.getBuildScanUrl())),
    BUILD_SCAN_ID("Build Scan ID", BuildValidationData::getBuildScanId),
    GIT_URL("Git URL", BuildValidationData::getGitUrl),
    GIT_BRANCH("Git Branch", BuildValidationData::getGitBranch),
    GIT_COMMIT_ID("Git Commit ID", BuildValidationData::getGitCommitId),
    REQUESTED_TASKS("Requested Tasks", d -> String.join(" ", d.getRequestedTasks())),
    BUILD_OUTCOME("Build Outcome", BuildValidationData::getBuildOutcome),
    REMOTE_BUILD_CACHE_URL("Remote Build Cache URL", d -> toStringSafelyWithTrailingSlash(d.getRemoteBuildCacheUrl())),
    REMOTE_BUILD_CACHE_SHARD("Remote Build Cache Shard", BuildValidationData::getRemoteBuildCacheShard),
    AVOIDED_UP_TO_DATE("Avoided Up To Date", d -> totalTasks(d, "avoided_up_to_date")),
    AVOIDED_UP_TO_DATE_AVOIDANCE_SAVINGS("Avoided up-to-date avoidance savings", d -> totalAvoidanceSavings(d, "avoided_up_to_date")),
    AVOIDED_FROM_CACHE("Avoided from cache", d -> totalTasks(d, "avoided_from_cache")),
    AVOIDED_FROM_CACHE_AVOIDANCE_SAVINGS("Avoided from cache avoidance savings", d -> totalAvoidanceSavings(d, "avoided_from_cache")),
    EXECUTED_CACHEABLE("Executed cacheable", d -> totalTasks(d, "executed_cacheable")),
    EXECUTED_CACHEABLE_DURATION("Executed cacheable duration", d -> totalDuration(d, "executed_cacheable")),
    EXECUTED_NOT_CACHEABLE("Executed not cacheable", d -> totalTasks(d, "executed_not_cacheable")),
    EXECUTED_NOT_CACHEABLE_DURATION("Executed not cacheable duration", d -> totalDuration(d, "executed_not_cacheable")),
    ;

    public final String label;
    public final Function<BuildValidationData, String> value;

    Fields(String label, Function<BuildValidationData, String> value) {
        this.label = label;
        this.value = value;
    }

    public static Stream<Fields> ordered() {
        return Arrays.stream(Fields.values());
    }

    private static String toStringSafely(Object object) {
        if (object == null) {
            return "";
        }
        return object.toString();
    }

    private static String toStringSafelyWithTrailingSlash(Object object) {
        String value = toStringSafely(object);
        if (value.isEmpty() || value.endsWith("/")) {
            return value;
        }
        return value + "/";
    }

    private static String totalTasks(BuildValidationData data, String avoidanceOutcome) {
        if (data.getTasksByAvoidanceOutcome().containsKey(avoidanceOutcome)) {
            return data.getTasksByAvoidanceOutcome().get(avoidanceOutcome).totalTasks().toString();
        }
        return "";
    }

    private static String totalAvoidanceSavings(BuildValidationData data, String avoidanceOutcome) {
        return formatDuration(
            data.getTasksByAvoidanceOutcome()
                .getOrDefault(avoidanceOutcome, TaskExecutionSummary.ZERO)
                .totalAvoidanceSavings()
        );
    }

    private static String totalDuration(BuildValidationData data, String avoidanceOutcome) {
        return formatDuration(
            data.getTasksByAvoidanceOutcome()
                .getOrDefault(avoidanceOutcome, TaskExecutionSummary.ZERO)
                .totalDuration()
        );
    }

    private static String formatDuration(Duration duration) {
        long hours = duration.toHours();
        long minutes = duration.minusHours(hours).toMinutes();
        double seconds = duration.minusHours(hours).minusMinutes(minutes).toMillis() / 1000d;

        StringBuilder s = new StringBuilder();
        if (hours != 0) {
            s.append(hours + "h ");
        }
        if (minutes != 0) {
            s.append(minutes + "m ");
        }
        s.append(String.format(Locale.ROOT, "%.3fs", seconds));

        return s.toString().trim();
    }
}
