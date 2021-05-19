package com.gradle.enterprise.export_api.client;

import java.net.URL;

public class UnparsableBuildScanEventException extends ExportApiClientException {
    public UnparsableBuildScanEventException(String buildScanId, URL gradleEnterpriseServer, String data, Throwable cause) {
        super(String.format("Ah error occurred while trying to parse an event returned for build scan %s:%n%s%nEvent data: %s",
            buildScanUrl(gradleEnterpriseServer, buildScanId), cause.getMessage(), data),
            cause);
    }
}
