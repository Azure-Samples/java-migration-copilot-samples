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
                -- Migrated from Oracle to PostgreSQL according to java check item 1, 3, 4, 6
                SELECT
                    id,
                    title,
                    SUBSTRING(description FROM 1 FOR 50) AS short_desc,
                    CASE WHEN LENGTH(description) > 50 THEN 'Y' ELSE 'N' END AS is_long_desc,
                    priority,
                    TO_CHAR(due_date, 'YYYY-MM-DD HH24:MI:SS') AS formatted_due_date,
                    ROUND(EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - created_at)) / 86400) AS days_since_creation
                FROM
                    todo_items
                WHERE
                    (UPPER(title) LIKE UPPER('%' || ? || '%') OR
                     UPPER(description) LIKE UPPER('%' || ? || '%'))
                    AND priority >= ?
                ORDER BY
                    priority DESC,
                    due_date ASC
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
                row.put("id", rs.getLong("id"));
                row.put("title", rs.getString("title"));
                row.put("shortDescription", rs.getString("short_desc"));
                row.put("isLongDescription", "Y".equals(rs.getString("is_long_desc")));
                row.put("priority", rs.getInt("priority"));
                row.put("formattedDueDate", rs.getString("formatted_due_date"));
                row.put("daysSinceCreation", rs.getInt("days_since_creation"));
                results.add(row);
            }

            log.info("Executed PostgreSQL-compatible SQL query with {} results", results.size());
            return results;

        } catch (SQLException e) {
            log.error("Error executing PostgreSQL SQL", e);
            throw new RuntimeException("Failed to execute PostgreSQL SQL query", e);
        }
    }

    /**
     * Demonstrates PostgreSQL-specific database operations
     * Uses PostgreSQL's VARCHAR data type and other PostgreSQL-specific functions
     */
    public void performOracleSpecificOperations() {
        // Migrated from Oracle to PostgreSQL according to java check item 16, 9999
        // Create temporary table if not exists
        String dropTable = "DROP TABLE IF EXISTS temp_todo_stats";
        String createTempTable = "CREATE TABLE temp_todo_stats (category VARCHAR(100), count_value INTEGER, last_updated TIMESTAMP)";
        String insertTotal = "INSERT INTO temp_todo_stats VALUES ('TOTAL', (SELECT COUNT(*) FROM todo_items), CURRENT_TIMESTAMP)";
        String insertCompleted = "INSERT INTO temp_todo_stats VALUES ('COMPLETED', (SELECT COUNT(*) FROM todo_items WHERE completed = 1), CURRENT_TIMESTAMP)";
        String insertPending = "INSERT INTO temp_todo_stats VALUES ('PENDING', (SELECT COUNT(*) FROM todo_items WHERE completed = 0), CURRENT_TIMESTAMP)";
        String insertHighPriority = "INSERT INTO temp_todo_stats VALUES ('HIGH_PRIORITY', (SELECT COUNT(*) FROM todo_items WHERE priority >= 8), CURRENT_TIMESTAMP)";

        try {
            jdbcTemplate.execute(dropTable);
            jdbcTemplate.execute(createTempTable);
            jdbcTemplate.execute(insertTotal);
            jdbcTemplate.execute(insertCompleted);
            jdbcTemplate.execute(insertPending);
            jdbcTemplate.execute(insertHighPriority);
            log.info("Successfully executed PostgreSQL SQL to create and populate temporary statistics table");
        } catch (Exception e) {
            log.error("Error executing PostgreSQL SQL", e);
        }
    }
}
