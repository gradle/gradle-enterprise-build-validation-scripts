package com.gradle.enterprise.api.client;

import java.net.MalformedURLException;
import java.net.URL;

public class ApiClientException extends RuntimeException {
    public ApiClientException() {
    }

    public ApiClientException(String message) {
        super(message);
    }

    public ApiClientException(String message, Throwable cause) {
        super(message, cause);
    }

    public ApiClientException(Throwable cause) {
        super(cause);
    }

    public ApiClientException(String message, Throwable cause, boolean enableSuppression, boolean writableStackTrace) {
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
