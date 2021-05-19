package com.gradle.enterprise;

import java.net.URL;

public class BuildScanNotFound extends FetchBuildValidationDataException {
    public BuildScanNotFound(String buildScanId, URL gradleEnterpriseServer) {
        super(String.format("Build scan %s was not found.%nVerify the build scan exists and that you have the" +
                " 'Access build data via the Export API' permission.",
            buildScanUrl(gradleEnterpriseServer, buildScanId)));
    }
}
