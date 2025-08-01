# Migration Plan: Ant to Maven Project Conversion

**Plan Creation Timestamp:** 2025-08-01 15:07:25

## Project Overview
Migrating a legacy Java EE web application from Ant build system to Maven, with the following characteristics:
- **Project Type:** WAR (Web Application)
- **Current Build Tool:** Apache Ant
- **Target Build Tool:** Maven
- **Java Version:** 11
- **Application Server:** Open Liberty
- **Frameworks:** Spring MVC, MyBatis/iBATIS, Log4j

## Migration Strategy
Following the knowledge base guidelines "Migrate ant project to maven project" (KB ID: ant-project-to-maven-project)

## Dependencies Analysis
Based on project analysis, the following dependencies are used:
- **Web APIs:** javax.servlet-api (Java EE 8)
- **Spring Framework:** 5.3.x (Spring MVC, Context)
- **Data Access:** iBATIS SqlMaps (legacy MyBatis)
- **Logging:** Log4j 1.x
- **Database:** MySQL (via JDBC)
- **Mail:** JavaMail API

## File Dependencies Analysis
Based on code analysis, the dependency order for file changes:

1. **Configuration Files** (No dependencies)
   - `resources/sql-map-config.xml`
   - `resources/applicationContext-service.xml`
   - `resources/ca/on/gov/edu/msfaa/shared/persistence/xml/Student_SqlMap.xml`

2. **Utility Classes** (No dependencies)
   - `src/ca/on/gov/edu/coreft/util/MyBatisUtil.java`

3. **Model Classes** (No dependencies)
   - `src/ca/on/gov/edu/coreft/StudentProfile.java`

4. **Service Layer** (Depends on Model, Util)
   - `src/ca/on/gov/edu/coreft/service/StudentService.java`

5. **Controller Layer** (Depends on Service, Model)
   - `src/ca/on/gov/edu/coreft/controller/StudentController.java`
   - `src/ca/on/gov/edu/coreft/controller/AddStudentController.java`

6. **Servlet Layer** (Depends on Model, Util)
   - `src/ca/on/gov/edu/coreft/IndexServlet.java`
   - `src/ca/on/gov/edu/coreft/AddStudentServlet.java`
   - `src/ca/on/gov/edu/coreft/StudentProfileListServlet.java`

7. **Filter Layer** (Standalone)
   - `src/ca/on/gov/edu/coreft/filter/CommonHttpServletFilter.java`

## Migration Tasks

### 1. Create Maven Project Structure
- [X] Create `pom.xml` with proper configuration
- [X] Create Maven standard directory structure:
  - `src/main/java/` (Java source files)
  - `src/main/resources/` (Configuration files)
  - `src/main/webapp/` (Web content)
  - `src/test/java/` (Test files)

### 2. Move Source Files to Maven Structure
- [X] Move `src/ca/**/*.java` → `src/main/java/ca/`
- [X] Move `resources/**` → `src/main/resources/`
- [X] Move `WebContent/**` → `src/main/webapp/`

### 3. Configure Maven Dependencies
- [X] Add servlet-api dependency (provided scope)
- [X] Add Spring Framework dependencies
- [X] Add iBATIS/MyBatis dependencies
- [X] Add Log4j dependencies
- [X] Add MySQL connector
- [X] Add JavaMail dependencies
- [X] Add Jackson dependencies for JSON processing

### 4. Configure Maven Plugins
- [X] Configure maven-compiler-plugin (Java 11)
- [X] Configure maven-war-plugin for WAR packaging
- [X] Configure proper resource filtering

### 5. Update Configuration Files
- [X] Update resource references in configuration files
- [X] Ensure web.xml is properly placed in `src/main/webapp/WEB-INF/`
- [X] Update Spring configuration files
- [X] Update Jackson import to use newer fasterxml package

### 6. Clean Up Ant Build Files
- [X] Remove `build.xml`
- [X] Remove `build.properties`
- [X] Remove old directory structure (`src/ca`, `resources/`, `WebContent/`)

### 7. Build and Validation
- [X] Build project with Maven
- [X] Resolve any compilation issues
- [X] Verify WAR structure
- [X] Test application functionality

## Final Status: **MIGRATION COMPLETED SUCCESSFULLY**

### Build Results:
- ✅ **Maven build successful**: `mvn clean package` completed without errors
- ✅ **WAR file generated**: `target/OpenLibertyApp.war` created with correct structure
- ✅ **Dependencies resolved**: All Maven dependencies downloaded and configured properly
- ✅ **Compilation successful**: All 9 Java source files compiled successfully
- ✅ **Resource processing**: All configuration files copied to correct locations

### Files Modified:
- **Created**: `pom.xml` - Maven project configuration with all required dependencies
- **Created**: Maven directory structure (`src/main/java`, `src/main/resources`, `src/main/webapp`, `src/test/java`)
- **Updated**: `StudentProfileListServlet.java` - Changed Jackson import from `org.codehaus.jackson.map.ObjectMapper` to `com.fasterxml.jackson.databind.ObjectMapper`
- **Moved**: All Java source files to `src/main/java/ca/`
- **Moved**: All resource files to `src/main/resources/`
- **Moved**: All web content to `src/main/webapp/`
- **Removed**: `build.xml`, `build.properties`, old directory structure

## Expected Changes Summary

### Files to be Created:
- `pom.xml` - Maven project configuration
- Maven directory structure

### Files to be Moved:
- All Java source files: `src/` → `src/main/java/`
- All resource files: `resources/` → `src/main/resources/`
- All web content: `WebContent/` → `src/main/webapp/`

### Files to be Removed:
- `build.xml` - Ant build file
- `build.properties` - Ant properties file

### Files to be Updated:
- Configuration files may need path updates if any absolute references exist

## Success Criteria
- [ ] Project builds successfully with `mvn clean package`
- [ ] Generated WAR file has correct structure
- [ ] All dependencies are properly resolved
- [ ] Application deploys and runs correctly
- [ ] No compilation errors or warnings

## Notes
- The project uses iBATIS (legacy MyBatis), which may need special attention for dependency resolution
- Spring configuration is XML-based and should be preserved during migration
- Log4j 1.x is being used, which is EOL but will be maintained during this migration
- The project supports both traditional servlets and Spring MVC controllers

---
**Status:** Plan Created - Awaiting User Confirmation
