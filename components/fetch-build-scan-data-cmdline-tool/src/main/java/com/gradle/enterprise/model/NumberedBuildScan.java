package com.gradle.enterprise.model;

import com.gradle.enterprise.cli.BadBuildScanUrlException;

import java.net.MalformedURLException;
import java.net.URL;

public class NumberedBuildScan {
    private final int runNum;
    private final URL buildScanUrl;

    public NumberedBuildScan(int runNum, URL buildScanUrl) {
        this.runNum = runNum;
        this.buildScanUrl = buildScanUrl;
    }

    public static NumberedBuildScan parse(String runNumAndBuildScanUrl) {
        String[] parts = runNumAndBuildScanUrl.split(",");
        String runNum = parts[0];
        String buildScanUrl = parts[1];
        try {
            return new NumberedBuildScan(Integer.parseInt(runNum), new URL(buildScanUrl));
        } catch (MalformedURLException e) {
            throw new BadBuildScanUrlException(buildScanUrl, e);
        }
    }

    public int runNum() {
        return runNum;
    }

    public URL buildScanUrl() {
        return buildScanUrl;
    }
}
