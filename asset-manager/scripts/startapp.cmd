@echo off
setlocal

rem Get the directory where the script is located
set SCRIPT_DIR=%~dp0
set PROJECT_ROOT=%SCRIPT_DIR%..

if not defined AZURE_SERVICEBUS_NAMESPACE (
    echo Set AZURE_SERVICEBUS_NAMESPACE to your Azure Service Bus namespace before starting the apps.
    exit /b 1
)

echo Starting PostgreSQL container...
docker run -d --name assets-postgres -e POSTGRES_DB=assets_manager -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=postgres -p 5432:5432 postgres:latest

echo Waiting for PostgreSQL to start...
timeout /t 10 /nobreak

rem Create logs directory if it doesn't exist
if not exist "%PROJECT_ROOT%\logs" mkdir "%PROJECT_ROOT%\logs"

rem Create pids directory if it doesn't exist
if not exist "%PROJECT_ROOT%\pids" mkdir "%PROJECT_ROOT%\pids"

echo Starting web module...
cd /d "%PROJECT_ROOT%\web"
start "Web Module" cmd /k "%PROJECT_ROOT%\mvnw.cmd clean spring-boot:run -Dspring-boot.run.jvmArguments=-Dspring.pid.file=%PROJECT_ROOT%\pids\web.pid -Dspring-boot.run.profiles=dev"

echo Starting worker module...
cd /d "%PROJECT_ROOT%\worker"
start "Worker Module" cmd /k "%PROJECT_ROOT%\mvnw.cmd clean spring-boot:run -Dspring-boot.run.jvmArguments=-Dspring.pid.file=%PROJECT_ROOT%\pids\worker.pid -Dspring-boot.run.profiles=dev"

echo Web application: http://localhost:8080
echo Authenticate to Azure before starting, for example by running az login.
