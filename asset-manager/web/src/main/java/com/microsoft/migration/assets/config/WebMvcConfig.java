package com.microsoft.migration.assets.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.http.CacheControl;
import org.springframework.web.servlet.config.annotation.InterceptorRegistry;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.ViewControllerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurerAdapter;
import org.springframework.web.servlet.handler.HandlerInterceptorAdapter;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.util.concurrent.TimeUnit;

/**
 * Web MVC configuration using WebMvcConfigurerAdapter.
 */
@Configuration
@SuppressWarnings("deprecation")
public class WebMvcConfig extends WebMvcConfigurerAdapter {

    /**
     * Resource handlers with caching for static content.
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
     * Simple view controllers to provide direct mapping from URL paths to view names.
     * This provides a shortcut for simple page navigation without needing controller methods.
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

    /**
     * Interceptors for request logging and file operation monitoring.
     */
    @Override
    public void addInterceptors(InterceptorRegistry registry) {
        registry.addInterceptor(new FileOperationLoggingInterceptor())
                .addPathPatterns("/s3/**")
                .excludePathPatterns("/s3/view/**"); // Exclude file download endpoints from detailed logging
    }

    /**
     * Custom interceptor using HandlerInterceptorAdapter.
     * This interceptor logs file operations for monitoring and debugging purposes.
     */
    private static class FileOperationLoggingInterceptor extends HandlerInterceptorAdapter {
        
        @Override
        public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) {
            long startTime = System.currentTimeMillis();
            request.setAttribute("startTime", startTime);
            
            String operation = determineFileOperation(request);
            System.out.printf("[FILE-OP] %s %s - %s started at %d%n", 
                    request.getMethod(), request.getRequestURI(), operation, startTime);
            
            return true;
        }

        @Override
        public void afterCompletion(HttpServletRequest request, HttpServletResponse response, 
                                  Object handler, Exception ex) {
            long startTime = (Long) request.getAttribute("startTime");
            long duration = System.currentTimeMillis() - startTime;
            String operation = determineFileOperation(request);
            
            if (ex != null) {
                System.out.printf("[FILE-OP] %s %s - %s FAILED in %d ms (Status: %d, Error: %s)%n", 
                        request.getMethod(), request.getRequestURI(), operation, duration, 
                        response.getStatus(), ex.getMessage());
            } else {
                System.out.printf("[FILE-OP] %s %s - %s completed in %d ms (Status: %d)%n", 
                        request.getMethod(), request.getRequestURI(), operation, duration, 
                        response.getStatus());
            }
        }
        
        private String determineFileOperation(HttpServletRequest request) {
            String uri = request.getRequestURI();
            String method = request.getMethod();
            
            if (uri.contains("/upload")) {
                return "FILE_UPLOAD";
            } else if (uri.contains("/delete/")) {
                return "FILE_DELETE";
            } else if (uri.contains("/view/")) {
                return "FILE_DOWNLOAD";
            } else if (uri.contains("/view-page/")) {
                return "FILE_VIEW_PAGE";
            } else if ("GET".equals(method) && uri.equals("/s3")) {
                return "FILE_LIST";
            } else {
                return "FILE_OPERATION";
            }
        }
    }
}
