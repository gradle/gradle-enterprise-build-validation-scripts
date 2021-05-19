package com.gradle.enterprise;

import okhttp3.Response;

import java.net.URL;

public class UnexpectedResponse extends FetchBuildValidationDataException {
    public UnexpectedResponse(String buildScanId, URL gradleEnterpriseServer, Response response) {
        super(String.format("Encountered an unexpected response while fetching build scan %s.%n%s",
            buildScanUrl(gradleEnterpriseServer, buildScanId), response));
    }
}
