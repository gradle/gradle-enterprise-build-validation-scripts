package com.gradle.enterprise.model;

import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;

import java.net.URL;

import static org.junit.jupiter.api.Assertions.assertAll;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

class NumberedBuildScanTests {

    @ParameterizedTest
    @ValueSource(strings = {
            "https://ge.example.com/s/7slcdesxr2xnw",
            "https://ge.example.com/s/7slcdesxr2xnw/",
            "https://ge.example.com/s/7slcdesxr2xnw/timeline",
            "https://ge.example.com/s/7slcdesxr2xnw/console-log?page=1",
            "https://ge.example.com/s/7slcdesxr2xnw/projects#:foo-service"
    })
    void validBuildScanUrlsAreCorrectlyParsed(String buildScanUrl) {
        final NumberedBuildScan numberedBuildScan = NumberedBuildScan.parse("0," + buildScanUrl);
        assertAll(
                () -> assertEquals(new URL("https://ge.example.com"), numberedBuildScan.baseUrl()),
                () -> assertEquals("7slcdesxr2xnw", numberedBuildScan.buildScanId())
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
    void invalidBuildScanUrlsThrowException(String buildScanUrl) {
        assertThrows(IllegalArgumentException.class, () -> NumberedBuildScan.parse("0," + buildScanUrl));
    }
}
