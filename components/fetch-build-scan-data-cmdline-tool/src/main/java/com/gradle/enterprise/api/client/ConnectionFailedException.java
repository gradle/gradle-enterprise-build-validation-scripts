package com.gradle.enterprise.api.client;

import java.net.URL;

public class ConnectionFailedException extends ApiClientException {

    public ConnectionFailedException(URL gradleEnterpriseServer, String buildScanId, Throwable cause) {
        super(String.format("Unable to connect to %s in order to fetch build scan %s: %s", gradleEnterpriseServer, buildScanId, cause.getMessage()), cause);
    }

    public ConnectionFailedException(URL gradleEnterpriseServer, String buildScanId, ApiException cause) {
        super(String.format("Unable to connect to %s in order to fetch build scan %s", gradleEnterpriseServer, buildScanId), cause);
    }

}
