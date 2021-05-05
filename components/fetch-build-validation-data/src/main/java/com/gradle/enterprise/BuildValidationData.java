package com.gradle.enterprise;

import java.util.List;

public class BuildValidationData {
    private final String commitId;
    private final List<String> requestedTasks;
    private final Boolean buildSuccessful;

    public BuildValidationData(String commitId, List<String> requestedTasks, Boolean buildSuccessful) {
        this.commitId = commitId;
        this.requestedTasks = requestedTasks;
        this.buildSuccessful = buildSuccessful;
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
