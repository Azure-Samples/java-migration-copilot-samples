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
     * Demonstrates executing raw SQL Server queries directly
     * This method shows SQL Server-specific SQL features like:
     * - VARCHAR data type
     * - SQL Server specific date functions
     * - SQL Server specific string functions
     */
    public List<Map<String, Object>> executeRawOracleQuery(String keyword, int minPriority) {
        String sql = """
                SELECT
                    ID,
                    TITLE,
                    SUBSTRING(DESCRIPTION, 1, 50) AS SHORT_DESC,
                    CASE WHEN LEN(DESCRIPTION) > 50 THEN 'Y' ELSE 'N' END AS IS_LONG_DESC,
                    PRIORITY,
                    CONVERT(VARCHAR(19), DUE_DATE, 120) AS FORMATTED_DUE_DATE,
                    DATEDIFF(DAY, CREATED_AT, GETDATE()) AS DAYS_SINCE_CREATION
                FROM
                    TODO_ITEMS
                WHERE
                    (UPPER(TITLE) LIKE UPPER('%' + ? + '%') OR
                     UPPER(DESCRIPTION) LIKE UPPER('%' + ? + '%'))
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

            log.info("Executed SQL Server-specific SQL query with {} results", results.size());
            return results;

        } catch (SQLException e) {
            log.error("Error executing SQL Server SQL", e);
            throw new RuntimeException("Failed to execute SQL Server SQL query", e);
        }
    }

    /**
     * Demonstrates SQL Server-specific database operations
     * Uses SQL Server's VARCHAR data type and other SQL Server-specific functions
     */
    public void performOracleSpecificOperations() {
        // Example of creating a temporary table with SQL Server syntax
        String createTempTable = """
                IF OBJECT_ID('tempdb..#TEMP_TODO_STATS', 'U') IS NOT NULL
                   DROP TABLE #TEMP_TODO_STATS;

                CREATE TABLE #TEMP_TODO_STATS (
                   CATEGORY VARCHAR(100),
                   COUNT_VALUE INT,
                   LAST_UPDATED DATETIME
                );

                INSERT INTO #TEMP_TODO_STATS VALUES ('TOTAL', (SELECT COUNT(*) FROM TODO_ITEMS), GETDATE());
                INSERT INTO #TEMP_TODO_STATS VALUES ('COMPLETED', (SELECT COUNT(*) FROM TODO_ITEMS WHERE COMPLETED = 1), GETDATE());
                INSERT INTO #TEMP_TODO_STATS VALUES ('PENDING', (SELECT COUNT(*) FROM TODO_ITEMS WHERE COMPLETED = 0), GETDATE());
                INSERT INTO #TEMP_TODO_STATS VALUES ('HIGH_PRIORITY', (SELECT COUNT(*) FROM TODO_ITEMS WHERE PRIORITY >= 8), GETDATE());
                """;

        try {
            jdbcTemplate.execute(createTempTable);
            log.info("Successfully executed SQL Server T-SQL block to create and populate temporary statistics table");
        } catch (Exception e) {
            log.error("Error executing SQL Server T-SQL block", e);
        }
    }
}
