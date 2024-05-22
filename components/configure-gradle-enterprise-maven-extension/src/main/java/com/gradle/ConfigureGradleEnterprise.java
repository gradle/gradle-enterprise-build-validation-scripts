package com.gradle;

import com.gradle.develocity.agent.maven.adapters.enterprise.GradleEnterpriseApiAdapter;
import com.gradle.maven.extension.api.GradleEnterpriseApi;
import com.gradle.maven.extension.api.GradleEnterpriseListener;
import org.apache.maven.execution.MavenSession;

import javax.inject.Inject;

@SuppressWarnings({"unused", "deprecation"})
public class ConfigureGradleEnterprise implements GradleEnterpriseListener {
    private static final String EXPERIMENT_DIR = System.getProperty("com.gradle.enterprise.build-validation.expDir");

    private final ConfigureDevelocityAdaptor configureDevelocityAdaptor;

    @Inject
    public ConfigureGradleEnterprise(ConfigureDevelocityAdaptor configureDevelocityAdaptor) {
        this.configureDevelocityAdaptor = configureDevelocityAdaptor;
    }

    @Override
    public void configure(GradleEnterpriseApi api, MavenSession session) {
        configureDevelocityAdaptor.configure(new GradleEnterpriseApiAdapter(api), session);
    }
}
