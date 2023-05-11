package com.gradle.enterprise.loader;

public interface Logger {
    void info(String message, Object... args);

    void info(String message);

    void debug(String message);

    void debug(Throwable t);

    void error(String message, Object... args);

    void error(String message);

    void error(Throwable t);

    boolean isDebugEnabled();
}
