package com.gradle.enterprise.network;

import java.nio.file.Path;

public class FailedToLoadNetworkSettingsException extends RuntimeException {

    public FailedToLoadNetworkSettingsException(Path networkSettingsFile, Throwable cause) {
        super(String.format("Failed to load network settings from %s: %s: %s",
            networkSettingsFile.toAbsolutePath(),
            cause.getClass().getSimpleName(),
            cause.getMessage()
        ), cause);
    }

}
