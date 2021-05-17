package com.gradle;

import com.gradle.maven.extension.api.scan.BuildScanApi;
import org.apache.maven.eventspy.AbstractEventSpy;
import org.apache.maven.eventspy.EventSpy;
import org.apache.maven.execution.ExecutionEvent;
import org.apache.maven.execution.MavenExecutionResult;
import org.apache.maven.project.MavenProject;
import org.codehaus.plexus.PlexusContainer;
import org.codehaus.plexus.component.annotations.Component;
import org.codehaus.plexus.logging.Logger;

import javax.inject.Inject;
import java.io.BufferedWriter;
import java.io.FileWriter;
import java.io.IOException;
import java.io.PrintWriter;

@Component( role = EventSpy.class, hint = "capture-build-scans" )
public class CaptureBuildScansEventSpy  extends AbstractEventSpy {
    private static final String EXPERIMENT_DIR=System.getProperty("com.gradle.enterprise.build_validation.experimentDir");

    private final PlexusContainer container;
    private final RootProjectExtractor rootProjectExtractor;
    private final Logger logger;
    private String rootProjectName = "";

    @Inject
    public CaptureBuildScansEventSpy(PlexusContainer container, RootProjectExtractor rootProjectExtractor, Logger logger) {
        this.container = container;
        this.rootProjectExtractor = rootProjectExtractor;
        this.logger = logger;
    }

    @Override
    public void init(Context context) throws Exception {
        super.init(context);
        logger.debug("Executing EventSpy: " + getClass().getSimpleName());

        BuildScanApi buildScan = ApiAccessor.lookupBuildScanApi(container, getClass());
        if (buildScan == null) throw new RuntimeException("Unable to configure build scans: the Build Scan API cannot be found.");

        buildScan.buildScanPublished(scan -> {
            synchronized (rootProjectName) {
                logger.debug("Saving build scan data to build-scans.csv");
                String port = scan.getBuildScanUri().getPort() != -1 ? ":" + scan.getBuildScanUri().getPort() : "";
                String baseUrl = String.format("%s://%s%s", scan.getBuildScanUri().getScheme(), scan.getBuildScanUri().getHost(), port);

                try (FileWriter fw = new FileWriter(EXPERIMENT_DIR + "/build-scans.csv", true);
                     BufferedWriter bw = new BufferedWriter(fw);
                     PrintWriter out = new PrintWriter(bw)) {
                    out.println(String.format("%s,%s,%s,%s", rootProjectName, baseUrl, scan.getBuildScanUri(), scan.getBuildScanId()));
                } catch (IOException e) {
                    logger.error("Unable to save scan data to build-scans.csv: " + e.getMessage(), e);
                    throw new RuntimeException("Unable to save scan data to build-scans.csv: " + e.getMessage(), e);
                }
            }
        });
    }

    @Override
    public void onEvent(Object event) throws Exception {
        if(event instanceof ExecutionEvent) {
            ExecutionEvent executionEvent = (ExecutionEvent) event;
            if (executionEvent.getType() == ExecutionEvent.Type.SessionStarted) {
                MavenProject rootProject = rootProjectExtractor.extractRootProject(executionEvent);
                synchronized (rootProjectName) {
                    rootProjectName = rootProject.getName();
                }
            }
        }
    }

    private MavenProject walkToRootProject(MavenProject project) {
        if(project.getParent() == null || project.isExecutionRoot()) return project;
        return walkToRootProject(project.getParent());
    }
}
