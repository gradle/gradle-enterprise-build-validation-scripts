package com.gradle.enterprise.api.client;

/**
 * Exception thrown when an error occurs while fetching a Build Scan.
 */
public abstract class ApiClientException extends RuntimeException {

    /**
     * Constructs a new {@code ApiClientException} with the specified detail
     * message.
     *
     * @param message the detail message
     */
    public ApiClientException(String message) {
        super(message);
    }

    /**
     * Constructs a new {@code ApiClientException} with the specified detail
     * message and cause.
     *
     * @param message the detail message
     * @param cause the cause
     */
    public ApiClientException(String message, Throwable cause) {
        super(message, cause);
    }
}
