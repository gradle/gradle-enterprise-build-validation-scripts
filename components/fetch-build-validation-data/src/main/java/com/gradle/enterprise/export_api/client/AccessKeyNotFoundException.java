package com.gradle.enterprise.export_api.client;

import java.net.URL;

public class AccessKeyNotFoundException extends ExportApiClientException {
    public AccessKeyNotFoundException(URL buildScanUrl) {
        super(String.format("Unable to find an access key for %s.",
            buildScanUrl.getHost()));
    }

    public AccessKeyNotFoundException(URL buildScanUrl, Throwable cause) {
        super(String.format("An error occurred while trying to find an access key for %s:%n%s.",
            buildScanUrl.getHost(), cause.getMessage()), cause);
    }
}
