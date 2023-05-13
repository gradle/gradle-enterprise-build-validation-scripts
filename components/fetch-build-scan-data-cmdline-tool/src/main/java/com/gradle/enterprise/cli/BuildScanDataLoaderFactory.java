package com.gradle.enterprise.cli;

import com.gradle.enterprise.loader.BuildScanDataLoader;
import com.gradle.enterprise.loader.Logger;
import com.gradle.enterprise.loader.offline.OfflineBuildScanDataLoader;
import com.gradle.enterprise.loader.online.OnlineBuildScanDataLoader;

import java.net.URI;
import java.nio.file.Path;

public class BuildScanDataLoaderFactory {
    private BuildScanDataLoaderFactory() {

    }

    public static BuildScanDataLoader createBuildScanDataLoader(URI resource, Path licenseFile, Logger logger) {
        return resource.getScheme().equals("file")
            ? OfflineBuildScanDataLoader.newInstance(licenseFile)
            : new OnlineBuildScanDataLoader(logger);
    }
}
