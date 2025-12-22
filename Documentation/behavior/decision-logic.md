# Decision Logic - Conditional Patterns

**Analysis Date:** December 2024  
**Method:** Static code analysis of conditional logic, branching patterns, and control flow  
**Total Projects Analyzed:** 8 (6 Java, 2 .NET)

---

## Table of Contents
- [Overview](#overview)
- [Decision Pattern Categories](#decision-pattern-categories)
- [Project-Specific Decision Logic](#project-specific-decision-logic)
- [Validation Decision Trees](#validation-decision-trees)
- [Error Handling Decisions](#error-handling-decisions)
- [Configuration-Based Decisions](#configuration-based-decisions)

---

## Overview

This document catalogs all conditional logic, branching patterns, and decision points across the codebase. Each decision is documented with:
- **Condition**: What triggers the decision
- **Actions**: Outcomes for each branch
- **Location**: Where in code it's implemented
- **Business Impact**: Why this decision exists

---

## Decision Pattern Categories

### Primary Decision Types
| Pattern Type | Count | Description | Projects |
|--------------|-------|-------------|----------|
| **Validation Decisions** | 40+ | Input validation and constraint checking | All projects |
| **Profile-Based Decisions** | 5+ | Environment/profile-based routing | asset-manager |
| **Type-Based Routing** | 8+ | Polymorphic behavior based on type | Malshinon, todo-web-api |
| **Search/Filter Decisions** | 15+ | Query construction based on parameters | ContosoUniversity, todo-web-api |
| **Error Handling Decisions** | 30+ | Exception handling and error recovery | All projects |
| **Authentication Decisions** | 3+ | Auth method selection | mi-sql-public-demo |
| **Storage Backend Selection** | 5+ | Choose storage provider | asset-manager |

---

## Project-Specific Decision Logic

### 1. mi-sql-public-demo

#### Authentication Method Decision
```
IF Azure Managed Identity available
  THEN use MI token for authentication
  ELSE throw error (no fallback authentication)
```
**Location**: `MainSQL.java` - token acquisition logic  
**Impact**: Security - enforce credential-less authentication

#### Connection Strategy Decision
```
IF SSL enabled in configuration
  THEN use encrypted connection
  ELSE use unencrypted connection (dev only)
```
**Location**: Connection string builder  
**Impact**: Security - protect data in transit

---

### 2. asset-manager

#### Storage Backend Selection (Web Module)
```
IF Spring profile contains "aws"
  THEN
    - Use S3Service for file storage
    - Upload files to AWS S3
    - Store S3 URL in metadata
    - Publish message to RabbitMQ for processing
  ELSE
    - Use LocalFileStorageService
    - Store files in local filesystem
    - Store local file path in metadata
    - Skip RabbitMQ message publishing
```
**Location**: `S3Controller` - profile-based bean injection  
**Impact**: Environment flexibility - support dev/prod environments

#### File Upload Validation Decision
```
IF file is null OR file.isEmpty()
  THEN
    - Return 400 Bad Request
    - Error message: "File cannot be empty"
  ELSE
    - Proceed with upload
```
**Location**: `S3Controller.upload()` method  
**Impact**: Data quality - reject invalid uploads

#### File Size Decision
```
IF file.getSize() > MAX_FILE_SIZE (10MB)
  THEN
    - Reject upload
    - Return 413 Payload Too Large
  ELSE
    - Accept upload
```
**Location**: Spring `@RequestParam` configuration  
**Impact**: Performance - prevent memory issues

#### Storage Directory Decision (Local Storage)
```
IF storage directory does not exist
  THEN
    - Create directory structure
    - Log directory creation
  ELSE
    - Use existing directory
```
**Location**: `LocalFileStorageService` initialization  
**Impact**: Reliability - auto-configure storage

#### Filename Uniqueness Decision
```
ALWAYS generate unique filename:
  - newFilename = UUID.randomUUID() + extractExtension(originalFilename)
```
**Location**: `StorageService` implementations  
**Impact**: Data integrity - prevent file collisions

#### Message Publishing Decision (Web Module)
```
IF AWS profile active
  THEN
    TRY
      - Publish message to RabbitMQ with file metadata
      - Log success
    CATCH exception
      - Log error (but continue - upload still succeeds)
  ELSE
    - Skip message publishing
```
**Location**: `S3Controller` after successful upload  
**Impact**: Resilience - upload succeeds even if queue fails

#### Thumbnail Processing Decision (Worker Module)
```
ON message received:
  TRY
    - Download image from S3
    - Generate thumbnail (200px width)
    - Upload thumbnail to S3
    - Update metadata with thumbnail URL
    - Acknowledge message
  CATCH IOException
    - Log error "Failed to download image"
    - Acknowledge message (discard - file missing)
  CATCH ImageProcessingException
    - Log error "Failed to process image"
    - Acknowledge message (discard - corrupted image)
  CATCH Exception
    - Log error
    - Reject message (requeue for retry)
```
**Location**: `ThumbnailProcessor` message listener  
**Impact**: Resilience - handle failures gracefully

---

### 3. todo-web-api-use-oracle-db

#### Todo Item Validation Decision
```
IF title is null OR title.isBlank()
  THEN throw ValidationException("Title is required")
  
IF title.length() > 200
  THEN throw ValidationException("Title max 200 characters")
  
IF description != null AND description.length() > 4000
  THEN throw ValidationException("Description max 4000 characters")
  
ELSE proceed with creation
```
**Location**: Bean Validation in `TodoItem` entity  
**Impact**: Data integrity - enforce Oracle VARCHAR2 limits

#### Query Method Selection Decision
```
SWITCH query type:
  CASE "all":
    - Use findAll()
  CASE "byCompleted":
    - Use findByCompleted(completed)
  CASE "byPriority":
    - Use findByPriorityGreaterThanEqual(minPriority)
  CASE "byKeyword":
    - Use findByKeyword(keyword)
  CASE "overdue":
    - Use getOverdueTasks() with Oracle SYSDATE
  DEFAULT:
    - Return all todos
```
**Location**: `TodoService` query methods  
**Impact**: Flexibility - support multiple query patterns

#### Update Existence Check Decision
```
IF todoRepository.findById(id) is empty
  THEN throw RuntimeException("Todo not found with id " + id)
  ELSE
    - Update todo fields
    - Save to database
```
**Location**: `TodoService.updateTodo()` method  
**Impact**: Data integrity - prevent silent failures

#### Oracle-Specific Query Decision
```
IF searching large text fields (VARCHAR2 > 1000 chars)
  THEN use DBMS_LOB.INSTR for efficient search
  ELSE use standard LIKE operator
```
**Location**: `TodoService.searchWithOracleVarchar2()` method  
**Impact**: Performance - leverage Oracle LOB functions

#### Overdue Task Sorting Decision
```
FOR overdue tasks:
  - ORDER BY priority DESC (highest priority first)
  - THEN BY due_date ASC (earliest deadline first)
```
**Location**: `TodoService.getOverdueTasks()` native query  
**Impact**: Business priority - urgent tasks first

---

### 4. rabbitmq-sender

#### Message Publishing Decision
```
TRY
  - Convert message to JSON
  - Send to configured queue/exchange
  - Log success
CATCH AmqpException
  - Log error "Failed to publish message"
  - Throw exception (let caller handle)
```
**Location**: Message sender service  
**Impact**: Error propagation - caller decides retry strategy

---

### 5. jakarta-ee/student-web-app

#### Student Creation Validation Decision
```
IF name is blank
  THEN
    - Add field error
    - Return to form
    
IF email is blank OR email format invalid
  THEN
    - Add field error
    - Return to form
    
IF enrollmentDate is null
  THEN
    - Add field error
    - Return to form
    
IF enrollmentDate > today
  THEN
    - Add field error: "Cannot enroll in future"
    - Return to form
    
IF email already exists in database
  THEN
    - Add error: "Email already registered"
    - Return to form
    
ELSE
  - Save student
  - Redirect to student list
```
**Location**: Controller form submission handler  
**Impact**: Data quality - comprehensive validation

#### MyBatis Query Decision
```
IF search parameter is not null
  THEN add WHERE clause with search condition
  ELSE return all students
  
IF pagination parameters provided
  THEN add LIMIT and OFFSET to query
  ELSE return all results (no pagination)
```
**Location**: MyBatis XML mapper  
**Impact**: Performance - conditional query building

---

### 6. ContosoUniversity

#### Student Search Decision
```
IF searchString is not null AND not empty
  THEN
    - Filter students WHERE 
      - LastName.ToLower().Contains(searchString.ToLower())
      - OR FirstMidName.ToLower().Contains(searchString.ToLower())
  ELSE
    - Return all students
```
**Location**: `StudentsController.Index()` method  
**Impact**: Usability - flexible search

#### Sort Order Decision
```
SWITCH sortOrder:
  CASE "name_desc":
    - ORDER BY LastName DESC
  CASE "Date":
    - ORDER BY EnrollmentDate ASC
  CASE "date_desc":
    - ORDER BY EnrollmentDate DESC
  DEFAULT:
    - ORDER BY LastName ASC (default sort)
```
**Location**: `StudentsController.Index()` method  
**Impact**: Usability - multiple sorting options

#### Pagination Decision
```
IF pageNumber is null OR pageNumber < 1
  THEN pageNumber = 1
  
totalPages = CEILING(totalStudents / pageSize)

IF pageNumber > totalPages
  THEN pageNumber = totalPages
  
RETURN students.Skip((pageNumber - 1) * pageSize).Take(pageSize)
```
**Location**: `PaginatedList<T>` helper  
**Impact**: Performance - avoid loading all records

#### Enrollment Date Validation Decision
```
IF enrollmentDate == DateTime.MinValue
  THEN
    - Add model error: "Invalid enrollment date"
    - Return to form
    
IF enrollmentDate.Year < 1753 OR enrollmentDate.Year > 9999
  THEN
    - Add model error: "Date out of valid range"
    - Return to form
    
ELSE
  - Accept enrollment date
```
**Location**: `StudentsController` validation  
**Impact**: Data integrity - SQL Server datetime2 constraints

#### Concurrency Conflict Decision
```
TRY
  - Save department changes
CATCH DbUpdateConcurrencyException
  - Reload current database values
  - IF entity no longer exists
    THEN redirect with "Entity deleted" message
    ELSE
      - Show current values
      - Allow user to retry with fresh data
```
**Location**: `DepartmentsController.Edit()` method  
**Impact**: Data integrity - handle concurrent updates

#### Course Credits Validation Decision
```
IF credits < 0 OR credits > 5
  THEN
    - Add validation error
    - Return to form
  ELSE
    - Accept credits value
```
**Location**: `Course` entity `[Range(0, 5)]` validation  
**Impact**: Business rule - academic credit limits

#### Cascade Delete Decision
```
IF deleting student
  THEN
    - Entity Framework automatically deletes related enrollments
    - Due to OnDelete(DeleteBehavior.Cascade) configuration
```
**Location**: EF relationship configuration  
**Impact**: Data integrity - no orphan enrollments

---

### 7. Malshinon

#### Processor Type Selection Decision
```
SWITCH processorType:
  CASE "CSV":
    RETURN new CSVProcessor()
  CASE "Excel":
    RETURN new ExcelProcessor()
  CASE "JSON":
    RETURN new JSONProcessor()
  DEFAULT:
    THROW ArgumentException("Unknown processor type")
```
**Location**: `DataProcessorFactory.CreateProcessor()` method  
**Impact**: Extensibility - polymorphic processing

#### File Extension Detection Decision
```
IF filename.EndsWith(".csv")
  THEN processorType = "CSV"
ELSE IF filename.EndsWith(".xls") OR filename.EndsWith(".xlsx")
  THEN processorType = "Excel"
ELSE IF filename.EndsWith(".json")
  THEN processorType = "JSON"
ELSE
  THROW NotSupportedException("Unsupported file type")
```
**Location**: File type detection logic  
**Impact**: Usability - automatic type detection

#### CSV Field Parsing Decision
```
FOR each field in CSV row:
  IF field contains comma AND field is quoted
    THEN
      - Keep field intact
      - Remove surrounding quotes
    ELSE
      - Split by comma
```
**Location**: CSVProcessor parsing logic  
**Impact**: Data quality - handle commas in data

#### Excel Format Decision
```
IF file extension is ".xls"
  THEN use HSSF workbook (old format)
ELSE IF file extension is ".xlsx"
  THEN use XSSF workbook (new format)
```
**Location**: ExcelProcessor initialization  
**Impact**: Compatibility - support multiple Excel versions

---

## Validation Decision Trees

### File Upload Validation (asset-manager)
```
┌─────────────────────────┐
│   File Upload Request   │
└───────────┬─────────────┘
            │
            ├─── Is file null? ─── YES ──> Return 400 "No file provided"
            │
            NO
            │
            ├─── Is file empty? ─── YES ──> Return 400 "File cannot be empty"
            │
            NO
            │
            ├─── Size > 10MB? ─── YES ──> Return 413 "File too large"
            │
            NO
            │
            ├─── Is AWS profile active? 
            │           │
            │           ├─── YES ──> Upload to S3 + Publish to RabbitMQ
            │           │
            │           └─── NO ──> Store locally (no message)
            │
            └─── Save metadata to DB ──> Return 200 with upload response
```

### Todo Item Creation (todo-web-api)
```
┌─────────────────────────┐
│  Todo Creation Request  │
└───────────┬─────────────┘
            │
            ├─── Is title blank? ─── YES ──> Return 400 "Title required"
            │
            NO
            │
            ├─── Title > 200 chars? ─── YES ──> Return 400 "Title too long"
            │
            NO
            │
            ├─── Description > 4000 chars? ─── YES ──> Return 400 "Description too long"
            │
            NO
            │
            ├─── Set defaults: completed=false, priority=0
            │
            ├─── Auto-generate timestamps
            │
            └─── Save to Oracle DB ──> Return 201 with created todo
```

### Student Search (ContosoUniversity)
```
┌─────────────────────────┐
│   Student Search        │
└───────────┬─────────────┘
            │
            ├─── Is searchString empty? ─── YES ──> Get all students
            │                                │
            NO                               │
            │                                │
            ├─── Filter by LastName OR FirstMidName (case-insensitive)
            │
            ├─── Apply sort order (name/date, asc/desc)
            │
            ├─── Calculate pagination (skip/take)
            │
            └─── Return paginated results with metadata
```

---

## Error Handling Decisions

### Exception Handling Patterns by Project

#### asset-manager
```
CATCH IOException (File operations)
  ──> Log error + Return 500 "File operation failed"
  
CATCH S3Exception (AWS S3 errors)
  ──> Log error + Return 500 "Storage service unavailable"
  
CATCH AmqpException (RabbitMQ errors)
  ──> Log error + Continue (upload still succeeds)
  
CATCH ImageProcessingException (Worker)
  ──> Log error + Acknowledge message (discard corrupted image)
```

#### todo-web-api
```
CATCH EntityNotFoundException
  ──> Return 404 "Todo not found"
  
CATCH ValidationException
  ──> Return 400 with validation errors
  
CATCH SQLException
  ──> Log error + Return 500 "Database error"
```

#### ContosoUniversity
```
CATCH DbUpdateConcurrencyException
  ──> Reload data + Show conflict resolution UI
  
CATCH DbUpdateException
  ──> Log error + Return user-friendly message
  
CATCH EntityNotFoundException
  ──> Return 404 "Entity not found"
```

#### mi-sql-public-demo
```
CATCH SQLException
  ──> Log error + Terminate (cannot recover)
  
CATCH AuthenticationException
  ──> Log error + Terminate (no fallback auth)
```

---

## Configuration-Based Decisions

### Profile-Based Routing (asset-manager)
| Configuration | Storage | Messaging | Behavior |
|--------------|---------|-----------|----------|
| **Profile: aws** | AWS S3 | RabbitMQ enabled | Production mode |
| **Profile: local** | Local filesystem | RabbitMQ disabled | Development mode |
| **Profile: test** | In-memory (mock) | Mock queue | Testing mode |

### Database Selection (All Projects)
| Configuration | Database | Driver | Behavior |
|--------------|----------|--------|----------|
| **Oracle profile** | Oracle DB | ojdbc11 | Use Oracle-specific SQL |
| **PostgreSQL profile** | PostgreSQL | postgresql | Standard SQL |
| **SQL Server profile** | SQL Server | mssql-jdbc | Use T-SQL features |
| **H2 profile** | H2 in-memory | h2 | Testing only |

### Logging Level Decisions
```
IF environment == "production"
  THEN logLevel = INFO (hide DEBUG logs)
ELSE IF environment == "development"
  THEN logLevel = DEBUG (verbose logging)
ELSE IF environment == "test"
  THEN logLevel = WARN (minimal logging)
```

---

## Decision Logic Complexity

### Complexity by Project
| Project | Decision Points | Complexity | Critical Decisions |
|---------|----------------|------------|-------------------|
| **ContosoUniversity** | 25+ | High | Search, sort, pagination, concurrency |
| **asset-manager** | 20+ | High | Storage selection, messaging, error handling |
| **todo-web-api** | 18+ | Medium | Validation, query selection, Oracle-specific |
| **student-web-app** | 15+ | Medium | Validation, MyBatis routing |
| **Malshinon** | 10+ | Medium | Type routing, format detection |
| **mi-sql-public-demo** | 5+ | Low | Auth method, connection |
| **rabbitmq-sender** | 3+ | Low | Message publishing |

---

**Related Documentation:**
- [Business Logic](business-logic.md) - Domain rules driving these decisions
- [Workflows](workflows.md) - How decisions combine into workflows
- [Error Handling](error-handling.md) - Exception handling patterns
- [Program Structure](../reference/program-structure.md) - Code locations of decision points
