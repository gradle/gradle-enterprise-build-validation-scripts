package com.gradle.enterprise;

public class FetchBuildValidationDataException extends RuntimeException {
    public FetchBuildValidationDataException() {
    }

    public FetchBuildValidationDataException(String message) {
        super(message);
    }

    public FetchBuildValidationDataException(String message, Throwable cause) {
        super(message, cause);
    }

    public FetchBuildValidationDataException(Throwable cause) {
        super(cause);
    }

    public FetchBuildValidationDataException(String message, Throwable cause, boolean enableSuppression, boolean writableStackTrace) {
        super(message, cause, enableSuppression, writableStackTrace);
    }
}
