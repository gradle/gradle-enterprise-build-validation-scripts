package com.gradle.enterprise;

import java.net.URL;

public class UnexpectedExceptionWhileFetchingBuildScan extends FetchBuildValidationDataException {
    public UnexpectedExceptionWhileFetchingBuildScan(String buildScanId, URL gradleEnterpriseServer, Throwable cause) {
        super(String.format("An unexpected error occurred while fetching build scan %s from %s: %s",
            buildScanId, gradleEnterpriseServer.getHost(), cause.getMessage()),
            cause);
    }
}
