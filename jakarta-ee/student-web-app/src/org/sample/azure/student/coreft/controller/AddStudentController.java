package org.sample.azure.student.coreft.controller;

import org.sample.azure.student.coreft.StudentProfile;
import org.sample.azure.student.coreft.service.StudentService;
import org.apache.log4j.Logger;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

@Controller
public class AddStudentController {
    
    private static final Logger logger = Logger.getLogger(AddStudentController.class);
    
    @Autowired
    private StudentService studentService;
    
    @GetMapping("/add-student")
    public String showAddStudentForm() {
        return "spring-add-student";
    }
    
    @PostMapping("/add-student")
    public String addStudent(
            @RequestParam("name") String name,
            @RequestParam("email") String email,
            @RequestParam("major") String major,
            RedirectAttributes redirectAttributes) {
        
        logger.info("Adding new student: " + name + ", " + email + ", " + major);
        
        try {
            // Save the student to the database using StudentService
            boolean success = studentService.saveStudent(name, email, major);
            
            if (success) {
                logger.info("Student saved successfully: " + name);
                redirectAttributes.addFlashAttribute("successMessage", 
                    "Student " + name + " has been added successfully!");
            } else {
                logger.warn("Failed to save student: " + name);
                redirectAttributes.addFlashAttribute("errorMessage", 
                    "Failed to save student. Please try again.");
            }
            
        } catch (Exception e) {
            logger.error("Error adding student: " + e.getMessage(), e);
            redirectAttributes.addFlashAttribute("errorMessage", 
                "Error adding student: " + e.getMessage());
        }
        
        return "redirect:/app/";
    }
}
