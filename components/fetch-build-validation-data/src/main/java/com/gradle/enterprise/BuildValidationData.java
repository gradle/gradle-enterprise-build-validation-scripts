package com.gradle.enterprise;

import java.net.URL;
import java.util.List;

public class BuildValidationData {
    private final String buildScanId;
    private final URL gradleEnterpriseServerUrl;
    private final String commitId;
    private final List<String> requestedTasks;
    private final Boolean buildSuccessful;

    public BuildValidationData(String buildScanId, URL gradleEnterpriseServerUrl, String commitId, List<String> requestedTasks, Boolean buildSuccessful) {
        this.buildScanId = buildScanId;
        this.gradleEnterpriseServerUrl = gradleEnterpriseServerUrl;
        this.commitId = commitId;
        this.requestedTasks = requestedTasks;
        this.buildSuccessful = buildSuccessful;
    }

    public String getBuildScanId() {
        return buildScanId;
    }

    public URL getGradleEnterpriseServerUrl() {
        return gradleEnterpriseServerUrl;
    }

    public String getCommitId() {
        return commitId;
    }

    public List<String> getRequestedTasks() {
        return requestedTasks;
    }

    public Boolean getBuildSuccessful() {
        return buildSuccessful;
    }
}
