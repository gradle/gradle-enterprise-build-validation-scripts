package com.gradle.enterprise;

import java.util.Arrays;
import java.util.Map;
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
    REMOTE_BUILD_CACHE_URL("Remote Build Cache URL", d -> toStringSafely(d.getRemoteBuildCacheUrl())),
    REMOTE_BUILD_CACHE_SHARD("Remote Build Cache Shard", BuildValidationData::getRemoteBuildCacheShard),
    AVOIDED_UP_TO_DATE("Avoided Up To Date", d -> taskCount(d, "avoided_up_to_date")),
    AVOIDED_FROM_CACHE("Avoided from cache", Fields::totalAvoidedFromCache),
    AVOIDED_FROM_LOCAL_CACHE("Avoided from local cache", d -> taskCount(d, "avoided_from_local_cache")),
    AVOIDED_FROM_REMOTE_CACHE("Avoided from remote cache", d -> taskCount(d, "avoided_from_remote_cache")),
    EXECUTED_CACHEABLE("Executed cacheable", d -> taskCount(d, "executed_cacheable")),
    EXECUTED_NOT_CACHEABLE("Executed not cacheable", d -> taskCount(d, "executed_not_cacheable")),
    EXECUTED_UNKNOWN_CACHEABILITY("Executed unknown cacheability", d -> taskCount(d, "executed_unknown_cacheability")),
    LIFECYCLE("Lifecycle", d -> taskCount(d, "lifecycle")),
    NO_SOURCE("No Source", d -> taskCount(d, "no-source")),
    SKIPPED("Skipped", d -> taskCount(d, "skipped"))
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

    private static String taskCount(BuildValidationData data, String avoidanceOutcome) {
        if (data.getTasksByAvoidanceOutcome().containsKey(avoidanceOutcome)) {
            return data.getTasksByAvoidanceOutcome().get(avoidanceOutcome).toString();
        }
        return "";
    }

    private static String totalAvoidedFromCache(BuildValidationData data) {
        Map<String, Long> tasksByOutcome = data.getTasksByAvoidanceOutcome();
        if (!(tasksByOutcome.containsKey("avoided_from_local_cache") || tasksByOutcome.containsKey("avoided_from_remote_cache"))) {
            return "";
        }
        long fromLocalCache = tasksByOutcome.getOrDefault("avoided_from_local_cache", 0L);
        long fromRemoteCache = tasksByOutcome.getOrDefault("avoided_from_remote_cache", 0L);
        return Long.toString(fromLocalCache + fromRemoteCache);
    }
}
