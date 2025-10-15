package com.microsoft.migration.assets.controller;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;

/**
 * Home controller for additional navigation endpoints.
 * Note: Root "/" redirect is now handled by WebMvcConfig view controllers.
 */
@Controller
public class HomeController {

    /**
     * Provide a health check endpoint for the application.
     */
    @GetMapping("/health")
    public String health() {
        return "redirect:/s3";
    }
}
