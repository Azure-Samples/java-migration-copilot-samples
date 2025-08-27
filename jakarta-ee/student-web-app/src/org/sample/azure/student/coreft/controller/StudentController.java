package org.sample.azure.student.coreft.controller;

import org.sample.azure.student.coreft.StudentProfile;
import org.sample.azure.student.coreft.service.StudentService;
import org.apache.log4j.Logger;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;

import java.util.List;

@Controller
public class StudentController {
    
    private static final Logger logger = Logger.getLogger(StudentController.class);
    
    @Autowired
    private StudentService studentService;
    
    @GetMapping("/")
    public String index(Model model) {
        logger.info("Handling index page request");
        
        try {
            List<StudentProfile> students = studentService.getAllStudents();
            model.addAttribute("students", students);
            logger.info("Added " + students.size() + " students to model");
        } catch (Exception e) {
            logger.error("Error loading students for index page: " + e.getMessage(), e);
            // Add empty list in case of error
            model.addAttribute("students", List.of());
            model.addAttribute("error", "Unable to load student data: " + e.getMessage());
        }
        
        return "spring-index";
    }
    
    @GetMapping("/students")
    public String listStudents(Model model) {
        logger.info("Handling students list request");
        
        try {
            List<StudentProfile> students = studentService.getAllStudents();
            model.addAttribute("students", students);
            logger.info("Added " + students.size() + " students to model");
        } catch (Exception e) {
            logger.error("Error loading students: " + e.getMessage(), e);
            model.addAttribute("students", List.of());
            model.addAttribute("error", "Unable to load student data: " + e.getMessage());
        }
        
        return "spring-index";
    }
}
