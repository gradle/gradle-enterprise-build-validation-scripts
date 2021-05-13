package com.gradle.enterprise;

import java.net.URL;

public class InterruptedWhileFetchingBuildScan extends FetchBuildValidationDataException {
    public InterruptedWhileFetchingBuildScan(String buildScanId, URL gradleEnterpriseServer, InterruptedException cause) {
        super(String.format("Process interrupted while fetching build scan %s from %s.",
            buildScanId, gradleEnterpriseServer.getHost()),
            cause);
    }
}
