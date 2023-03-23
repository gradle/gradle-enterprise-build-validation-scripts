package com.gradle.enterprise.api.client;

/**
 * Exception thrown by the {@link GradleEnterpriseApiClient} when an error
 * occurs while fetching a Build Scan from the Gradle Enterprise API.
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
