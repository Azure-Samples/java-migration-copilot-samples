@echo off
echo Setting up Docker environment for Student Web App...

REM Create mysql-connector directory if it doesn't exist
if not exist "mysql-connector" mkdir mysql-connector

REM Create compile-lib directory if it doesn't exist
if not exist "compile-lib" mkdir compile-lib

REM Download compile-time dependencies if not present
if not exist "compile-lib\servlet-api.jar" (
    echo Downloading Servlet API...
    curl -L -o compile-lib\servlet-api.jar https://repo1.maven.org/maven2/javax/servlet/javax.servlet-api/4.0.1/javax.servlet-api-4.0.1.jar
    
    if %errorlevel% equ 0 (
        echo Servlet API downloaded successfully
    ) else (
        echo Failed to download Servlet API
    )
)

if not exist "compile-lib\javamail-api.jar" (
    echo Downloading JavaMail API...
    curl -L -o compile-lib\javamail-api.jar https://repo1.maven.org/maven2/javax/mail/javax.mail-api/1.6.2/javax.mail-api-1.6.2.jar
    
    if %errorlevel% equ 0 (
        echo JavaMail API downloaded successfully
    ) else (
        echo Failed to download JavaMail API
    )
)

REM Check if MySQL Connector/J exists
if not exist "mysql-connector\mysql-connector-j-8.0.33.jar" (
    echo Downloading MySQL Connector/J...
    curl -L -o mysql-connector\mysql-connector-j-8.0.33.jar https://repo1.maven.org/maven2/mysql/mysql-connector-java/8.0.33/mysql-connector-j-8.0.33.jar
    
    if %errorlevel% equ 0 (
        echo MySQL Connector/J downloaded successfully
    ) else (
        echo Failed to download MySQL Connector/J. Please download it manually:
        echo URL: https://repo1.maven.org/maven2/mysql/mysql-connector-java/8.0.33/mysql-connector-j-8.0.33.jar
        echo Save it to: mysql-connector\mysql-connector-j-8.0.33.jar
    )
) else (
    echo MySQL Connector/J already exists
)

REM Build the application
echo Building application...
ant clean war

if %errorlevel% equ 0 (
    echo Application built successfully
    echo.
    echo Ready to run with Docker!
    echo Use: docker-compose up --build
    echo.
    echo Once running, access the application at:
    echo - Student: http://localhost:9080/
) else (
    echo Failed to build application
    exit /b 1
)
