package com.gradle.enterprise;

import com.gradle.enterprise.cli.FetchBuildValidationDataCommand;
import com.gradle.enterprise.cli.PrintExceptionHandler;
import picocli.CommandLine;
import picocli.CommandLine.Help.ColorScheme;

public class Main {
    public static void main(String[] args) {
        System.setProperty("picocli.disable.closures", "true");  // improves startup time
        ColorScheme colorScheme = CommandLine.Help.defaultColorScheme(CommandLine.Help.Ansi.AUTO);
        CommandLine cmdLine = new CommandLine(new FetchBuildValidationDataCommand(colorScheme))
            .setExecutionExceptionHandler(new PrintExceptionHandler())
            .setColorScheme(colorScheme);

        System.exit(cmdLine.execute(args));
    }
}
