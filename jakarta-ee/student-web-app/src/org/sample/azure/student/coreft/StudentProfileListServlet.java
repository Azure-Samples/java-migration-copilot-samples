package org.sample.azure.student.coreft;

import org.sample.azure.student.coreft.util.MyBatisUtil;
import com.ibatis.sqlmap.client.SqlMapSession;
import org.apache.log4j.Logger;
import org.codehaus.jackson.map.ObjectMapper;

import java.io.IOException;
import java.io.PrintWriter;
import java.util.List;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

public class StudentProfileListServlet extends HttpServlet {

    private static final Logger logger = Logger.getLogger(StudentProfileListServlet.class);

    private final ObjectMapper objectMapper;

    public StudentProfileListServlet() {
        objectMapper = new ObjectMapper();
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        logger.info("Start to list student profile list");
        response.setContentType("text/html;charset=UTF-8");
        
        try (PrintWriter out = response.getWriter()) {
            out.println("<html><head><title>Student Profile List</title></head><body>");
            out.println("<h2>Student Profile List</h2>");
            
            SqlMapSession session = null;
            try {
                session = MyBatisUtil.getSqlMapClient().openSession();

                @SuppressWarnings("unchecked")
                List<StudentProfile> students = (List<StudentProfile>) session.queryForList("com.azure.sample.StudentMapper.listStudent");
                
                out.println("<table border='1'><tr><th>ID</th><th>Name</th><th>Email</th><th>Major</th></tr>");
                for (StudentProfile student : students) {
                    out.println("<tr><td>" + student.getId() + "</td>" +
                               "<td>" + student.getName() + "</td>" +
                               "<td>" + student.getEmail() + "</td>" +
                               "<td>" + student.getMajor() + "</td></tr>");
                }
                out.println("</table>");
                out.println("<br/><br/><br/>");
                out.println(objectMapper.writeValueAsString(students));
                
            } catch (Exception ex) {
                logger.error("Error retrieving student list: " + ex.getMessage(), ex);
                out.println("<p>Error: " + ex.getMessage() + "</p>");
                throw new RuntimeException(ex);
            } finally {
                if (session != null) {
                    try {
                        session.close();
                    } catch (Exception e) {
                        logger.error("Error closing session: " + e.getMessage(), e);
                    }
                }
            }
            out.println("</body></html>");
        }
    }
}
