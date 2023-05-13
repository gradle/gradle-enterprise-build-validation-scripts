package com.gradle.enterprise.loader;

import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;

import java.net.URI;
import java.net.URISyntaxException;
import java.net.URL;

import static org.junit.jupiter.api.Assertions.*;

class BuildScanUrlUtilsTest {

    @ParameterizedTest
    @ValueSource(strings = {
            "https://ge.example.com/s/7slcdesxr2xnw",
            "https://ge.example.com/s/7slcdesxr2xnw/",
            "https://ge.example.com/s/7slcdesxr2xnw/timeline",
            "https://ge.example.com/s/7slcdesxr2xnw/console-log?page=1",
            "https://ge.example.com/s/7slcdesxr2xnw/projects#:foo-service"
    })
    void validBuildScanUrlsAreCorrectlyParsed(String givenBuildScanUrl) throws URISyntaxException {
        URL buildScanUrl = BuildScanUrlUtils.toBuildScanURL(new URI(givenBuildScanUrl));
        assertAll(
            () -> assertEquals(new URL("https://ge.example.com"), BuildScanUrlUtils.extractBaseUrl(buildScanUrl)),
            () -> assertEquals("7slcdesxr2xnw", BuildScanUrlUtils.extractBuildScanId(buildScanUrl))
        );
    }

    @ParameterizedTest
    @ValueSource(strings = {
            "https://ge.example.com",
            "https://ge.example.com/",
            "https://ge.example.com/s",
            "https://ge.example.com/s/",
            "https://ge.example.com/S/",
            "https://ge.example.com/S/7slcdesxr2xnw",
    })
    void invalidBuildScanUrlsThrowException(String givenBuildScanUrl) throws URISyntaxException {
        URL buildScanUrl = BuildScanUrlUtils.toBuildScanURL(new URI(givenBuildScanUrl));
        assertThrows(IllegalArgumentException.class, () -> BuildScanUrlUtils.extractBuildScanId(buildScanUrl));
    }
}
