package com.gradle.enterprise.cli;

/**
 * Exception thrown when any error occurs while fetching a Build Scan.
 */
public class FetchToolException extends RuntimeException {

    /**
     * Constructs a new {@code FetchToolException} with the specified detail message.
     *
     * @param message the detail message
     */
    public FetchToolException(String message) {
        super(message);
    }
}
