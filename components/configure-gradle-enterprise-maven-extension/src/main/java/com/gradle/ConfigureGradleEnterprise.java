package com.gradle;

import com.gradle.develocity.agent.maven.adapters.enterprise.GradleEnterpriseApiAdapter;
import org.apache.maven.execution.MavenSession;

import javax.inject.Inject;

// Using fully qualified class names to avoid deprecation warnings on import statements
@SuppressWarnings({"deprecation"})
public class ConfigureGradleEnterprise implements com.gradle.maven.extension.api.GradleEnterpriseListener {

    private final ConfigureDevelocityAdaptor configureDevelocityAdaptor;

    @Inject
    public ConfigureGradleEnterprise(ConfigureDevelocityAdaptor configureDevelocityAdaptor) {
        this.configureDevelocityAdaptor = configureDevelocityAdaptor;
    }

    @Override
    public void configure(com.gradle.maven.extension.api.GradleEnterpriseApi api, MavenSession session) {
        configureDevelocityAdaptor.configure(new GradleEnterpriseApiAdapter(api), session);
    }
}
