package com.gradle;

import com.gradle.maven.extension.api.scan.BuildScanApi;
import org.apache.maven.eventspy.AbstractEventSpy;
import org.apache.maven.eventspy.EventSpy;
import org.codehaus.plexus.PlexusContainer;
import org.codehaus.plexus.component.annotations.Component;
import org.codehaus.plexus.logging.Logger;

import javax.inject.Inject;
import java.io.BufferedWriter;
import java.io.FileWriter;
import java.io.IOException;
import java.io.PrintWriter;
import java.util.Map;

@Component( role = EventSpy.class, hint = "demo" )
public class CaptureBuildScansEventSpy  extends AbstractEventSpy {

    private final PlexusContainer container;
    private final Logger logger;

    @Inject
    public CaptureBuildScansEventSpy(PlexusContainer container, Logger logger) {
        this.container = container;
        this.logger = logger;
    }

    @Override
    public void init(Context context) throws Exception {
        super.init(context);
        logger.debug("Executing EventSpy: " + getClass().getSimpleName());

        BuildScanApi buildScan = ApiAccessor.lookupBuildScanApi(container, getClass());
        if (buildScan == null) throw new RuntimeException("Unable to configure build scans: the Build Scan API cannot be found.");

        buildScan.buildScanPublished(scan -> {
            logger.debug("Saving build scan data to scans.csv");
            String port = scan.getBuildScanUri().getPort() != -1 ? ":" + scan.getBuildScanUri().getPort(): "";
            String baseUrl = String.format("%s://%s%s", scan.getBuildScanUri().getScheme(), scan.getBuildScanUri().getHost(), port);

            try(FileWriter fw = new FileWriter("../scans.csv", true);
                BufferedWriter bw = new BufferedWriter(fw);
                PrintWriter out = new PrintWriter(bw))
            {
                out.println(String.format("%s,%s,%s", baseUrl, scan.getBuildScanId(), scan.getBuildScanUri()));
            } catch (IOException e) {
                logger.error("Unable to save scan data to scans.csv: " + e.getMessage(), e);
                throw new RuntimeException("Unable to save scan data to scans.csv: " + e.getMessage(), e);
            }
        });
    }
}
