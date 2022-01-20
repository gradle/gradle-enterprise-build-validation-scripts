package com.gradle.enterprise;

import com.gradle.enterprise.api.client.ApiClient;
import picocli.CommandLine;
import picocli.CommandLine.Help.ColorScheme;

public class Main {
    public static void main(String[] args) {
        ColorScheme colorScheme = CommandLine.Help.defaultColorScheme(CommandLine.Help.Ansi.AUTO);
        int exitCode = new CommandLine(new FetchBuildValidationDataCommand(colorScheme))
            .setExecutionExceptionHandler(new PrintExceptionHandler())
            .setColorScheme(colorScheme)
            .execute(args);
        System.exit(exitCode);
    }
}
