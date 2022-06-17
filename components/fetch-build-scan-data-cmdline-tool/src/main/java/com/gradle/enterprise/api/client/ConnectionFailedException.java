package com.gradle.enterprise.api.client;

import java.net.URL;

public class ConnectionFailedException extends ApiClientException {

    public ConnectionFailedException(String buildScanId, URL gradleEnterpriseServer, Throwable cause) {
        super(String.format("Unable to connect to %s in order to fetch build scan %s: %s", gradleEnterpriseServer, buildScanId, cause.getMessage()), cause);
    }

    public ConnectionFailedException(String buildScanId, URL gradleEnterpriseServer, ApiException cause) {
        super(String.format("Unable to connect to %s in order to fetch build scan %s.", gradleEnterpriseServer, buildScanId), cause);
    }

}
