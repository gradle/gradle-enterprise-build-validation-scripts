package com.gradle.enterprise;

import picocli.CommandLine;

public class Main {
    public static void main(String[] args) {
        var colorScheme = CommandLine.Help.defaultColorScheme(CommandLine.Help.Ansi.AUTO);
        int exitCode = new CommandLine(new FetchBuildValidationDataCommand(colorScheme))
            .setExecutionExceptionHandler(new PrintExceptionHandler())
            .setColorScheme(colorScheme)
            .execute(args);
        System.exit(exitCode);
    }
}
