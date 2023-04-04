package com.gradle.enterprise.cli;

import java.time.Duration;
import java.util.Locale;

final class FormattingUtils {

    private FormattingUtils() {
    }

    static String formatDuration(Duration duration) {
        long hours = duration.toHours();
        long minutes = duration.minusHours(hours).toMinutes();
        double seconds = duration.minusHours(hours).minusMinutes(minutes).toMillis() / 1000d;

        StringBuilder s = new StringBuilder();
        if (hours != 0) {
            s.append(hours).append("h ");
        }
        if (minutes != 0) {
            s.append(minutes).append("m ");
        }
        s.append(String.format(Locale.ROOT, "%.3fs", seconds));

        return s.toString().trim();
    }
}
