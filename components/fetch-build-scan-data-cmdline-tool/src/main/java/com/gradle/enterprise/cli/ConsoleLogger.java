package com.gradle.enterprise.cli;

import picocli.CommandLine;

import java.io.PrintStream;

public class ConsoleLogger {
    private final PrintStream out;
    private final CommandLine.Help.ColorScheme colorScheme;
    private final boolean debugEnabled;

    public ConsoleLogger(PrintStream out, CommandLine.Help.ColorScheme colorScheme, boolean debugEnabled) {
        this.out = out;
        this.colorScheme = colorScheme;
        this.debugEnabled = debugEnabled;
    }

    public void info(String message) {
        out.println(message);
    }

    public void infoNoNewline(String message) {
        out.print(message);
    }
    public void info(String message, Object... args) {
        out.printf(message, args);
    }

    public void debug(String message) {
        if (debugEnabled) {
            out.println(colorScheme.text("@|faint " + message + "|@"));
        }
    }

    public void debug(Throwable t) {
        debug(colorScheme.stackTraceText(t).plainString());
    }

    public void error(String message) {
        out.println(colorScheme.errorText(message));
    }

    public void error(Throwable t) {
        error(colorScheme.stackTraceText(t).plainString());
    }

    public boolean isDebugEnabled() {
        return debugEnabled;
    }
}
