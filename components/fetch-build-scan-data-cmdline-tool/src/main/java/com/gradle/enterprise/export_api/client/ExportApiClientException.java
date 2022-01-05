package com.gradle.enterprise.export_api.client;

import java.net.MalformedURLException;
import java.net.URL;

public class ExportApiClientException extends RuntimeException {
    public ExportApiClientException() {
    }

    public ExportApiClientException(String message) {
        super(message);
    }

    public ExportApiClientException(String message, Throwable cause) {
        super(message, cause);
    }

    public ExportApiClientException(Throwable cause) {
        super(cause);
    }

    public ExportApiClientException(String message, Throwable cause, boolean enableSuppression, boolean writableStackTrace) {
        super(message, cause, enableSuppression, writableStackTrace);
    }

    protected static final URL buildScanUrl(URL gradleEnterpriseServerUrl, String buildScanId) {
        try {
            return new URL(gradleEnterpriseServerUrl, "/s/" + buildScanId);
        } catch (MalformedURLException e) {
            throw new RuntimeException(e.getMessage(), e);
        }
    }
}
