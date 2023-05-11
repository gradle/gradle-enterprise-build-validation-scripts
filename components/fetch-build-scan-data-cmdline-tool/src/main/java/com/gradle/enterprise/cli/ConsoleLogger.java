package com.gradle.enterprise.cli;

import com.gradle.enterprise.loader.Logger;
import picocli.CommandLine;

import java.io.PrintStream;

public class ConsoleLogger implements Logger {

    private final PrintStream out;
    private final CommandLine.Help.ColorScheme colorScheme;
    private final boolean debugEnabled;

    private boolean lastStatementIncludedNewline = true;

    public ConsoleLogger(PrintStream out, CommandLine.Help.ColorScheme colorScheme, boolean debugEnabled) {
        this.out = out;
        this.colorScheme = colorScheme;
        this.debugEnabled = debugEnabled;
    }

    @Override
    public void info(String message, Object... args) {
        info(String.format(message, args));
    }

    @Override
    public void info(String message) {
        out.println(message);
        lastStatementIncludedNewline = true;
    }

    @Override
    public void debug(String message) {
        if (debugEnabled) {
            out.println(colorScheme.text("@|faint " + message + "|@"));
            lastStatementIncludedNewline = true;
        }
    }

    @Override
    public void debug(Throwable t) {
        debug(colorScheme.stackTraceText(t).plainString());
    }

    @Override
    public void error(String message, Object... args) {
        error(String.format(message, args));
    }

    @Override
    public void error(String message) {
        if (!lastStatementIncludedNewline) {
            out.println();
        }
        out.println(colorScheme.errorText(message));
        lastStatementIncludedNewline = true;
    }

    @Override
    public void error(Throwable t) {
        error(colorScheme.stackTraceText(t).plainString());
    }

    @Override
    public boolean isDebugEnabled() {
        return debugEnabled;
    }

}
