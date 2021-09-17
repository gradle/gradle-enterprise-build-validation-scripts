package com.gradle;

import com.gradle.maven.extension.api.GradleEnterpriseApi;
import com.gradle.maven.extension.api.GradleEnterpriseListener;
import org.apache.maven.execution.MavenSession;
import org.apache.maven.project.MavenProject;
import org.codehaus.plexus.component.annotations.Component;
import org.codehaus.plexus.logging.Logger;

import javax.inject.Inject;
import java.io.BufferedWriter;
import java.io.FileWriter;
import java.io.IOException;
import java.io.PrintWriter;

@SuppressWarnings("unused")
@Component(
    role = GradleEnterpriseListener.class,
    hint = "capture-build-scans",
    description = "Captures the URL to build scans produced from Maven builds."
)
public class CaptureBuildScansListener implements GradleEnterpriseListener {
    private static final String EXPERIMENT_DIR = System.getProperty("com.gradle.enterprise.build_validation.experimentDir");

    private final RootProjectExtractor rootProjectExtractor;
    private final Logger logger;

    @Inject
    public CaptureBuildScansListener(RootProjectExtractor rootProjectExtractor, Logger logger) {
        this.rootProjectExtractor = rootProjectExtractor;
        this.logger = logger;
    }

    @Override
    public void configure(GradleEnterpriseApi api, MavenSession session) throws Exception {
        MavenProject rootProject = rootProjectExtractor.extractRootProject(session);
        logger.debug("Configuring build scan published event...");

        api.getBuildScan().buildScanPublished(scan -> {
            logger.debug("Saving build scan data to build-scans.csv");
            String port = scan.getBuildScanUri().getPort() != -1 ? ":" + scan.getBuildScanUri().getPort() : "";
            String baseUrl = String.format("%s://%s%s", scan.getBuildScanUri().getScheme(), scan.getBuildScanUri().getHost(), port);

            try (FileWriter fw = new FileWriter(EXPERIMENT_DIR + "/build-scans.csv", true);
                 BufferedWriter bw = new BufferedWriter(fw);
                 PrintWriter out = new PrintWriter(bw)) {
                out.println(String.format("%s,%s,%s,%s", rootProject.getName(), baseUrl, scan.getBuildScanUri(), scan.getBuildScanId()));
            } catch (IOException e) {
                logger.error("Unable to save scan data to build-scans.csv: " + e.getMessage(), e);
                throw new RuntimeException("Unable to save scan data to build-scans.csv: " + e.getMessage(), e);
            }
        });
    }
}
