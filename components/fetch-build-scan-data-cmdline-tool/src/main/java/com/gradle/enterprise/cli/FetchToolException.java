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

    /**
     * Constructs a new {@code FetchToolException} with the specified detail message and cause.
     *
     * @param message the detail message
     * @param cause the cause
     */
    public FetchToolException(String message, Throwable cause) {
        super(message, cause);
    }
}
