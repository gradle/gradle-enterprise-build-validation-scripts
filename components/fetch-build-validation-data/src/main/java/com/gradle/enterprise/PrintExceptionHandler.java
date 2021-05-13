package com.gradle.enterprise;

import picocli.CommandLine;

public class PrintExceptionHandler implements CommandLine.IExecutionExceptionHandler {

    @Override
    public int handleExecutionException(Exception e, CommandLine cmd, CommandLine.ParseResult parseResult) throws Exception {
        cmd.getErr().println(cmd.getColorScheme().errorText(e.getMessage()));

        int returnCode = cmd.getCommandSpec().exitCodeOnExecutionException();
        if (cmd.getExitCodeExceptionMapper() != null) {
            returnCode = cmd.getExitCodeExceptionMapper().getExitCode(e);
        }
        return returnCode;
    }
}
