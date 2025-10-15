package com.microsoft.migration.assets.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.http.CacheControl;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.ViewControllerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurerAdapter;

import java.util.concurrent.TimeUnit;

/**
 * Web MVC configuration using WebMvcConfigurerAdapter.
 * 
 */
@Configuration
@SuppressWarnings("deprecation")
public class WebMvcConfig extends WebMvcConfigurerAdapter {

    /**
     * Configure resource handlers with caching for static content.
     * This demonstrates meaningful resource handling that improves performance.
     */
    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        // Add cache control for CSS, JS, and image files
        registry.addResourceHandler("/css/**", "/js/**", "/images/**")
                .addResourceLocations("classpath:/static/css/", "classpath:/static/js/", "classpath:/static/images/")
                .setCacheControl(CacheControl.maxAge(30, TimeUnit.DAYS).cachePublic());
        
        // Add cache control for favicon
        registry.addResourceHandler("/favicon.ico")
                .addResourceLocations("classpath:/static/")
                .setCacheControl(CacheControl.maxAge(7, TimeUnit.DAYS).cachePublic());
    }

    /**
     * Add simple view controllers to provide direct mapping from URL paths to view names.
     * This provides a meaningful shortcut for simple page navigation without needing controller methods.
     */
    @Override
    public void addViewControllers(ViewControllerRegistry registry) {
        // Redirect root to the S3 file listing page
        registry.addRedirectViewController("/", "/s3");
        
        // Add a simple about page
        registry.addViewController("/about").setViewName("about");
        
        // Add a help page for file upload instructions
        registry.addViewController("/help").setViewName("help");
    }
}
