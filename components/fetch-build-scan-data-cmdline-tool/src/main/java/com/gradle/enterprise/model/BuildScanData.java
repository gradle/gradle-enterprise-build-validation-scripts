package com.gradle.enterprise.model;

import java.math.BigDecimal;
import java.net.MalformedURLException;
import java.net.URL;
import java.time.Duration;
import java.util.List;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class BuildScanData {
    private static final Pattern REMOTE_BUILD_CACHE_SHARD_PATTERN = Pattern.compile(".*/cache/(.+)$");

    private final int runNum;
    private final String rootProjectName;
    private final String buildScanId;
    private final URL gradleEnterpriseServerUrl;
    private final String gitUrl;
    private final String gitBranch;
    private final String gitCommitId;
    private final List<String> requestedTasks;
    private final String buildOutcome;
    private final URL remoteBuildCacheUrl;
    private final Map<String, TaskExecutionSummary> tasksByAvoidanceOutcome;
    private final Duration buildTime;
    private final BigDecimal serializationFactor;

    public BuildScanData(
        int runNum,
        String rootProjectName,
        String buildScanId,
        URL gradleEnterpriseServerUrl,
        String gitUrl,
        String gitBranch,
        String gitCommitId,
        List<String> requestedTasks,
        String buildOutcome,
        URL remoteBuildCacheUrl,
        Map<String, TaskExecutionSummary> tasksByAvoidanceOutcome,
        Duration buildTime,
        BigDecimal serializationFactor) {
        this.runNum = runNum;
        this.rootProjectName = rootProjectName;
        this.buildScanId = buildScanId;
        this.gradleEnterpriseServerUrl = gradleEnterpriseServerUrl;
        this.gitUrl = gitUrl;
        this.gitBranch = gitBranch;
        this.gitCommitId = gitCommitId;
        this.requestedTasks = requestedTasks;
        this.buildOutcome = buildOutcome;
        this.remoteBuildCacheUrl = remoteBuildCacheUrl;
        this.tasksByAvoidanceOutcome = tasksByAvoidanceOutcome;
        this.buildTime = buildTime;
        this.serializationFactor = serializationFactor;
    }

    public int runNum() {
        return runNum;
    }

    public String getRootProjectName() {
        return rootProjectName;
    }

    public String getBuildScanId() {
        return buildScanId;
    }

    public URL getBuildScanUrl() {
        try {
            return new URL(gradleEnterpriseServerUrl, "/s/" + buildScanId);
        } catch (MalformedURLException e) {
            throw new RuntimeException(e.getMessage(), e);
        }
    }

    public URL getGradleEnterpriseServerUrl() {
        return gradleEnterpriseServerUrl;
    }

    public String getGitUrl() {
        return gitUrl;
    }

    public boolean isGitUrlFound() {
        return isFound(gitUrl);
    }

    public String getGitBranch() {
        return gitBranch;
    }

    public boolean isGitBranchFound() {
        return isFound(gitBranch);
    }

    public String getGitCommitId() {
        return gitCommitId;
    }

    public boolean isGitCommitIdFound() {
        return isFound(gitCommitId);
    }

    public List<String> getRequestedTasks() {
        return requestedTasks;
    }

    public String getBuildOutcome() {
        return buildOutcome;
    }

    public URL getRemoteBuildCacheUrl() {
        return remoteBuildCacheUrl;
    }

    public String getRemoteBuildCacheShard() {
        if (remoteBuildCacheUrl == null) {
            return "";
        }
        Matcher matcher = REMOTE_BUILD_CACHE_SHARD_PATTERN.matcher(remoteBuildCacheUrl.getPath());
        if (matcher.matches()) {
            return matcher.group(1);
        }
        return "";
    }

    private static boolean isFound(String value) {
        return !value.isEmpty();
    }

    public Map<String, TaskExecutionSummary> getTasksByAvoidanceOutcome() {
        return tasksByAvoidanceOutcome;
    }

    public TaskExecutionSummary getExecutedCacheableSummary() {
        return tasksByAvoidanceOutcome.get("executed_cacheable");
    }

    public Duration getBuildTime() {
        return buildTime;
    }

    public BigDecimal getSerializationFactor() {
        return serializationFactor;
    }

}
