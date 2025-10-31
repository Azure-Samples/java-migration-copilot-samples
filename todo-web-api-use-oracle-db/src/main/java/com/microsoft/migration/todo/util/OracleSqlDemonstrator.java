package com.microsoft.migration.todo.util;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Component
@Slf4j
public class OracleSqlDemonstrator {

    @Autowired
    private JdbcTemplate jdbcTemplate;

    /**
     * Demonstrates executing raw Oracle SQL queries directly
     * This method shows Oracle-specific SQL features like:
     * - VARCHAR2 data type
     * - Oracle specific date functions
     * - Oracle specific string functions
     */
    public List<Map<String, Object>> executeRawOracleQuery(String keyword, int minPriority) {
        String sql = """
                SELECT
                    ID,
                    TITLE,
                    SUBSTR(DESCRIPTION, 1, 50) AS SHORT_DESC,
                    CASE WHEN LENGTH(DESCRIPTION) > 50 THEN 'Y' ELSE 'N' END AS IS_LONG_DESC,
                    PRIORITY,
                    TO_CHAR(DUE_DATE, 'YYYY-MM-DD HH24:MI:SS') AS FORMATTED_DUE_DATE,
                    ROUND(SYSDATE - CREATED_AT) AS DAYS_SINCE_CREATION
                FROM
                    TODO_ITEMS
                WHERE
                    (UPPER(TITLE) LIKE UPPER('%' || ? || '%') OR
                     UPPER(DESCRIPTION) LIKE UPPER('%' || ? || '%'))
                    AND PRIORITY >= ?
                ORDER BY
                    PRIORITY DESC,
                    DUE_DATE ASC
                """;

        List<Map<String, Object>> results = new ArrayList<>();

        try (Connection conn = jdbcTemplate.getDataSource().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            // Set parameters
            stmt.setString(1, keyword);
            stmt.setString(2, keyword);
            stmt.setInt(3, minPriority);

            // Execute query
            ResultSet rs = stmt.executeQuery();

            // Process results
            while (rs.next()) {
                Map<String, Object> row = new HashMap<>();
                row.put("id", rs.getLong("ID"));
                row.put("title", rs.getString("TITLE"));
                row.put("shortDescription", rs.getString("SHORT_DESC"));
                row.put("isLongDescription", "Y".equals(rs.getString("IS_LONG_DESC")));
                row.put("priority", rs.getInt("PRIORITY"));
                row.put("formattedDueDate", rs.getString("FORMATTED_DUE_DATE"));
                row.put("daysSinceCreation", rs.getInt("DAYS_SINCE_CREATION"));
                results.add(row);
            }

            log.info("Executed Oracle-specific SQL query with {} results", results.size());
            return results;

        } catch (SQLException e) {
            log.error("Error executing Oracle SQL", e);
            throw new RuntimeException("Failed to execute Oracle SQL query", e);
        }
    }

    /**
     * Demonstrates Oracle-specific database operations
     * Uses Oracle's VARCHAR2 data type and other Oracle-specific functions
     */
    public void performOracleSpecificOperations() {
        // Example of creating a temporary table with VARCHAR2
        String createTempTable = """
                DECLARE
                   v_count NUMBER;
                BEGIN
                   SELECT COUNT(*) INTO v_count FROM USER_TABLES WHERE TABLE_NAME = 'TEMP_TODO_STATS';
                   IF v_count > 0 THEN
                      EXECUTE IMMEDIATE 'DROP TABLE TEMP_TODO_STATS';
                   END IF;

                   EXECUTE IMMEDIATE 'CREATE TABLE TEMP_TODO_STATS (
                      CATEGORY VARCHAR2(100),
                      COUNT_VALUE NUMBER,
                      LAST_UPDATED TIMESTAMP
                   )';

                   -- Insert some statistics
                   EXECUTE IMMEDIATE 'INSERT INTO TEMP_TODO_STATS VALUES (''TOTAL'', (SELECT COUNT(*) FROM TODO_ITEMS), SYSTIMESTAMP)';
                   EXECUTE IMMEDIATE 'INSERT INTO TEMP_TODO_STATS VALUES (''COMPLETED'', (SELECT COUNT(*) FROM TODO_ITEMS WHERE COMPLETED = 1), SYSTIMESTAMP)';
                   EXECUTE IMMEDIATE 'INSERT INTO TEMP_TODO_STATS VALUES (''PENDING'', (SELECT COUNT(*) FROM TODO_ITEMS WHERE COMPLETED = 0), SYSTIMESTAMP)';
                   EXECUTE IMMEDIATE 'INSERT INTO TEMP_TODO_STATS VALUES (''HIGH_PRIORITY'', (SELECT COUNT(*) FROM TODO_ITEMS WHERE PRIORITY >= 8), SYSTIMESTAMP)';

                   COMMIT;
                END;
                """;

        try {
            jdbcTemplate.execute(createTempTable);
            log.info("Successfully executed Oracle PL/SQL block to create and populate temporary statistics table");
        } catch (Exception e) {
            log.error("Error executing Oracle PL/SQL block", e);
        }
    }
}
