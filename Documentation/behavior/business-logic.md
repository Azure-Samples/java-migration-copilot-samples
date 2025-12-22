# Business Logic - Domain Rules and Operations

**Analysis Date:** December 2024  
**Method:** Static code analysis of controllers, services, and business logic layers  
**Total Projects Analyzed:** 8 (6 Java, 2 .NET)

---

## Table of Contents
- [Overview](#overview)
- [Cross-Cutting Business Rules](#cross-cutting-business-rules)
- [Project-Specific Business Logic](#project-specific-business-logic)
  - [mi-sql-public-demo](#1-mi-sql-public-demo)
  - [asset-manager](#2-asset-manager)
  - [todo-web-api](#3-todo-web-api-use-oracle-db)
  - [rabbitmq-sender](#4-rabbitmq-sender)
  - [jakarta-ee student-web-app](#5-jakarta-ee-student-web-app)
  - [ContosoUniversity](#6-contosouniversity)
  - [Malshinon](#7-malshinon)
- [Business Rule Categories](#business-rule-categories)
- [Validation Rules Matrix](#validation-rules-matrix)

---

## Overview

This document extracts and catalogs business rules, domain logic, validation patterns, and operational workflows implemented across the codebase. Each business rule is documented with:
- **Rule Description**: What the rule enforces
- **Implementation Location**: Where in code it's implemented
- **Validation Method**: How it's validated
- **Business Impact**: Why this rule exists

---

## Cross-Cutting Business Rules

### Data Integrity Rules
| Rule | Description | Implementation | Projects |
|------|-------------|----------------|----------|
| Auto-Timestamp Creation | All entities automatically capture creation timestamp | JPA `@PrePersist`, EF `CreatedAt` | All with databases |
| Auto-Timestamp Update | All entities automatically update modification timestamp | JPA `@PreUpdate`, EF `UpdatedAt` | All with databases |
| Soft Delete | Entities marked as deleted rather than removed | `deleted` flag field | ContosoUniversity |
| Audit Trail | Track who created/modified records | `createdBy`, `modifiedBy` fields | ContosoUniversity |

### Validation Rules (Common)
| Rule | Description | Standard | Projects |
|------|-------------|----------|----------|
| Required Fields | Critical fields cannot be null/empty | Bean Validation `@NotNull`, `@NotBlank` | All Java projects |
| String Length Limits | Prevent database overflow | `@Size(max=N)` annotations | All projects |
| Email Format | Email fields must be valid format | `@Email` validation | student-web-app, ContosoUniversity |
| Date Range Validation | Dates must fall within acceptable ranges | Custom validators | ContosoUniversity |

---

## Project-Specific Business Logic

### 1. mi-sql-public-demo

**Domain**: Azure Managed Identity authentication demonstration  
**Business Purpose**: Demonstrate credential-less database access using Azure-managed identities

#### Business Rules

##### Authentication Rules
| Rule ID | Rule | Implementation | Business Rationale |
|---------|------|----------------|-------------------|
| AUTH-001 | Application MUST use Azure Managed Identity for SQL authentication | `MainSQL.java` - Azure Identity SDK integration | Security: No credentials in code or config |
| AUTH-002 | Token acquisition MUST succeed before database connection | Token retrieval in `main()` method | Fail-fast: Detect auth issues immediately |
| AUTH-003 | Connection string MUST NOT contain username/password | Connection string builder excludes credentials | Security: Enforce Azure AD authentication |

##### Connection Rules
| Rule ID | Rule | Implementation | Business Rationale |
|---------|------|----------------|-------------------|
| CONN-001 | Connection MUST use encrypted channel (SSL) | JDBC connection string with `encrypt=true` | Security: Protect data in transit |
| CONN-002 | Connection timeout set to 30 seconds | Connection string parameter | Reliability: Prevent hung connections |
| CONN-003 | Connection MUST validate server certificate | SSL certificate validation | Security: Prevent MITM attacks |

##### Query Execution Rules
| Rule ID | Rule | Implementation | Business Rationale |
|---------|------|----------------|-------------------|
| QUERY-001 | Use prepared statements for all queries | `PreparedStatement` usage | Security: Prevent SQL injection |
| QUERY-002 | Close all database resources in finally block | try-with-resources | Resource management: Prevent leaks |

---

### 2. asset-manager

**Domain**: Cloud-based asset (image/file) management with asynchronous processing  
**Business Purpose**: Upload, store, and process files with cloud storage and message queue integration

#### Business Rules

##### File Upload Rules (Web Module)
| Rule ID | Rule | Implementation | Business Rationale |
|---------|------|----------------|-------------------|
| UPLOAD-001 | Files MUST NOT be empty | `S3Controller` - `file.isEmpty()` check | Data quality: Reject meaningless uploads |
| UPLOAD-002 | File size MUST NOT exceed 10MB | Spring `@RequestParam` with size limit | Performance: Prevent memory issues |
| UPLOAD-003 | Original filename MUST be captured in metadata | `AssetMetadata.filename` field | Traceability: Preserve original file info |
| UPLOAD-004 | Content type MUST be captured | `AssetMetadata.contentType` field | File classification: Enable type-based processing |
| UPLOAD-005 | File size MUST be recorded | `AssetMetadata.size` field | Storage management: Track usage |
| UPLOAD-006 | Upload timestamp MUST be recorded | `AssetMetadata.uploadedAt` field (auto) | Audit: Track when files uploaded |

##### Storage Selection Rules
| Rule ID | Rule | Implementation | Business Rationale |
|---------|------|----------------|-------------------|
| STORAGE-001 | IF AWS profile active THEN use S3, ELSE use local storage | `StorageService` profile-based bean selection | Environment flexibility: Support dev/prod |
| STORAGE-002 | Local storage directory MUST be created if missing | `LocalFileStorageService` - directory creation | Reliability: Auto-configure storage |
| STORAGE-003 | S3 bucket name MUST be configurable | `application.yml` property | Configuration: Environment-specific buckets |
| STORAGE-004 | S3 region MUST be configurable | `application.yml` property | Configuration: Compliance (data residency) |

##### Filename Handling Rules
| Rule ID | Rule | Implementation | Business Rationale |
|---------|------|----------------|-------------------|
| FILENAME-001 | Generate unique filename using UUID | `UUID.randomUUID()` + original extension | Uniqueness: Prevent collisions |
| FILENAME-002 | Preserve file extension from original | Extract extension from `getOriginalFilename()` | Compatibility: Maintain file type |
| FILENAME-003 | Remove special characters from filenames | Filename sanitization | Security: Prevent path traversal |

##### Messaging Rules (Web Module)
| Rule ID | Rule | Implementation | Business Rationale |
|---------|------|----------------|-------------------|
| MSG-001 | Publish RabbitMQ message ONLY if AWS profile active | Profile conditional in upload logic | Cost efficiency: No processing in dev |
| MSG-002 | Message MUST contain file metadata (filename, S3 key, size) | `RabbitTemplate.send()` with JSON payload | Worker requirements: Need info for processing |
| MSG-003 | Message publishing failure MUST NOT fail upload | Try-catch around message publishing | Resilience: Upload succeeds even if queue down |
| MSG-004 | Queue name MUST be configurable | `application.yml` property | Configuration: Environment-specific queues |

##### Metadata Persistence Rules
| Rule ID | Rule | Implementation | Business Rationale |
|---------|------|----------------|-------------------|
| META-001 | Metadata MUST be saved to database | `AssetMetadataRepository.save()` | Traceability: Track all uploads |
| META-002 | S3 URL MUST be stored in metadata | `AssetMetadata.s3Url` field | Access: Enable file retrieval |
| META-003 | Database save MUST succeed before response | Synchronous repository call | Data integrity: Ensure persistence |

##### Thumbnail Processing Rules (Worker Module)
| Rule ID | Rule | Implementation | Business Rationale |
|---------|------|----------------|-------------------|
| THUMB-001 | Worker MUST consume messages from RabbitMQ | `@RabbitListener` annotation | Async processing: Decouple upload from processing |
| THUMB-002 | Image MUST be downloaded from S3 before processing | `S3Client.getObject()` call | Processing requirement: Need source file |
| THUMB-003 | Thumbnail width MUST be 200px (maintain aspect ratio) | Image processing library configuration | Standardization: Consistent thumbnail size |
| THUMB-004 | Thumbnail MUST be uploaded to S3 | `S3Client.putObject()` for thumbnail | Storage: Make thumbnail accessible |
| THUMB-005 | Thumbnail S3 key MUST have "-thumbnail" suffix | Key generation logic | Organization: Distinguish originals from thumbnails |
| THUMB-006 | Metadata MUST be updated with thumbnail URL | `AssetMetadataRepository.save()` update | Linking: Associate thumbnail with original |
| THUMB-007 | Corrupted image MUST NOT crash worker | Try-catch around image processing | Resilience: Continue processing other messages |
| THUMB-008 | Failed processing MUST log error and acknowledge message | Error logging + message acknowledgment | Observability + queue management |

---

### 3. todo-web-api-use-oracle-db

**Domain**: Task management with Oracle Database  
**Business Purpose**: CRUD operations for todo items with Oracle-specific features

#### Business Rules

##### Todo Item Creation Rules
| Rule ID | Rule | Implementation | Business Rationale |
|---------|------|----------------|-------------------|
| TODO-001 | Title MUST NOT be null or blank | `@NotBlank` on `TodoItem.title` | Data quality: All tasks need description |
| TODO-002 | Title MUST NOT exceed 200 characters | `@Size(max=200)` on `TodoItem.title` | Database constraint: Oracle VARCHAR2(200) |
| TODO-003 | Description MUST NOT exceed 4000 characters | `@Size(max=4000)` on `TodoItem.description` | Database constraint: Oracle VARCHAR2(4000) |
| TODO-004 | Description is optional (can be null) | No `@NotNull` on `description` | Flexibility: Allow quick task creation |
| TODO-005 | Completed flag defaults to FALSE | `@Column` default value | Workflow: New tasks are incomplete |
| TODO-006 | Priority defaults to 0 (normal) | `@Column` default value | Workflow: Default to standard priority |
| TODO-007 | Creation timestamp auto-generated | `@Column(updatable=false)` + `@PrePersist` | Audit: Track creation time |
| TODO-008 | Update timestamp auto-updated | `@PreUpdate` callback | Audit: Track last modification |

##### Todo Item Query Rules
| Rule ID | Rule | Implementation | Business Rationale |
|---------|------|----------------|-------------------|
| QUERY-001 | Search by keyword MUST check title AND description | `findByKeyword()` with OR condition | Usability: Comprehensive search |
| QUERY-002 | High priority filter threshold configurable | `findByPriorityGreaterThanEqual(minPriority)` | Flexibility: User-defined priority cutoffs |
| QUERY-003 | Overdue tasks query uses Oracle SYSDATE | Native query with `SYSDATE` | Oracle-specific: Leverage DB function |
| QUERY-004 | Overdue tasks sorted by priority DESC, then due date ASC | `ORDER BY PRIORITY DESC, DUE_DATE ASC` | Workflow: Most urgent first |
| QUERY-005 | Completed filter MUST use boolean 0/1 for Oracle | `COMPLETED = 0` in native query | Oracle compatibility: Boolean as number |

##### Todo Item Update Rules
| Rule ID | Rule | Implementation | Business Rationale |
|---------|------|----------------|-------------------|
| UPDATE-001 | Update MUST fail if ID not found | `orElseThrow(RuntimeException)` | Data integrity: Prevent silent failures |
| UPDATE-002 | All fields (except ID and timestamps) can be updated | `setTitle()`, `setDescription()`, etc. | Flexibility: Allow full updates |
| UPDATE-003 | Update timestamp MUST be refreshed | `@PreUpdate` trigger | Audit: Track modification time |
| UPDATE-004 | Bulk priority update uses Oracle SYSTIMESTAMP | Native query with `SYSTIMESTAMP` | Oracle-specific: DB-level timestamp |

##### Todo Item Search Rules (Oracle-Specific)
| Rule ID | Rule | Implementation | Business Rationale |
|---------|------|----------------|-------------------|
| SEARCH-001 | VARCHAR2 search uses DBMS_LOB.INSTR for large text | `DBMS_LOB.INSTR(TITLE, :searchTerm)` | Oracle optimization: Efficient LOB search |
| SEARCH-002 | Search MUST be case-sensitive (Oracle default) | No UPPER() conversion | Performance: Leverage indexes |

##### Due Date Rules
| Rule ID | Rule | Implementation | Business Rationale |
|---------|------|----------------|-------------------|
| DUEDATE-001 | Due date is optional (can be null) | Nullable field | Flexibility: Not all tasks have deadlines |
| DUEDATE-002 | Overdue tasks identified by comparing to current date | `DUE_DATE < SYSDATE` | Business logic: Past due = overdue |
| DUEDATE-003 | Future-dated tasks included in queries | No upper bound filter | Planning: Show future work |

---

### 4. rabbitmq-sender

**Domain**: Message publishing to RabbitMQ  
**Business Purpose**: Demonstrate message queue integration

#### Business Rules

##### Message Publishing Rules
| Rule ID | Rule | Implementation | Business Rationale |
|---------|------|----------------|-------------------|
| PUB-001 | Message MUST be JSON formatted | Jackson serialization | Interoperability: Standard format |
| PUB-002 | Queue name MUST be configurable | Configuration property | Flexibility: Environment-specific queues |
| PUB-003 | Exchange name MUST be configurable | Configuration property | Flexibility: Routing configuration |
| PUB-004 | Connection retry MUST be configured | RabbitMQ connection factory | Resilience: Handle transient failures |

---

### 5. jakarta-ee student-web-app

**Domain**: Student profile management  
**Business Purpose**: CRUD operations for student records

#### Business Rules

##### Student Creation Rules
| Rule ID | Rule | Implementation | Business Rationale |
|---------|------|----------------|-------------------|
| STUDENT-001 | Name MUST NOT be blank | Validation in form submission | Data quality: All students need names |
| STUDENT-002 | Email MUST be valid format | `@Email` validation annotation | Data quality: Enable communication |
| STUDENT-003 | Email MUST be unique | Database unique constraint | Business rule: One email per student |
| STUDENT-004 | Enrollment date MUST NOT be null | `@NotNull` validation | Data integrity: Track enrollment |
| STUDENT-005 | Enrollment date MUST NOT be in future | Custom validation | Business logic: Can't enroll in future |
| STUDENT-006 | Major field is required | Form validation | Academic requirement: Declare major |

##### Student Query Rules
| Rule ID | Rule | Implementation | Business Rationale |
|---------|------|----------------|-------------------|
| QUERY-001 | MyBatis mapper MUST parameterize all queries | `#{param}` syntax in XML | Security: Prevent SQL injection |
| QUERY-002 | Student list MUST be paginated (if large) | Query with LIMIT/OFFSET | Performance: Avoid loading all records |

##### Student Update Rules
| Rule ID | Rule | Implementation | Business Rationale |
|---------|------|----------------|-------------------|
| UPDATE-001 | Update MUST preserve student ID | ID not editable in form | Data integrity: Maintain identity |
| UPDATE-002 | Email uniqueness MUST be validated on update | Database constraint check | Business rule: Prevent duplicate emails |

---

### 6. ContosoUniversity

**Domain**: University management system (.NET)  
**Business Purpose**: Manage students, courses, enrollments, departments

#### Business Rules

##### Student Rules
| Rule ID | Rule | Implementation | Business Rationale |
|---------|------|----------------|-------------------|
| STU-001 | Enrollment date MUST be between 1753 and 9999 | `[DataType(DataType.Date)]` + SQL Server datetime2 range | SQL Server constraint: datetime2 valid range |
| STU-002 | Enrollment date MinValue MUST be rejected | Controller validation | Data quality: Invalid date sentinel |
| STU-003 | First name MUST NOT exceed 50 characters | `[StringLength(50)]` | Database constraint: VARCHAR(50) |
| STU-004 | Last name MUST NOT exceed 50 characters | `[StringLength(50)]` | Database constraint: VARCHAR(50) |
| STU-005 | First name and last name both required | `[Required]` attribute | Data quality: Identify students |
| STU-006 | Student deletion MUST cascade to enrollments | EF `OnDelete(DeleteBehavior.Cascade)` | Data integrity: Remove orphan enrollments |

##### Course Rules
| Rule ID | Rule | Implementation | Business Rationale |
|---------|------|----------------|-------------------|
| COURSE-001 | Course credits MUST be between 0 and 5 | `[Range(0, 5)]` validation | Academic policy: Credit hour limits |
| COURSE-002 | Course title MUST NOT exceed 50 characters | `[StringLength(50)]` | Display constraint: UI layout |
| COURSE-003 | Course MUST belong to a department | Foreign key constraint | Organization: All courses have departments |
| COURSE-004 | Course ID is user-defined (not auto-generated) | Manual ID assignment | Business requirement: Use course codes |

##### Enrollment Rules
| Rule ID | Rule | Implementation | Business Rationale |
|---------|------|----------------|-------------------|
| ENROLL-001 | Student can enroll in same course only once | Unique index on (StudentID, CourseID) | Business rule: No duplicate enrollments |
| ENROLL-002 | Grade is optional (nullable) | Nullable `Grade?` property | Workflow: Grade assigned later |
| ENROLL-003 | Grade MUST be A, B, C, D, or F | Enum constraint | Academic standard: Letter grades only |

##### Department Rules
| Rule ID | Rule | Implementation | Business Rationale |
|---------|------|----------------|-------------------|
| DEPT-001 | Department name MUST NOT exceed 50 characters | `[StringLength(50)]` | Database constraint |
| DEPT-002 | Department budget MUST be non-negative | `[DataType(DataType.Currency)]` + validation | Business rule: Can't have negative budget |
| DEPT-003 | Department start date required | `[Required]` attribute | Historical tracking: When dept established |
| DEPT-004 | Department updates MUST handle concurrency | `RowVersion` timestamp field | Data integrity: Detect concurrent updates |
| DEPT-005 | Concurrency conflict MUST notify user | Catch `DbUpdateConcurrencyException` | User experience: Inform of conflicts |

##### Search and Filtering Rules
| Rule ID | Rule | Implementation | Business Rationale |
|---------|------|----------------|-------------------|
| SEARCH-001 | Student search MUST match LastName OR FirstMidName | LINQ `Where` with OR condition | Usability: Find by either name |
| SEARCH-002 | Search MUST be case-insensitive | `.ToLower()` comparison | Usability: User-friendly search |
| SEARCH-003 | Sorting options: Name ascending, Name descending, Date, Date descending | Switch statement on `sortOrder` | Usability: Flexible result ordering |

##### Pagination Rules
| Rule ID | Rule | Implementation | Business Rationale |
|---------|------|----------------|-------------------|
| PAGE-001 | Default page size is 3 records | Hardcoded constant (demo value) | Demo: Show pagination in action |
| PAGE-002 | Page number starts at 1 (not 0) | User-facing page numbers | Usability: Natural numbering |

---

### 7. Malshinon

**Domain**: Data processing with factory pattern (.NET)  
**Business Purpose**: Process different data formats (CSV, Excel, JSON)

#### Business Rules

##### Processor Selection Rules
| Rule ID | Rule | Implementation | Business Rationale |
|---------|------|----------------|-------------------|
| PROC-001 | Processor type determined by file extension or parameter | `DataProcessorFactory.CreateProcessor(type)` | Flexibility: Support multiple formats |
| PROC-002 | IF type=CSV THEN create CSVProcessor | Factory switch/if logic | Polymorphism: Type-specific handling |
| PROC-003 | IF type=Excel THEN create ExcelProcessor | Factory switch/if logic | Polymorphism: Type-specific handling |
| PROC-004 | IF type=JSON THEN create JSONProcessor | Factory switch/if logic | Polymorphism: Type-specific handling |
| PROC-005 | IF type unknown THEN return null or throw exception | Factory default case | Error handling: Invalid type detection |

##### Data Processing Rules
| Rule ID | Rule | Implementation | Business Rationale |
|---------|------|----------------|-------------------|
| DATA-001 | All processors MUST implement IDataProcessor | Interface contract | Architecture: Ensure consistency |
| DATA-002 | CSV processing MUST handle quoted fields | CSV parser library | Data quality: Handle commas in data |
| DATA-003 | Excel processing MUST support .xls and .xlsx | Excel library compatibility | Compatibility: Support old and new formats |
| DATA-004 | JSON processing MUST validate JSON structure | JSON deserializer | Data quality: Reject malformed JSON |

##### DAL (Data Access Layer) Rules
| Rule ID | Rule | Implementation | Business Rationale |
|---------|------|----------------|-------------------|
| DAL-001 | DAL MUST abstract database operations | Interface-based DAL | Architecture: Decoupled data access |
| DAL-002 | Connection string MUST be configurable | Configuration file | Flexibility: Environment-specific databases |

---

## Business Rule Categories

### Category Summary

| Category | Count | Primary Projects |
|----------|-------|------------------|
| **Validation Rules** | 45+ | All projects |
| **Data Integrity Rules** | 20+ | All with databases |
| **Authentication/Authorization** | 5+ | mi-sql-public-demo, ContosoUniversity |
| **Storage Management** | 15+ | asset-manager |
| **Message Queue Rules** | 10+ | asset-manager, rabbitmq-sender |
| **Oracle-Specific Rules** | 8+ | todo-web-api |
| **SQL Server-Specific Rules** | 10+ | ContosoUniversity |
| **Concurrency Control** | 5+ | ContosoUniversity |
| **File Processing** | 12+ | asset-manager, Malshinon |
| **Search and Filter** | 10+ | todo-web-api, ContosoUniversity, student-web-app |

---

## Validation Rules Matrix

### Input Validation by Project

| Validation Type | mi-sql | asset-mgr | todo-api | rabbitmq | student | ContosoU | Malshinon |
|----------------|---------|-----------|----------|----------|---------|----------|-----------|
| **Required Fields** | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| **String Length** | - | ✓ | ✓ | - | ✓ | ✓ | - |
| **Email Format** | - | - | - | - | ✓ | ✓ | - |
| **Date Range** | - | - | ✓ | - | ✓ | ✓ | - |
| **Numeric Range** | - | ✓ (file size) | ✓ (priority) | - | - | ✓ (credits, budget) | - |
| **File Type** | - | ✓ | - | - | - | - | ✓ |
| **Uniqueness** | - | ✓ (filename) | - | - | ✓ (email) | - | - |
| **SQL Injection Prevention** | ✓ | ✓ | ✓ | - | ✓ | ✓ | ✓ |

### Business Logic Complexity by Project

| Project | Complexity | Rationale |
|---------|------------|-----------|
| **asset-manager** | High | Multiple storage backends, async processing, messaging |
| **ContosoUniversity** | High | Complex entity relationships, concurrency control, search/filter/pagination |
| **todo-web-api** | Medium | Oracle-specific queries, multiple query methods, bulk operations |
| **student-web-app** | Medium | MyBatis mapping, validation, CRUD operations |
| **Malshinon** | Medium | Factory pattern, multiple processor types, data format handling |
| **rabbitmq-sender** | Low | Simple message publishing |
| **mi-sql-public-demo** | Low | Demonstration of authentication pattern |

---

**Related Documentation:**
- [Decision Logic](decision-logic.md) - Conditional logic and branching patterns
- [Workflows](workflows.md) - End-to-end process flows
- [Error Handling](error-handling.md) - Exception handling patterns
- [Program Structure](../reference/program-structure.md) - Implementation details and code locations
- [Validation Criteria](../migration/validation-criteria.md) - How these rules are validated during migration
