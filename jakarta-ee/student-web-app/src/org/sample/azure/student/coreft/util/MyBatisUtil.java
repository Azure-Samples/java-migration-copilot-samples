package org.sample.azure.student.coreft.util;

import com.ibatis.common.resources.Resources;
import com.ibatis.sqlmap.client.SqlMapClient;
import com.ibatis.sqlmap.client.SqlMapClientBuilder;

import java.io.Reader;

public class MyBatisUtil {
    private static SqlMapClient sqlMapClient;
    private static Exception initializationException;

    static {
        try {
            System.out.println("Initializing MyBatisUtil...");
            Reader reader = Resources.getResourceAsReader("sql-map-config.xml");
            sqlMapClient = SqlMapClientBuilder.buildSqlMapClient(reader);
            System.out.println("SqlMapClient initialized successfully!");

        } catch (Exception e) {
            initializationException = e;
            System.err.println("Failed to initialize SqlMapClient: " + e.getMessage());
            e.printStackTrace();
        }
    }

    public static SqlMapClient getSqlMapClient() {
        if (sqlMapClient == null) {
            throw new RuntimeException("SqlMapClient was not properly initialized. " + 
                                     (initializationException != null ? 
                                      "Initialization error: " + initializationException.getMessage() : 
                                      "Unknown initialization error"), 
                                     initializationException);
        }
        return sqlMapClient;
    }
}