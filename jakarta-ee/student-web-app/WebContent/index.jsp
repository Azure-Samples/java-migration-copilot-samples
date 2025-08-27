<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="org.sample.azure.student.coreft.StudentProfile" %>
<%@ page import="java.util.List" %>
<html>
<head>
    <title>Student Management System - Spring Framework 5.3</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        table { border-collapse: collapse; width: 100%; margin-top: 20px; }
        th, td { border: 1px solid #ddd; padding: 12px; text-align: left; }
        th { background-color: #f2f2f2; }
        .header { background-color: #4CAF50; color: white; padding: 20px; margin-bottom: 20px; }
        .nav { margin: 20px 0; }
        .nav a { margin-right: 15px; text-decoration: none; color: #4CAF50; }
        .nav a:hover { text-decoration: underline; }
        .error { color: red; background-color: #ffe6e6; padding: 10px; margin: 10px 0; border-radius: 5px; }
        .info { color: #31708f; background-color: #d9edf7; padding: 10px; margin: 10px 0; border-radius: 5px; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Student Management System</h1>
        <p>Powered by Spring Framework 5.3 and Open Liberty</p>
    </div>
    
    <div class="nav">
        <a href="/">Original Home</a>
        <a href="/app/">Spring Home (NEW!)</a>
        <a href="/app/students">Spring Students</a>
        <a href="/app/add-student">Spring Add Student</a>
        <a href="/studentProfileList">Legacy Student List</a>
    </div>

    <% 
        String error = (String) request.getAttribute("error");
        String successMessage = (String) request.getAttribute("successMessage");
        String errorMessage = (String) request.getAttribute("errorMessage");
        
        if (error != null) { 
    %>
        <div class="error">
            <strong>Error:</strong> <%= error %>
        </div>
    <% } %>
    
    <% if (successMessage != null) { %>
        <div class="info">
            <strong>Success:</strong> <%= successMessage %>
        </div>
    <% } %>
    
    <% if (errorMessage != null) { %>
        <div class="error">
            <strong>Error:</strong> <%= errorMessage %>
        </div>
    <% } %>

    <h2>Student Profiles (Direct JSP Access)</h2>
    
    <div class="info">
        <strong>New!</strong> Spring Framework 5.3 has been integrated! Try the new Spring MVC pages:
        <br>• <a href="/app/" style="color: #31708f;">Spring Home Page</a> - Full Spring MVC integration
        <br>• <a href="/app/add-student" style="color: #31708f;">Spring Add Student</a> - Modern form handling
        <br><br>This page shows direct JSP access (traditional approach).
    </div>
    
    <table>
        <thead>
            <tr>
                <th>ID</th>
                <th>Name</th>
                <th>Email</th>
                <th>Major</th>
            </tr>
        </thead>
        <tbody>
            <%
                @SuppressWarnings("unchecked")
                List<StudentProfile> students = (List<StudentProfile>) request.getAttribute("students");
                if (students != null && !students.isEmpty()) {
                    for (StudentProfile student : students) {
            %>
            <tr>
                <td><%= student.getId() %></td>
                <td><%= student.getName() %></td>
                <td><%= student.getEmail() %></td>
                <td><%= student.getMajor() %></td>
            </tr>
            <%      }
                } else { %>
            <tr>
                <td colspan="4" style="text-align: center; font-style: italic;">
                    <% if (students != null) { %>
                        No student profiles found.
                    <% } else { %>
                        Loading student data...
                    <% } %>
                </td>
            </tr>
            <% } %>
        </tbody>
    </table>
    
    <div style="margin-top: 30px; font-size: 12px; color: #666;">
        <p><strong>Technology Stack:</strong></p>
        <ul>
            <li>Spring Framework 5.3</li>
            <li>Spring MVC</li>
            <li>Open Liberty Application Server</li>
            <li>MyBatis (iBatis) for Data Access</li>
            <li>MySQL Database</li>
        </ul>
    </div>
</body>
</html>
