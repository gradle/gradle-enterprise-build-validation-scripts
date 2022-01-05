package com.gradle.enterprise.export_api.client;

import okhttp3.Request;
import okhttp3.Response;

import java.net.URL;

public class AuthenticationFailedException extends FailedRequestException {
    public AuthenticationFailedException(String buildScanId, URL gradleEnterpriseServer, Request request, Response response) {
        super(String.format("Failed to authenticate while attempting to fetch build scan %s.",
            buildScanUrl(gradleEnterpriseServer, buildScanId)),
            request, response);
    }
}
