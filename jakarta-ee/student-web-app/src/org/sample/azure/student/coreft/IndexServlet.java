package org.sample.azure.student.coreft;

import org.sample.azure.student.coreft.util.MyBatisUtil;
import com.ibatis.sqlmap.client.SqlMapSession;
import org.apache.log4j.Logger;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.List;

/**
 * Servlet to handle the root path and populate index.jsp with student data
 */
public class IndexServlet extends HttpServlet {

    private static final Logger logger = Logger.getLogger(IndexServlet.class);

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        logger.info("Processing request for index page with student data");
        
        SqlMapSession session = null;
        try {
            // Get student data
            session = MyBatisUtil.getSqlMapClient().openSession();
            List<StudentProfile> students = (List<StudentProfile>) session.queryForList("com.azure.sample.StudentMapper.listStudent");
            
            // Set attributes for the JSP
            request.setAttribute("students", students);
            logger.info("Successfully loaded " + students.size() + " students for index page");
            
        } catch (Exception ex) {
            logger.error("Error loading students for index page: " + ex.getMessage(), ex);
            // Set error message and empty list
            request.setAttribute("error", "Unable to load student data: " + ex.getMessage());
            request.setAttribute("students", null);
        } finally {
            if (session != null) {
                try {
                    session.close();
                } catch (Exception e) {
                    logger.error("Error closing session: " + e.getMessage(), e);
                }
            }
        }
        
        // Forward to the JSP
        request.getRequestDispatcher("/index.jsp").forward(request, response);
    }
}
