package com.gradle.enterprise;

import okhttp3.Authenticator;
import okhttp3.Credentials;

import java.nio.charset.StandardCharsets;
import java.util.Base64;

public class Authenticators {
    public static Authenticator basic(String username, String password) {
        return (route, response) -> {
            if (response.request().header("Authorization") != null) {
                return null; // Give up, we've already attempted to authenticate.
            }

            return response.request().newBuilder()
                .header("Authorization", Credentials.basic(username, password))
                .build();
        };
    }

    public static Authenticator accessKey(String accessKey) {
        return (route, response) -> {
            if (response.request().header("Authorization") != null) {
                return null; // Give up, we've already attempted to authenticate.
            }

            var encoded = Base64.getEncoder().encodeToString(accessKey.getBytes(StandardCharsets.UTF_8));

            return response.request().newBuilder()
                .header("Authorization", "Bearer " + encoded)
                .build();
        };
    }
}
