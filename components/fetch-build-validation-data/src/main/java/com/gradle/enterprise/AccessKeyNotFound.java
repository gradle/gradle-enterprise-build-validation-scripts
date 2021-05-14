package com.gradle.enterprise;

import java.net.URL;

public class AccessKeyNotFound extends FetchBuildValidationDataException {
    public AccessKeyNotFound(URL buildScanUrl) {
        super(String.format("Unable to find an access key for %s.",
            buildScanUrl.getHost()));
    }

    public AccessKeyNotFound(URL buildScanUrl, Throwable cause) {
        super(String.format("An error occurred while trying to find an access key for %s: %s.",
            buildScanUrl.getHost(), cause.getMessage()), cause);
    }
}
