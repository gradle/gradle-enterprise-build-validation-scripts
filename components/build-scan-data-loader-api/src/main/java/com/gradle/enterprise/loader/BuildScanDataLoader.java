package com.gradle.enterprise.loader;

public interface BuildScanDataLoader {

    String loadDataForGradle();

    String loadDataForMaven();

}
