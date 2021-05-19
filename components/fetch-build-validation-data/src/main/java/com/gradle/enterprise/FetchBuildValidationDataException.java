package com.gradle.enterprise;

import java.net.MalformedURLException;
import java.net.URL;

public class FetchBuildValidationDataException extends RuntimeException {
    public FetchBuildValidationDataException() {
    }

    public FetchBuildValidationDataException(String message) {
        super(message);
    }

    public FetchBuildValidationDataException(String message, Throwable cause) {
        super(message, cause);
    }

    public FetchBuildValidationDataException(Throwable cause) {
        super(cause);
    }

    public FetchBuildValidationDataException(String message, Throwable cause, boolean enableSuppression, boolean writableStackTrace) {
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
