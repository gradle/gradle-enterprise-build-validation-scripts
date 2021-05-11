package com.gradle.enterprise;

import java.net.URL;
import java.util.List;

public class BuildValidationData {
    private final String buildScanId;
    private final URL gradleEnterpriseServerUrl;
    private final String gitCommitId;
    private final List<String> requestedTasks;
    private final Boolean buildSuccessful;

    public BuildValidationData(String buildScanId, URL gradleEnterpriseServerUrl, String gitCommitId, List<String> requestedTasks, Boolean buildSuccessful) {
        this.buildScanId = buildScanId;
        this.gradleEnterpriseServerUrl = gradleEnterpriseServerUrl;
        this.gitCommitId = gitCommitId;
        this.requestedTasks = requestedTasks;
        this.buildSuccessful = buildSuccessful;
    }

    public String getBuildScanId() {
        return buildScanId;
    }

    public URL getGradleEnterpriseServerUrl() {
        return gradleEnterpriseServerUrl;
    }

    public String getGitCommitId() {
        return gitCommitId;
    }

    public List<String> getRequestedTasks() {
        return requestedTasks;
    }

    public Boolean getBuildSuccessful() {
        return buildSuccessful;
    }
}
