package com.gradle.enterprise;

import java.util.Arrays;
import java.util.Comparator;
import java.util.List;
import java.util.function.Function;
import java.util.stream.Collectors;

public enum Fields {
    ROOT_PROJECT_NAME(0, "Root Project Name", BuildValidationData::getRootProjectName),
    GE_SERVER(1, "Gradle Enterprise Server", d -> toStringSafely(d.getGradleEnterpriseServerUrl())),
    BUILD_SCAN(2, "Build Scan", d -> toStringSafely(d.getBuildScanUrl())),
    BUILD_SCAN_ID(3, "Build Scan ID", BuildValidationData::getBuildScanId),
    GIT_URL(4, "Git URL", BuildValidationData::getGitUrl),
    GIT_BRANCH(5, "Git Branch", BuildValidationData::getGitBranch),
    GIT_COMMIT_ID(6, "Git Commit ID", BuildValidationData::getGitCommitId),
    REQUESTED_TASKS(7, "Requested Tasks", d -> String.join(" ", d.getRequestedTasks())),
    BUILD_OUTCOME(8, "Build Outcome", BuildValidationData::getBuildOutcome),
    REMOTE_BUILD_CACHE_URL(9, "Remote Build Cache URL", d -> toStringSafely(d.getRemoteBuildCacheUrl())),
    REMOTE_BUILD_CACHE_SHARD(10, "Remote Build Cache Shard", BuildValidationData::getRemoteBuildCacheShard),
    AVOIDED_UP_TO_DATE(11, "Avoided Up To Date", d -> taskCount(d, "avoided_up_to_date")),
    AVOIDED_FROM_CACHE(12, "Avoided from cache", d -> {
        long fromLocalCache = d.getTasksByAvoidanceOutcome().getOrDefault("avoided_from_local_cache", 0L);
        long fromRemoteCache = d.getTasksByAvoidanceOutcome().getOrDefault("avoided_from_remote_cache", 0L);
        return Long.toString(fromLocalCache + fromRemoteCache);
    }),
    AVOIDED_FROM_LOCAL_CACHE(13, "Avoided from local cache", d -> taskCount(d, "avoided_from_local_cache")),
    AVOIDED_FROM_REMOTE_CACHE(14, "Avoided from remote cache", d -> taskCount(d, "avoided_from_remote_cache")),
    EXECUTED_CACHABLE(15, "Executed cacheable", d -> taskCount(d, "executed_cacheable")),
    EXECUTED_NOT_CACHABLE(16, "Executed not cacheable", d -> taskCount(d, "executed_not_cacheable")),
    EXECUTED_UNKNOWN_CACHEABILITY(17, "Executed unknown cacheability", d -> taskCount(d, "executed_unknown_cacheability")),
    LIFECYCLE(18, "Lifecycle", d -> taskCount(d, "lifecycle")),
    NO_SOURCE(19, "No Source", d -> taskCount(d, "no-source")),
    SKIPPED(20, "Skipped", d -> taskCount(d, "skipped"))
    ;

    private static final Comparator<Fields> ORDER_COMPARATOR = Comparator.comparingInt(field -> field.order);

    public final int order;
    public final String label;
    public final Function<BuildValidationData, String> value;

    Fields(int order, String label, Function<BuildValidationData, String> value) {
        this.order = order;
        this.label = label;
        this.value = value;
    }

    public static List<Fields> ordered() {
        return Arrays.stream(Fields.values()).sorted(ORDER_COMPARATOR).collect(Collectors.toList());
    }

    private static String toStringSafely(Object object) {
        if (object == null) {
            return "";
        }
        return object.toString();
    }

    private static String taskCount(BuildValidationData buildValidationData, String avoidanceOutcome) {
        return buildValidationData.getTasksByAvoidanceOutcome().getOrDefault(avoidanceOutcome, 0L).toString();
    }
}
