package org.sample.azure.student.coreft;

import org.sample.azure.student.coreft.util.MyBatisUtil;
import com.ibatis.sqlmap.client.SqlMapSession;
import org.apache.log4j.Logger;

import java.io.IOException;
import java.util.HashMap;
import java.util.Map;
import javax.naming.Context;
import javax.naming.InitialContext;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.mail.Message;
import javax.mail.Session;
import javax.mail.Transport;
import javax.mail.internet.InternetAddress;
import javax.mail.internet.MimeMessage;

public class AddStudentServlet extends HttpServlet {

    private static final Logger logger = Logger.getLogger(AddStudentServlet.class);

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        logger.info("Displaying add student form");
        // Forward to the add student form JSP
        request.getRequestDispatcher("/add_student_profile.jsp").forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        String name = request.getParameter("name");
        String email = request.getParameter("email");
        String major = request.getParameter("major");
        boolean success = false;
        String errorMsg = null;
        SqlMapSession session = null;
        
        try {
            logger.info("Starting to add student: name=" + name + ", email=" + email + ", major=" + major);
            session = MyBatisUtil.getSqlMapClient().openSession();
            session.startTransaction();
            
            Map<String, Object> params = new HashMap<>();
            params.put("name", name);
            params.put("email", email);
            params.put("major", major);
            
            session.insert("com.azure.sample.StudentMapper.addStudent", params);
            session.commitTransaction();
            success = true;
            
            logger.info("Student added successfully, sending email to: " + email);
            // Send email notification
            sendEmail(email, name);
            
        } catch (Exception e) {
            logger.error("Error adding student: " + e.getMessage(), e);
            errorMsg = e.getMessage();
            if (session != null) {
                try {
                    session.endTransaction();
                } catch (Exception rollbackEx) {
                    logger.error("Error ending transaction: " + rollbackEx.getMessage(), rollbackEx);
                }
            }
        } finally {
            if (session != null) {
                try {
                    session.close();
                } catch (Exception e) {
                    logger.error("Error closing session: " + e.getMessage(), e);
                }
            }
        }
        
        if (success) {
            logger.info("Redirecting to HelloServlet after successful add.");
            response.setContentType("text/html");
            response.getWriter().write("<h2>Student added successfully!</h2>");
            response.getWriter().write("<p><a href='studentProfileList'>View All Student Profiles</a></p>");
            response.getWriter().write("<p><a href='/'>Add Another Student</a></p>");
        } else {
            logger.warn("Add student failed: " + errorMsg);
            request.setAttribute("errorMsg", errorMsg != null ? errorMsg : "Failed to add student.");
            request.getRequestDispatcher("/add_student_profile.jsp").forward(request, response);
        }
    }

    private void sendEmail(String to, String name) throws Exception {
        logger.info("Preparing to send email to: " + to);
        // Lookup mail session from JNDI (configured in server.xml)
        Context ctx = new InitialContext();
        Session session = (Session) ctx.lookup("java:comp/env/mail/StudentMailSession");
        Message msg = new MimeMessage(session);
        msg.setRecipients(Message.RecipientType.TO, InternetAddress.parse(to, false));
        msg.setSubject("Welcome, " + name + "!");
        msg.setText("Dear " + name + ",\n\nYour student profile has been created successfully.\n\nRegards,\nAdmin");
        Transport.send(msg);
        logger.info("Email sent to: " + to);
    }
}
