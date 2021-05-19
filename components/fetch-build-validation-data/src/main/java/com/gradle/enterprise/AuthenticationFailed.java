package com.gradle.enterprise;

import okhttp3.Response;

import java.net.URL;

public class AuthenticationFailed extends FetchBuildValidationDataException {
    public AuthenticationFailed(String buildScanId, URL gradleEnterpriseServer) {
        super(String.format("Failed to authenticate while attempting to fetch build scan %s.",
            buildScanUrl(gradleEnterpriseServer, buildScanId)));
    }
}
