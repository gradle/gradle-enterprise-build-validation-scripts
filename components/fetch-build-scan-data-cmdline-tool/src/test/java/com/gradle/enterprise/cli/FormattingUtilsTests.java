package com.gradle.enterprise.cli;

import org.junit.jupiter.api.Test;

import java.time.Duration;

import static org.junit.jupiter.api.Assertions.assertAll;
import static org.junit.jupiter.api.Assertions.assertEquals;

public class FormattingUtilsTests {

    @Test
    void durationsAreFormattedCorrectly() {
        assertAll(
                () -> assertDurationFormatting(          "0.009s", 9L),
                () -> assertDurationFormatting(          "0.099s", 99L),
                () -> assertDurationFormatting(          "0.999s", 999L),
                () -> assertDurationFormatting(          "9.999s", 9999L),
                () -> assertDurationFormatting(      "1m 39.999s", 99999L),
                () -> assertDurationFormatting(     "16m 39.999s", 999999L),
                () -> assertDurationFormatting(  "2h 46m 39.999s", 9999999L),
                () -> assertDurationFormatting( "27h 46m 39.999s", 99999999L),

                () -> assertDurationFormatting(         "-0.009s", -9L),
                () -> assertDurationFormatting(         "-0.099s", -99L),
                () -> assertDurationFormatting(         "-0.999s", -999L),
                () -> assertDurationFormatting(         "-9.999s", -9999L),
                () -> assertDurationFormatting(     "-1m 39.999s", -99999L),
                () -> assertDurationFormatting(    "-16m 39.999s", -999999L),
                () -> assertDurationFormatting( "-2h 46m 39.999s", -9999999L),
                () -> assertDurationFormatting("-27h 46m 39.999s", -99999999L)
        );
    }

    private static void assertDurationFormatting(String expected, Long millis) {
        assertEquals(expected, FormattingUtils.formatDuration(Duration.ofMillis(millis)));
    }
}
