<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.*" %>
<html>
<head>
    <title>Add Student Profile - Spring Framework</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background-color: #f5f5f5; }
        .container { max-width: 600px; margin: 0 auto; background-color: white; padding: 30px; border-radius: 10px; box-shadow: 0 0 10px rgba(0,0,0,0.1); }
        .header { background-color: #4CAF50; color: white; padding: 20px; margin: -30px -30px 30px -30px; border-radius: 10px 10px 0 0; }
        .form-group { margin-bottom: 20px; }
        label { display: block; margin-bottom: 5px; font-weight: bold; color: #333; }
        input[type="text"], input[type="email"] { width: 100%; padding: 10px; border: 1px solid #ddd; border-radius: 5px; font-size: 16px; box-sizing: border-box; }
        input[type="submit"] { background-color: #4CAF50; color: white; padding: 12px 30px; border: none; border-radius: 5px; cursor: pointer; font-size: 16px; }
        input[type="submit"]:hover { background-color: #45a049; }
        .nav { margin-bottom: 20px; }
        .nav a { color: #4CAF50; text-decoration: none; margin-right: 15px; }
        .nav a:hover { text-decoration: underline; }
        .success { color: #3c763d; background-color: #dff0d8; padding: 10px; margin: 10px 0; border-radius: 5px; border: 1px solid #d6e9c6; }
        .error { color: #a94442; background-color: #f2dede; padding: 10px; margin: 10px 0; border-radius: 5px; border: 1px solid #ebccd1; }
        .spring-badge { background-color: #6DB33F; color: white; padding: 4px 8px; border-radius: 4px; font-size: 12px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>Add Student Profile <span class="spring-badge">Spring MVC</span></h1>
            <p>Spring Framework 5.3 Integration</p>
        </div>
        
        <div class="nav">
            <a href="/app/">← Back to Spring Home</a>
            <a href="/app/students">View All Students</a>
            <a href="/">Original Index</a>
            <a href="/studentProfileList">Legacy Student List</a>
        </div>

        <% 
            String successMessage = (String) request.getAttribute("successMessage");
            String errorMessage = (String) request.getAttribute("errorMessage");
            if (successMessage != null) { 
        %>
            <div class="success">
                <%= successMessage %>
            </div>
        <% } %>
        
        <% if (errorMessage != null) { %>
            <div class="error">
                <%= errorMessage %>
            </div>
        <% } %>

        <form action="/app/add-student" method="post">
            <div class="form-group">
                <label for="name">Student Name:</label>
                <input type="text" id="name" name="name" required placeholder="Enter student's full name">
            </div>
            
            <div class="form-group">
                <label for="email">Email Address:</label>
                <input type="email" id="email" name="email" required placeholder="Enter student's email">
            </div>
            
            <div class="form-group">
                <label for="major">Major/Field of Study:</label>
                <input type="text" id="major" name="major" required placeholder="Enter student's major">
            </div>
            
            <div class="form-group">
                <input type="submit" value="Add Student (Spring MVC)">
            </div>
        </form>
        
        <div style="margin-top: 30px; font-size: 12px; color: #666; border-top: 1px solid #eee; padding-top: 20px;">
            <p><strong>Spring MVC Integration:</strong></p>
            <ul>
                <li>Form processing via Spring MVC Controller</li>
                <li>URL: /app/add-student (POST)</li>
                <li>Redirects to: /app/ (Spring home page)</li>
                <li>Uses Spring's RedirectAttributes for flash messages</li>
            </ul>
        </div>
    </div>
</body>
</html>
