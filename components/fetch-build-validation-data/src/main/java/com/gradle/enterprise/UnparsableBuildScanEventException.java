package com.gradle.enterprise;

import okhttp3.Response;

import java.net.URL;

public class UnparsableBuildScanEventException extends FetchBuildValidationDataException {
    public UnparsableBuildScanEventException(String buildScanId, URL gradleEnterpriseServer, String data, Throwable cause) {
        super(String.format("Ah error occurred while trying to parse an event returned for build scan %s:%n%s%nEvent data: %s",
            buildScanUrl(gradleEnterpriseServer, buildScanId), cause.getMessage(), data),
            cause);
    }
}
