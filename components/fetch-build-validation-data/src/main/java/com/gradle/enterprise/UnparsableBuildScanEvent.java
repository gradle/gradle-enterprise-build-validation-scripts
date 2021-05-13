package com.gradle.enterprise;

import okhttp3.Response;

import java.net.URL;

public class UnparsableBuildScanEvent extends FetchBuildValidationDataException {
    public UnparsableBuildScanEvent(String buildScanId, URL gradleEnterpriseServer, String data, Throwable cause) {
        super(String.format("Ah error occurred while trying to parse an event returned from %s for build scan %s: %s. Event data: %s",
            gradleEnterpriseServer, buildScanId, cause.getMessage(), data),
            cause);
    }
}
