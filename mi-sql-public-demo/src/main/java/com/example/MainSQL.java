package com.example;

import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.Properties;

import java.sql.*;

import com.microsoft.sqlserver.jdbc.SQLServerDataSource;

public class MainSQL {


    public static void main(String[] args) {
        
        Properties properties = new Properties();
        try (InputStream input = MainSQL.class.getClassLoader().getResourceAsStream("application.properties")) {
            if (input == null) {
                System.out.println("Sorry, unable to find application.properties");
                return;
            }
            // Load the properties file
            properties.load(input);
        } catch (IOException ex) {
            ex.printStackTrace();
            return;
        }

        String connString = properties.getProperty("AZURE_SQLDB_CONNECTIONSTRING");
        String clientId = properties.getProperty("AZURE_CLIENT_ID");
        
        connString = connString + ";msiClientId=" + clientId + ";authentication=ActiveDirectoryMSI";
        System.out.print(connString);
        
        SQLServerDataSource ds = new SQLServerDataSource();
        ds.setURL(connString);
        try (Connection connection = ds.getConnection()) {
            System.out.println("Connected successfully.");
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }

    
}