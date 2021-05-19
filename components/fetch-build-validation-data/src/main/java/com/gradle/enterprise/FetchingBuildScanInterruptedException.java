package com.gradle.enterprise;

import java.net.URL;

public class FetchingBuildScanInterruptedException extends FetchBuildValidationDataException {
    public FetchingBuildScanInterruptedException(String buildScanId, URL gradleEnterpriseServer, InterruptedException cause) {
        super(String.format("Process interrupted while fetching build scan %s.",
            buildScanUrl(gradleEnterpriseServer, buildScanId)), cause);
    }
}
