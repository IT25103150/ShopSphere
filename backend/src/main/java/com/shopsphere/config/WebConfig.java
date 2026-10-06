package com.shopsphere.config;

import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

/** Serves product images at GET /images/products/{filename} straight from the shared images folder. */
@Configuration
public class WebConfig implements WebMvcConfigurer {
    private static final Logger log = LoggerFactory.getLogger(WebConfig.class);
    private final Path imagesDir;

    public WebConfig(@Value("${shopsphere.images.dir}") String dir) {
        this.imagesDir = Paths.get(dir).toAbsolutePath().normalize();
        try {
            Files.createDirectories(imagesDir);
        } catch (Exception ex) {
            log.warn("Could not create images folder {}", imagesDir, ex);
        }
        log.info("Product images are served from {}", imagesDir);
    }

    public Path getImagesDir() {
        return imagesDir;
    }

    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        registry.addResourceHandler("/images/products/**")
                .addResourceLocations(imagesDir.toUri().toString())
                .setCachePeriod(3600);
    }
}
