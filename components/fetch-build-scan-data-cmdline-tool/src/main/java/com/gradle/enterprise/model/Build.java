package com.gradle.enterprise.model;

import java.net.URL;

public class Build {
    private final int runNum;

    private final URL buildScanUrl;

    public Build(int runNum, URL buildScanUrl) {
        this.buildScanUrl = buildScanUrl;
        this.runNum = runNum;
    }

    public int runNum() {
        return runNum;
    }

    public URL buildScanUrl() {
        return buildScanUrl;
    }
}
