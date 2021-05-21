package com.gradle.enterprise.export_api.client;

import okhttp3.Request;
import okhttp3.Response;

import java.net.URL;

public class BuildScanNotFoundException extends FailedRequestException {
    public BuildScanNotFoundException(String buildScanId, URL gradleEnterpriseServer, Request request, Response response) {
        super(String.format("Build scan %s was not found.%nVerify the build scan exists and you have been granted the permission" +
                " 'Access build data via the Export API'.", buildScanUrl(gradleEnterpriseServer, buildScanId)),
            request, response);
    }
}
