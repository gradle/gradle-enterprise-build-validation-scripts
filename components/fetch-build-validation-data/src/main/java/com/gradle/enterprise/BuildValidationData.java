package com.gradle.enterprise;

import java.net.MalformedURLException;
import java.net.URL;
import java.util.List;

public class BuildValidationData {
    private final String buildScanId;
    private final URL gradleEnterpriseServerUrl;
    private final String gitUrl;
    private final String gitBranch;
    private final String gitCommitId;
    private final List<String> requestedTasks;
    private final Boolean buildSuccessful;

    public BuildValidationData(String buildScanId, URL gradleEnterpriseServerUrl, String gitUrl, String gitBranch, String gitCommitId, List<String> requestedTasks, Boolean buildSuccessful) {
        this.buildScanId = buildScanId;
        this.gradleEnterpriseServerUrl = gradleEnterpriseServerUrl;
        this.gitUrl = gitUrl;
        this.gitBranch = gitBranch;
        this.gitCommitId = gitCommitId;
        this.requestedTasks = requestedTasks;
        this.buildSuccessful = buildSuccessful;
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

    public String getGitBranch() {
        return gitBranch;
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
