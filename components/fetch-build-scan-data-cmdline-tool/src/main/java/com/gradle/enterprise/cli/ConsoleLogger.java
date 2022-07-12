package com.gradle.enterprise.cli;

import picocli.CommandLine;

import java.io.PrintStream;

public class ConsoleLogger {
    
    private final PrintStream out;
    private final CommandLine.Help.ColorScheme colorScheme;
    private final boolean debugEnabled;

    private boolean lastStatementIncludedNewline = true;

    public ConsoleLogger(PrintStream out, CommandLine.Help.ColorScheme colorScheme, boolean debugEnabled) {
        this.out = out;
        this.colorScheme = colorScheme;
        this.debugEnabled = debugEnabled;
    }

    public void info(String message, Object... args) {
        info(String.format(message + "%n", args));
    }

    public void info(String message) {
        out.println(message);
        lastStatementIncludedNewline = true;
    }

    public void infoNoNewline(String message) {
        out.print(message);
        lastStatementIncludedNewline = false;
    }

    public void debug(String message, Object... args) {
        debug(String.format(message, args));
    }

    public void debug(String message) {
        if (debugEnabled) {
            out.println(colorScheme.text("@|faint " + message + "|@"));
            lastStatementIncludedNewline = true;
        }
    }

    public void debug(Throwable t) {
        debug(colorScheme.stackTraceText(t).plainString());
    }

    public void error(String message, Object... args) {
        error(String.format(message, args));
    }

    public void error(String message) {
        if (!lastStatementIncludedNewline) {
            out.println();
        }
        out.println(colorScheme.errorText(message));
        lastStatementIncludedNewline = true;
    }

    public void error(Throwable t) {
        error(colorScheme.stackTraceText(t).plainString());
    }

    public boolean isDebugEnabled() {
        return debugEnabled;
    }

}
