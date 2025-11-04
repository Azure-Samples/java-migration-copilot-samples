#!/bin/bash

# Setup script for Docker environment

echo "Setting up Docker environment for Student Web App..."

# Create mysql-connector directory if it doesn't exist
mkdir -p mysql-connector

# Create compile-lib directory if it doesn't exist
mkdir -p compile-lib

# Download compile-time dependencies if not present
if [ ! -f "compile-lib/servlet-api.jar" ]; then
    echo "Downloading Servlet API..."
    curl -L -o compile-lib/servlet-api.jar \
        https://repo1.maven.org/maven2/javax/servlet/javax.servlet-api/4.0.1/javax.servlet-api-4.0.1.jar
    
    if [ $? -eq 0 ]; then
        echo "Servlet API downloaded successfully"
    else
        echo "Failed to download Servlet API"
    fi
fi

if [ ! -f "compile-lib/javamail-api.jar" ]; then
    echo "Downloading JavaMail API..."
    curl -L -o compile-lib/javamail-api.jar \
        https://repo1.maven.org/maven2/javax/mail/javax.mail-api/1.6.2/javax.mail-api-1.6.2.jar
    
    if [ $? -eq 0 ]; then
        echo "JavaMail API downloaded successfully"
    else
        echo "Failed to download JavaMail API"
    fi
fi

# Download MySQL Connector/J if not present
if [ ! -f "mysql-connector/mysql-connector-j-8.0.33.jar" ]; then
    echo "Downloading MySQL Connector/J..."
    curl -L -o mysql-connector/mysql-connector-j-8.0.33.jar \
        https://repo1.maven.org/maven2/com/mysql/mysql-connector-j/8.0.33/mysql-connector-j-8.0.33.jar
    
    if [ $? -eq 0 ]; then
        echo "MySQL Connector/J downloaded successfully"
    else
        echo "Failed to download MySQL Connector/J. Please download it manually:"
        echo "URL: https://repo1.maven.org/maven2/com/mysql/mysql-connector-j/8.0.33/mysql-connector-j-8.0.33.jar"
        echo "Save it to: mysql-connector/mysql-connector-j-8.0.33.jar"
    fi
else
    echo "MySQL Connector/J already exists"
fi

# Build the application
echo "Building application..."
ant clean war

if [ $? -eq 0 ]; then
    echo "Application built successfully"
    echo ""
    echo "Ready to run with Docker!"
    echo "Use: docker-compose up --build"
    echo ""
    echo "Once running, access the application at:"
    echo "- Student: http://localhost:9080/"
else
    echo "Failed to build application"
    exit 1
fi
