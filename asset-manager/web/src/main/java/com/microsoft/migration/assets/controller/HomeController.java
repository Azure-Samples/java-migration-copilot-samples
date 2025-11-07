package com.microsoft.migration.assets.controller;

import com.microsoft.migration.assets.constants.StorageConstants;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;

@Controller
public class HomeController {

    @GetMapping("/")
    public String home() {
        return "redirect:/" + StorageConstants.STORAGE_PATH;
    }
}