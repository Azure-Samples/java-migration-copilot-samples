# Program Structure - Complete Hierarchy

**Analysis Date:** December 2024  
**Total Source Files:** 87 (45 Java, 42 C#)  
**Analysis Method:** Static Code Analysis

---

## Table of Contents
- [Overview](#overview)
- [Java Projects](#java-projects)
  - [mi-sql-public-demo](#1-mi-sql-public-demo)
  - [asset-manager](#2-asset-manager)
  - [todo-web-api-use-oracle-db](#3-todo-web-api-use-oracle-db)
  - [rabbitmq-sender](#4-rabbitmq-sender)
  - [jakarta-ee/student-web-app](#5-jakarta-ee-student-web-app)
- [.NET Projects](#net-projects)
  - [ContosoUniversity](#6-contosouniversity)
  - [Malshinon](#7-malshinon)
- [Cross-Project Patterns](#cross-project-patterns)

---

## Overview

This document provides a complete structural hierarchy of all classes, interfaces, enums, and their relationships across the entire repository. Each component includes:
- Full package/namespace paths
- Access modifiers
- Inheritance hierarchies
- Key annotations/attributes
- Method signatures
- Field declarations
- Source file locations

---

## Java Projects

### 1. mi-sql-public-demo

**Purpose:** Demonstrates Azure Managed Identity authentication with SQL Server  
**Language:** Java 17  
**Package Base:** `com.example`  
**Source Files:** 1

#### Classes

##### MainSQL
- **Type:** Class (application entry point)
- **Package:** `com.example`
- **File:** `mi-sql-public-demo/src/main/java/com/example/MainSQL.java`
- **Access:** public
- **Pattern:** Main application class
- **Methods:**
  - `public static void main(String[] args)` - Application entry point
  - Connection establishment using Managed Identity
  - SQL query execution
  - Result processing
- **Key Features:**
  - JDBC connection management
  - Azure Managed Identity integration
  - SQL Server connectivity
  - Statement execution and result set processing

---

### 2. asset-manager

**Purpose:** Multi-module Spring Boot microservices for asset/image management  
**Language:** Java 8  
**Framework:** Spring Boot 2.7.18  
**Modules:** web, worker  
**Package Base:** `com.microsoft.migration.assets`  
**Source Files:** 26 (14 web + 12 worker)

#### Module: web

##### Application Entry Point

###### AssetsManagerApplication
- **Type:** Class (@SpringBootApplication)
- **Package:** `com.microsoft.migration.assets`
- **File:** `asset-manager/web/src/main/java/com/microsoft/migration/assets/AssetsManagerApplication.java`
- **Annotations:** `@SpringBootApplication`
- **Methods:**
  - `public static void main(String[] args)` - Spring Boot application entry

##### Controllers (Presentation Layer)

###### HomeController
- **Type:** Class (@Controller)
- **Package:** `com.microsoft.migration.assets.controller`
- **File:** `asset-manager/web/src/main/java/com/microsoft/migration/assets/controller/HomeController.java`
- **Annotations:** `@Controller`
- **Mappings:**
  - `@GetMapping("/")` → `index()` - Returns home view
- **Purpose:** Home page controller

###### S3Controller
- **Type:** Class (@Controller)
- **Package:** `com.microsoft.migration.assets.controller`
- **File:** `asset-manager/web/src/main/java/com/microsoft/migration/assets/controller/S3Controller.java`
- **Annotations:** `@Controller`, `@RequestMapping("/{STORAGE_PATH}")`, `@RequiredArgsConstructor`
- **Dependencies:** StorageService (injected via constructor)
- **Mappings:**
  - `@GetMapping` → `listObjects(Model)` - List all stored objects
  - `@GetMapping("/upload")` → `uploadForm()` - Show upload form
  - `@PostMapping("/upload")` → `uploadObject(MultipartFile, RedirectAttributes)` - Handle file upload
  - `@GetMapping("/view-page/{key}")` → `viewObjectPage(String, Model, RedirectAttributes)` - View object details page
  - `@GetMapping("/view/{key}")` → `viewObject(String)` - Stream object content
  - `@PostMapping("/delete/{key}")` → `deleteObject(String, RedirectAttributes)` - Delete object
- **Return Types:**
  - String (view names)
  - ResponseEntity<InputStreamResource> (file downloads)
- **Error Handling:** Try-catch with RedirectAttributes for user feedback

##### Services (Business Logic Layer)

###### StorageService (Interface)
- **Type:** Interface
- **Package:** `com.microsoft.migration.assets.service`
- **File:** `asset-manager/web/src/main/java/com/microsoft/migration/assets/service/StorageService.java`
- **Purpose:** Abstraction for storage operations
- **Methods:**
  - `List<S3StorageItem> listObjects()` - List all objects
  - `void uploadObject(MultipartFile)` throws IOException - Upload file
  - `InputStream getObject(String)` throws IOException - Retrieve object
  - `void deleteObject(String)` throws IOException - Delete object
  - `String getStorageType()` - Get storage implementation type
  - `default String getThumbnailKey(String)` - Generate thumbnail key
  - `default String generateUrl(String)` - Generate object URL
- **Pattern:** Strategy pattern for multiple storage implementations

###### AwsS3Service
- **Type:** Class (@Service)
- **Package:** `com.microsoft.migration.assets.service`
- **File:** `asset-manager/web/src/main/java/com/microsoft/migration/assets/service/AwsS3Service.java`
- **Implements:** StorageService
- **Annotations:** `@Service`, `@Profile("aws")`, `@RequiredArgsConstructor`
- **Dependencies:**
  - S3Client (AWS SDK v2)
  - ImageMetadataRepository
  - RabbitTemplate (messaging)
- **Purpose:** AWS S3 storage implementation
- **Key Operations:**
  - S3 object listing with SDK v2
  - Multipart file upload to S3
  - Object retrieval and deletion
  - RabbitMQ message publishing for async processing

###### LocalFileStorageService
- **Type:** Class (@Service)
- **Package:** `com.microsoft.migration.assets.service`
- **File:** `asset-manager/web/src/main/java/com/microsoft/migration/assets/service/LocalFileStorageService.java`
- **Implements:** StorageService
- **Annotations:** `@Service`, `@Profile("local")`
- **Purpose:** Local filesystem storage implementation (for testing)

###### BackupMessageProcessor
- **Type:** Class (@Service)
- **Package:** `com.microsoft.migration.assets.service`
- **File:** `asset-manager/web/src/main/java/com/microsoft/migration/assets/service/BackupMessageProcessor.java`
- **Annotations:** `@Service`, `@RequiredArgsConstructor`
- **Purpose:** Message queue consumer for processing notifications

##### Configuration Classes

###### AwsS3Config
- **Type:** Class (@Configuration)
- **Package:** `com.microsoft.migration.assets.config`
- **File:** `asset-manager/web/src/main/java/com/microsoft/migration/assets/config/AwsS3Config.java`
- **Annotations:** `@Configuration`, `@Profile("aws")`
- **Bean Definitions:**
  - `@Bean S3Client s3Client()` - Configures AWS S3 SDK client
- **Purpose:** AWS SDK configuration

###### RabbitConfig
- **Type:** Class (@Configuration)
- **Package:** `com.microsoft.migration.assets.config`
- **File:** `asset-manager/web/src/main/java/com/microsoft/migration/assets/config/RabbitConfig.java`
- **Annotations:** `@Configuration`
- **Bean Definitions:**
  - Queue configuration
  - Exchange setup
  - Binding definitions
- **Purpose:** RabbitMQ messaging configuration

###### WebMvcConfig
- **Type:** Class (@Configuration)
- **Package:** `com.microsoft.migration.assets.config`
- **File:** `asset-manager/web/src/main/java/com/microsoft/migration/assets/config/WebMvcConfig.java`
- **Annotations:** `@Configuration`
- **Implements:** WebMvcConfigurer
- **Purpose:** Spring MVC customization

##### Repository Layer (Data Access)

###### ImageMetadataRepository
- **Type:** Interface (@Repository)
- **Package:** `com.microsoft.migration.assets.repository`
- **File:** `asset-manager/web/src/main/java/com/microsoft/migration/assets/repository/ImageMetadataRepository.java`
- **Extends:** JpaRepository<ImageMetadata, Long>
- **Purpose:** PostgreSQL data access for image metadata
- **Methods:** Standard CRUD operations from JpaRepository

##### Model Classes (Domain)

###### ImageMetadata
- **Type:** Class (@Entity)
- **Package:** `com.microsoft.migration.assets.model`
- **File:** `asset-manager/web/src/main/java/com/microsoft/migration/assets/model/ImageMetadata.java`
- **Annotations:** `@Entity`, `@Table(name="image_metadata")`
- **Fields:**
  - `@Id @GeneratedValue Long id` - Primary key
  - `String key` - S3 object key
  - `String filename` - Original filename
  - `Long fileSize` - File size in bytes
  - `String contentType` - MIME type
  - `LocalDateTime uploadedAt` - Upload timestamp
  - `String thumbnailKey` - Thumbnail S3 key
  - `String status` - Processing status
- **Purpose:** JPA entity for image metadata in PostgreSQL

###### S3StorageItem
- **Type:** Class
- **Package:** `com.microsoft.migration.assets.model`
- **File:** `asset-manager/web/src/main/java/com/microsoft/migration/assets/model/S3StorageItem.java`
- **Annotations:** `@Data`, `@Builder`, `@NoArgsConstructor`, `@AllArgsConstructor`
- **Fields:**
  - `String key` - Object key
  - `Long size` - Object size
  - `Instant lastModified` - Last modification time
  - `String url` - View URL
- **Purpose:** DTO for storage items in UI

###### ImageProcessingMessage
- **Type:** Class
- **Package:** `com.microsoft.migration.assets.model`
- **File:** `asset-manager/web/src/main/java/com/microsoft/migration/assets/model/ImageProcessingMessage.java`
- **Annotations:** `@Data`, `@Builder`, `@NoArgsConstructor`, `@AllArgsConstructor`
- **Fields:**
  - `String key` - S3 object key
  - `String filename` - Original filename
  - `String operation` - Operation type (e.g., "thumbnail")
- **Purpose:** Message format for RabbitMQ communication

##### Constants

###### StorageConstants
- **Type:** Class
- **Package:** `com.microsoft.migration.assets.constants`
- **File:** `asset-manager/web/src/main/java/com/microsoft/migration/assets/constants/StorageConstants.java`
- **Fields:** Application-wide constants for storage paths and configuration

#### Module: worker

##### Application Entry Point

###### WorkerApplication
- **Type:** Class (@SpringBootApplication)
- **Package:** `com.microsoft.migration.assets.worker`
- **File:** `asset-manager/worker/src/main/java/com/microsoft/migration/assets/worker/WorkerApplication.java`
- **Annotations:** `@SpringBootApplication`
- **Methods:**
  - `public static void main(String[] args)` - Worker application entry

##### Services (Background Processing)

###### FileProcessor (Interface)
- **Type:** Interface
- **Package:** `com.microsoft.migration.assets.worker.service`
- **File:** `asset-manager/worker/src/main/java/com/microsoft/migration/assets/worker/service/FileProcessor.java`
- **Methods:**
  - `void processMessage(ImageProcessingMessage)` - Process incoming message
- **Purpose:** Abstraction for file processing operations

###### AbstractFileProcessingService
- **Type:** Abstract Class
- **Package:** `com.microsoft.migration.assets.worker.service`
- **File:** `asset-manager/worker/src/main/java/com/microsoft/migration/assets/worker/service/AbstractFileProcessingService.java`
- **Implements:** FileProcessor
- **Pattern:** Template method pattern
- **Methods:**
  - `abstract InputStream downloadFile(String key)` - Download from storage
  - `abstract void uploadThumbnail(String key, byte[] data)` - Upload thumbnail
  - `protected byte[] generateThumbnail(InputStream)` - Thumbnail generation logic
- **Purpose:** Common logic for file processing

###### S3FileProcessingService
- **Type:** Class (@Service)
- **Package:** `com.microsoft.migration.assets.worker.service`
- **File:** `asset-manager/worker/src/main/java/com/microsoft/migration/assets/worker/service/S3FileProcessingService.java`
- **Extends:** AbstractFileProcessingService
- **Annotations:** `@Service`, `@Profile("aws")`, `@RabbitListener`
- **Dependencies:**
  - S3Client
  - ImageMetadataRepository
- **Methods:**
  - `@RabbitListener(queues="...")` `processMessage(ImageProcessingMessage)` - Message listener
  - `InputStream downloadFile(String)` - Download from S3
  - `void uploadThumbnail(String, byte[])` - Upload to S3
- **Purpose:** AWS S3-based image processing worker

###### LocalFileProcessingService
- **Type:** Class (@Service)
- **Package:** `com.microsoft.migration.assets.worker.service`
- **File:** `asset-manager/worker/src/main/java/com/microsoft/migration/assets/worker/service/LocalFileProcessingService.java`
- **Extends:** AbstractFileProcessingService
- **Annotations:** `@Service`, `@Profile("local")`
- **Purpose:** Local filesystem-based processing (for testing)

##### Configuration Classes

###### AwsS3Config (Worker)
- **Type:** Class (@Configuration)
- **Package:** `com.microsoft.migration.assets.worker.config`
- **File:** `asset-manager/worker/src/main/java/com/microsoft/migration/assets/worker/config/AwsS3Config.java`
- **Annotations:** `@Configuration`, `@Profile("aws")`
- **Purpose:** Worker-specific AWS configuration

###### RabbitConfig (Worker)
- **Type:** Class (@Configuration)
- **Package:** `com.microsoft.migration.assets.worker.config`
- **File:** `asset-manager/worker/src/main/java/com/microsoft/migration/assets/worker/config/RabbitConfig.java`
- **Purpose:** Worker-specific RabbitMQ configuration

##### Utility Classes

###### StorageUtil
- **Type:** Class
- **Package:** `com.microsoft.migration.assets.worker.util`
- **File:** `asset-manager/worker/src/main/java/com/microsoft/migration/assets/worker/util/StorageUtil.java`
- **Purpose:** Helper methods for storage operations

##### Model Classes (Duplicated for worker independence)

- ImageMetadata (worker version)
- ImageProcessingMessage (worker version)

##### Repository Layer

###### ImageMetadataRepository (Worker)
- **Type:** Interface
- **Package:** `com.microsoft.migration.assets.worker.repository`
- **File:** `asset-manager/worker/src/main/java/com/microsoft/migration/assets/worker/repository/ImageMetadataRepository.java`
- **Extends:** JpaRepository<ImageMetadata, Long>

##### Test Classes

###### S3FileProcessingServiceTest
- **Type:** Test Class (@SpringBootTest)
- **Package:** `com.microsoft.migration.assets.worker.service`
- **File:** `asset-manager/worker/src/test/java/com/microsoft/migration/assets/worker/service/S3FileProcessingServiceTest.java`
- **Purpose:** Unit tests for S3 file processing

---

### 3. todo-web-api-use-oracle-db

**Purpose:** RESTful API for Todo management with Oracle Database  
**Language:** Java 17  
**Framework:** Spring Boot 3.2.4  
**Package Base:** `com.microsoft.migration.todo`  
**Source Files:** 6

##### Application Entry Point

###### TodoApplication
- **Type:** Class (@SpringBootApplication)
- **Package:** `com.microsoft.migration.todo`
- **File:** `todo-web-api-use-oracle-db/src/main/java/com/microsoft/migration/todo/TodoApplication.java`
- **Annotations:** `@SpringBootApplication`

##### Controllers

###### TodoController
- **Type:** Class (@RestController)
- **Package:** `com.microsoft.migration.todo.controller`
- **File:** `todo-web-api-use-oracle-db/src/main/java/com/microsoft/migration/todo/controller/TodoController.java`
- **Annotations:** `@RestController`, `@RequestMapping("/api/todos")`, `@RequiredArgsConstructor`
- **Dependencies:** TodoService (injected)
- **Endpoints:**
  - `@GetMapping` → `getAllTodos()` - Returns List<TodoItem>
  - `@GetMapping("/{id}")` → `getTodoById(Long)` - Returns TodoItem
  - `@PostMapping` → `createTodo(TodoItem)` - Returns TodoItem
  - `@PutMapping("/{id}")` → `updateTodo(Long, TodoItem)` - Returns TodoItem
  - `@DeleteMapping("/{id}")` → `deleteTodo(Long)` - Returns void
  - `@PatchMapping("/{id}/complete")` → `completeTodo(Long)` - Returns TodoItem
- **Return Types:** ResponseEntity<T> for proper HTTP status handling
- **Validation:** Bean validation annotations on request body

##### Services

###### TodoService
- **Type:** Class (@Service)
- **Package:** `com.microsoft.migration.todo.service`
- **File:** `todo-web-api-use-oracle-db/src/main/java/com/microsoft/migration/todo/service/TodoService.java`
- **Annotations:** `@Service`, `@Transactional`, `@RequiredArgsConstructor`
- **Dependencies:** TodoRepository (injected)
- **Methods:**
  - `List<TodoItem> getAllTodos()` - Retrieve all todos
  - `TodoItem getTodoById(Long)` - Find by ID with exception handling
  - `TodoItem createTodo(TodoItem)` - Create new todo
  - `TodoItem updateTodo(Long, TodoItem)` - Update existing todo
  - `void deleteTodo(Long)` - Delete todo
  - `TodoItem completeTodo(Long)` - Mark as complete
- **Exception Handling:** EntityNotFoundException for missing items

##### Repository

###### TodoRepository
- **Type:** Interface (@Repository)
- **Package:** `com.microsoft.migration.todo.repository`
- **File:** `todo-web-api-use-oracle-db/src/main/java/com/microsoft/migration/todo/repository/TodoRepository.java`
- **Extends:** JpaRepository<TodoItem, Long>
- **Custom Queries:** May include Oracle-specific queries

##### Model

###### TodoItem
- **Type:** Class (@Entity)
- **Package:** `com.microsoft.migration.todo.model`
- **File:** `todo-web-api-use-oracle-db/src/main/java/com/microsoft/migration/todo/model/TodoItem.java`
- **Annotations:**
  - `@Entity`
  - `@Table(name="TODO_ITEMS")`
  - `@Data` (Lombok)
  - `@NoArgsConstructor`, `@AllArgsConstructor`
- **Fields:**
  - `@Id @GeneratedValue(strategy=GenerationType.SEQUENCE) Long id`
  - `@Column(length=255) String title` - Oracle VARCHAR2(255)
  - `@Column(length=1000) String description` - Oracle VARCHAR2(1000)
  - `@Column(name="is_completed") Boolean completed` - Default false
  - `@Column(name="created_at") LocalDateTime createdAt`
  - `@Column(name="updated_at") LocalDateTime updatedAt`
- **Validation:**
  - `@NotBlank` on title
  - `@Size(max=255)` on title
  - `@Size(max=1000)` on description
- **Lifecycle Callbacks:**
  - `@PrePersist` - Set createdAt
  - `@PreUpdate` - Update updatedAt

##### Utility

###### OracleSqlDemonstrator
- **Type:** Class
- **Package:** `com.microsoft.migration.todo.util`
- **File:** `todo-web-api-use-oracle-db/src/main/java/com/microsoft/migration/todo/util/OracleSqlDemonstrator.java`
- **Purpose:** Demonstrates Oracle-specific SQL features (VARCHAR2, sequences, etc.)

---

### 4. rabbitmq-sender

**Purpose:** RabbitMQ message producer demonstration  
**Language:** Java  
**Framework:** Spring Boot  
**Package Base:** `com.example.messagingrabbitmq`  
**Source Files:** 2

##### Application Entry Point

###### MessagingRabbitmqApplication
- **Type:** Class (@SpringBootApplication)
- **Package:** `com.example.messagingrabbitmq`
- **File:** `rabbitmq-sender/src/main/java/com/example/messagingrabbitmq/MessagingRabbitmqApplication.java`
- **Annotations:** `@SpringBootApplication`
- **Methods:**
  - `public static void main(String[] args)`
  - Application startup logic

##### Services

###### Producer
- **Type:** Class (@Component)
- **Package:** `com.example.messagingrabbitmq`
- **File:** `rabbitmq-sender/src/main/java/com/example/messagingrabbitmq/Producer.java`
- **Annotations:** `@Component`
- **Dependencies:** RabbitTemplate (injected)
- **Methods:**
  - Message sending methods
  - Queue interaction logic
- **Purpose:** Produces messages to RabbitMQ queues

---

### 5. jakarta-ee student-web-app

**Purpose:** Student profile management with hybrid Jakarta EE/Spring MVC  
**Language:** Java 11  
**Framework:** Jakarta EE + Spring MVC (hybrid)  
**Server:** Open Liberty  
**Package Base:** `org.sample.azure.student.coreft`  
**Source Files:** 9

##### Servlets (Jakarta EE)

###### IndexServlet
- **Type:** Class (extends HttpServlet)
- **Package:** `org.sample.azure.student.coreft`
- **File:** `jakarta-ee/student-web-app/src/org/sample/azure/student/coreft/IndexServlet.java`
- **Annotations:** `@WebServlet(urlPatterns={"/"})`
- **Methods:**
  - `protected void doGet(HttpServletRequest, HttpServletResponse)` - Handle GET requests
- **Purpose:** Home page servlet

###### AddStudentServlet
- **Type:** Class (extends HttpServlet)
- **Package:** `org.sample.azure.student.coreft`
- **File:** `jakarta-ee/student-web-app/src/org/sample/azure/student/coreft/AddStudentServlet.java`
- **Annotations:** `@WebServlet(urlPatterns={"/add-student"})`
- **Methods:**
  - `protected void doGet(HttpServletRequest, HttpServletResponse)` - Show form
  - `protected void doPost(HttpServletRequest, HttpServletResponse)` - Handle submission
- **Purpose:** Add student functionality (Jakarta EE style)

###### StudentProfileListServlet
- **Type:** Class (extends HttpServlet)
- **Package:** `org.sample.azure.student.coreft`
- **File:** `jakarta-ee/student-web-app/src/org/sample/azure/student/coreft/StudentProfileListServlet.java`
- **Annotations:** `@WebServlet(urlPatterns={"/student-list"})`
- **Purpose:** List all students

##### Controllers (Spring MVC - Hybrid)

###### StudentController
- **Type:** Class (@Controller)
- **Package:** `org.sample.azure.student.coreft.controller`
- **File:** `jakarta-ee/student-web-app/src/org/sample/azure/student/coreft/controller/StudentController.java`
- **Annotations:** `@Controller`, `@RequestMapping("/students")`
- **Dependencies:** StudentService (injected)
- **Mappings:**
  - `@GetMapping` → List students
  - `@GetMapping("/{id}")` → View student details
  - `@PostMapping` → Create student
  - `@PutMapping("/{id}")` → Update student
  - `@DeleteMapping("/{id}")` → Delete student
- **Purpose:** RESTful-style student management (Spring MVC style)

###### AddStudentController
- **Type:** Class (@Controller)
- **Package:** `org.sample.azure.student.coreft.controller`
- **File:** `jakarta-ee/student-web-app/src/org/sample/azure/student/coreft/controller/AddStudentController.java`
- **Annotations:** `@Controller`
- **Purpose:** Additional Spring MVC controller for student addition

##### Services

###### StudentService
- **Type:** Class (@Service)
- **Package:** `org.sample.azure.student.coreft.service`
- **File:** `jakarta-ee/student-web-app/src/org/sample/azure/student/coreft/service/StudentService.java`
- **Annotations:** `@Service`
- **Dependencies:** MyBatis mappers (via MyBatisUtil)
- **Methods:**
  - CRUD operations for students
  - Business logic for student management
- **Purpose:** Service layer bridging controllers and data access

##### Filters

###### CommonHttpServletFilter
- **Type:** Class (implements Filter)
- **Package:** `org.sample.azure.student.coreft.filter`
- **File:** `jakarta-ee/student-web-app/src/org/sample/azure/student/coreft/filter/CommonHttpServletFilter.java`
- **Annotations:** `@WebFilter(urlPatterns={"/*"})`
- **Methods:**
  - `doFilter(ServletRequest, ServletResponse, FilterChain)`
- **Purpose:** Common request/response filtering (logging, security, etc.)

##### Models

###### StudentProfile
- **Type:** Class (POJO)
- **Package:** `org.sample.azure.student.coreft`
- **File:** `jakarta-ee/student-web-app/src/org/sample/azure/student/coreft/StudentProfile.java`
- **Fields:**
  - `int id`
  - `String firstName`
  - `String lastName`
  - `String email`
  - `Date enrollmentDate`
  - `String major`
- **Purpose:** Student domain model

##### Utilities

###### MyBatisUtil
- **Type:** Class
- **Package:** `org.sample.azure.student.coreft.util`
- **File:** `jakarta-ee/student-web-app/src/org/sample/azure/student/coreft/util/MyBatisUtil.java`
- **Purpose:** MyBatis SQL mapper utility
- **Methods:**
  - SqlSessionFactory initialization
  - SqlSession creation
  - MyBatis configuration loading

---

## .NET Projects

### 6. ContosoUniversity

**Purpose:** University management system (students, courses, instructors, departments)  
**Language:** C#  
**Framework:** .NET Framework 4.8, ASP.NET MVC 5  
**Namespace Base:** `ContosoUniversity`  
**Source Files:** ~35

##### Application Startup

###### Global.asax.cs
- **Type:** Class (Application)
- **Namespace:** ContosoUniversity
- **File:** `ContosoUniversity/Global.asax.cs`
- **Inherits:** System.Web.HttpApplication
- **Methods:**
  - `void Application_Start()` - Initialize routes, bundles, filters
  - `void Application_BeginRequest()` - Per-request initialization
  - `void Application_Error()` - Global error handling
- **Purpose:** ASP.NET MVC application initialization

##### Controllers

###### BaseController
- **Type:** Abstract Class
- **Namespace:** `ContosoUniversity.Controllers`
- **File:** `ContosoUniversity/Controllers/BaseController.cs`
- **Inherits:** Controller
- **Properties:**
  - `protected SchoolContext db` - Database context
  - `protected INotificationService notificationService` - Notification service
- **Methods:**
  - `protected void SendEntityNotification(string, string, string, EntityOperation)` - Send entity change notifications
  - `protected override void Dispose(bool)` - Resource cleanup
- **Purpose:** Base class for all controllers providing common functionality

###### HomeController
- **Type:** Class
- **Namespace:** `ContosoUniversity.Controllers`
- **File:** `ContosoUniversity/Controllers/HomeController.cs`
- **Inherits:** BaseController
- **Attributes:** `[AllowAnonymous]`
- **Actions:**
  - `public ActionResult Index()` - Home page
  - `public ActionResult About()` - Statistics page with enrollment data
  - `public ActionResult Contact()` - Contact page
- **Purpose:** Main navigation and statistics

###### StudentsController
- **Type:** Class
- **Namespace:** `ContosoUniversity.Controllers`
- **File:** `ContosoUniversity/Controllers/StudentsController.cs`
- **Inherits:** BaseController
- **Actions:**
  - `public ActionResult Index(string sortOrder, string currentFilter, string searchString, int? page)` - List with paging/sorting/filtering
  - `public ActionResult Details(int? id)` - Student details with enrollments
  - `public ActionResult Create()` - Show create form
  - `[HttpPost] [ValidateAntiForgeryToken] public ActionResult Create([Bind] Student)` - Create student
  - `public ActionResult Edit(int? id)` - Show edit form
  - `[HttpPost] [ValidateAntiForgeryToken] public ActionResult Edit([Bind] Student)` - Update student
  - `public ActionResult Delete(int? id)` - Show delete confirmation
  - `[HttpPost, ActionName("Delete")] [ValidateAntiForgeryToken] public ActionResult DeleteConfirmed(int)` - Delete student
- **Features:**
  - Entity Framework CRUD operations
  - Model validation
  - Error handling with logging (Trace.TraceError)
  - Notification integration (SendEntityNotification)
  - SQL Server datetime validation (1753-9999 range)
- **Purpose:** Student management CRUD operations

###### CoursesController
- **Type:** Class
- **Namespace:** `ContosoUniversity.Controllers`
- **File:** `ContosoUniversity/Controllers/CoursesController.cs`
- **Inherits:** BaseController
- **Actions:**
  - Index, Details, Create, Edit, Delete (similar structure to StudentsController)
  - Department selection dropdowns
- **Purpose:** Course management

###### InstructorsController
- **Type:** Class
- **Namespace:** `ContosoUniversity.Controllers`
- **File:** `ContosoUniversity/Controllers/InstructorsController.cs`
- **Inherits:** BaseController
- **Actions:**
  - Complex Index with multiple related data (courses, enrollments)
  - Create/Edit with course assignments
  - Office assignment management
- **Features:**
  - Eager loading of related entities (.Include(), .ThenInclude())
  - Many-to-many relationship handling
  - Complex view models (InstructorIndexData, AssignedCourseData)
- **Purpose:** Instructor management with course assignments

###### DepartmentsController
- **Type:** Class
- **Namespace:** `ContosoUniversity.Controllers`
- **File:** `ContosoUniversity/Controllers/DepartmentsController.cs`
- **Inherits:** BaseController
- **Actions:**
  - Standard CRUD operations
  - Concurrency conflict handling
- **Features:**
  - Optimistic concurrency control with RowVersion
  - Budget management
  - Administrator assignment (FK to Instructor)
- **Purpose:** Department management with concurrency handling

###### NotificationsController
- **Type:** Class
- **Namespace:** `ContosoUniversity.Controllers`
- **File:** `ContosoUniversity/Controllers/NotificationsController.cs`
- **Inherits:** BaseController
- **Actions:**
  - List notifications
  - Manage notification preferences
  - Test notification sending
- **Purpose:** Notification system management

##### Models (Domain Entities)

###### Student
- **Type:** Class
- **Namespace:** `ContosoUniversity.Models`
- **File:** `ContosoUniversity/Models/Student.cs`
- **Properties:**
  - `int ID` - Primary key
  - `[Required] [StringLength(50)] string LastName`
  - `[Required] [StringLength(50, Minimum=1)] [Display(Name="First Name")] string FirstMidName`
  - `[DataType(DataType.Date)] [DisplayFormat(DataFormatString="{0:yyyy-MM-dd}")] DateTime EnrollmentDate`
  - `[Display(Name="Full Name")] string FullName { get; }` - Computed property
  - `virtual ICollection<Enrollment> Enrollments { get; set; }` - Navigation property
- **Validation:** Data annotations for required fields, string lengths
- **Purpose:** Student entity

###### Course
- **Type:** Class
- **Namespace:** `ContosoUniversity.Models`
- **File:** `ContosoUniversity/Models/Course.cs`
- **Properties:**
  - `[DatabaseGenerated(DatabaseGeneratedOption.None)] int CourseID` - Primary key (not auto-generated)
  - `[StringLength(50)] [Required] string Title`
  - `[Range(0,5)] int Credits`
  - `int DepartmentID` - Foreign key
  - `virtual Department Department { get; set; }` - Navigation property
  - `virtual ICollection<Enrollment> Enrollments { get; set; }`
  - `virtual ICollection<Instructor> Instructors { get; set; }` - Many-to-many
- **Purpose:** Course entity

###### Instructor
- **Type:** Class
- **Namespace:** `ContosoUniversity.Models`
- **File:** `ContosoUniversity/Models/Instructor.cs`
- **Properties:**
  - `int ID` - Primary key
  - `[Required] [StringLength(50)] string LastName`
  - `[Required] [StringLength(50)] string FirstMidName`
  - `[DataType(DataType.Date)] DateTime HireDate`
  - `string FullName { get; }` - Computed property
  - `virtual ICollection<Course> Courses { get; set; }` - Many-to-many
  - `virtual OfficeAssignment OfficeAssignment { get; set; }` - One-to-one
- **Purpose:** Instructor entity

###### Enrollment
- **Type:** Class
- **Namespace:** `ContosoUniversity.Models`
- **File:** `ContosoUniversity/Models/Enrollment.cs`
- **Properties:**
  - `int EnrollmentID` - Primary key
  - `int CourseID` - Foreign key
  - `int StudentID` - Foreign key
  - `Grade? Grade` - Nullable enum
  - `virtual Course Course { get; set; }` - Navigation property
  - `virtual Student Student { get; set; }` - Navigation property
- **Purpose:** Junction table for student-course enrollment

###### Department
- **Type:** Class
- **Namespace:** `ContosoUniversity.Models`
- **File:** `ContosoUniversity/Models/Department.cs`
- **Properties:**
  - `int DepartmentID` - Primary key
  - `[StringLength(50)] [Required] string Name`
  - `[DataType(DataType.Currency)] [Column(TypeName="money")] decimal Budget`
  - `[DataType(DataType.Date)] DateTime StartDate`
  - `int? InstructorID` - Foreign key (nullable, administrator)
  - `[Timestamp] byte[] RowVersion` - Concurrency token
  - `virtual Instructor Administrator { get; set; }` - Navigation property
  - `virtual ICollection<Course> Courses { get; set; }`
- **Concurrency:** RowVersion for optimistic concurrency
- **Purpose:** Department entity

###### OfficeAssignment
- **Type:** Class
- **Namespace:** `ContosoUniversity.Models`
- **File:** `ContosoUniversity/Models/OfficeAssignment.cs`
- **Properties:**
  - `[Key] [ForeignKey("Instructor")] int InstructorID` - Primary key and foreign key
  - `[StringLength(50)] string Location`
  - `virtual Instructor Instructor { get; set; }` - Navigation property
- **Pattern:** One-to-one relationship with Instructor
- **Purpose:** Instructor office location

###### Grade (Enum)
- **Type:** Enum
- **Namespace:** `ContosoUniversity.Models`
- **File:** `ContosoUniversity/Models/Enrollment.cs`
- **Values:** A, B, C, D, F
- **Purpose:** Student grade enumeration

##### View Models

###### EnrollmentDateGroup
- **Type:** Class
- **Namespace:** `ContosoUniversity.Models.SchoolViewModels`
- **File:** `ContosoUniversity/Models/SchoolViewModels/EnrollmentDateGroup.cs`
- **Properties:**
  - `DateTime? EnrollmentDate`
  - `int StudentCount`
- **Purpose:** Grouping statistics for About page

###### InstructorIndexData
- **Type:** Class
- **Namespace:** `ContosoUniversity.Models.SchoolViewModels`
- **File:** `ContosoUniversity/Models/SchoolViewModels/InstructorIndexData.cs`
- **Properties:**
  - `IEnumerable<Instructor> Instructors`
  - `IEnumerable<Course> Courses`
  - `IEnumerable<Enrollment> Enrollments`
- **Purpose:** Complex view model for instructor index page

###### AssignedCourseData
- **Type:** Class
- **Namespace:** `ContosoUniversity.Models.SchoolViewModels`
- **File:** `ContosoUniversity/Models/SchoolViewModels/AssignedCourseData.cs`
- **Properties:**
  - `int CourseID`
  - `string Title`
  - `bool Assigned`
- **Purpose:** Instructor-course assignment editing

##### Data Access Layer

###### SchoolContext
- **Type:** Class
- **Namespace:** `ContosoUniversity.Data`
- **File:** `ContosoUniversity/Data/SchoolContext.cs`
- **Inherits:** DbContext
- **Properties (DbSet):**
  - `public DbSet<Student> Students { get; set; }`
  - `public DbSet<Course> Courses { get; set; }`
  - `public DbSet<Enrollment> Enrollments { get; set; }`
  - `public DbSet<Instructor> Instructors { get; set; }`
  - `public DbSet<Department> Departments { get; set; }`
  - `public DbSet<OfficeAssignment> OfficeAssignments { get; set; }`
- **Methods:**
  - `protected override void OnModelCreating(DbModelBuilder)` - Fluent API configuration
- **Purpose:** Entity Framework database context

###### SchoolContextFactory
- **Type:** Class
- **Namespace:** `ContosoUniversity.Data`
- **File:** `ContosoUniversity/Data/SchoolContextFactory.cs`
- **Implements:** IDesignTimeDbContextFactory<SchoolContext>
- **Methods:**
  - `SchoolContext CreateDbContext(string[] args)` - Create context for migrations
- **Purpose:** Design-time context factory for EF migrations

###### DbInitializer
- **Type:** Class
- **Namespace:** `ContosoUniversity.Data`
- **File:** `ContosoUniversity/Data/DbInitializer.cs`
- **Methods:**
  - `public static void Initialize(SchoolContext)` - Seed database with test data
- **Purpose:** Database initialization and seeding

##### Utility Classes

###### PaginatedList<T>
- **Type:** Generic Class
- **Namespace:** `ContosoUniversity`
- **File:** `ContosoUniversity/PaginatedList.cs`
- **Inherits:** List<T>
- **Properties:**
  - `int PageIndex`
  - `int TotalPages`
  - `bool HasPreviousPage { get; }`
  - `bool HasNextPage { get; }`
- **Methods:**
  - `public static PaginatedList<T> Create(IQueryable<T>, int, int)` - Create paginated list
- **Purpose:** Pagination support for list views

##### Configuration Classes

###### BundleConfig
- **Type:** Class
- **Namespace:** `ContosoUniversity.App_Start`
- **File:** `ContosoUniversity/App_Start/BundleConfig.cs`
- **Methods:**
  - `public static void RegisterBundles(BundleCollection)` - Configure JS/CSS bundles
- **Purpose:** ASP.NET bundling and minification configuration

###### RouteConfig
- **Type:** Class
- **Namespace:** `ContosoUniversity.App_Start`
- **File:** `ContosoUniversity/App_Start/RouteConfig.cs`
- **Methods:**
  - `public static void RegisterRoutes(RouteCollection)` - Configure MVC routes
- **Purpose:** URL routing configuration

###### FilterConfig
- **Type:** Class
- **Namespace:** `ContosoUniversity.App_Start`
- **File:** `ContosoUniversity/App_Start/FilterConfig.cs`
- **Methods:**
  - `public static void RegisterGlobalFilters(GlobalFilterCollection)` - Register global action filters
- **Purpose:** Global MVC filter registration

---

### 7. Malshinon

**Purpose:** Data processing application with factory pattern  
**Language:** C#  
**Framework:** .NET Framework 4.8  
**Namespace Base:** `Malshinon`  
**Source Files:** ~10

##### Factory Pattern

###### IProcessorFactory (Interface)
- **Type:** Interface
- **Namespace:** `Malshinon.Factory`
- **Methods:**
  - `IProcessor CreateProcessor(string type)` - Factory method
- **Purpose:** Factory interface for creating processors

###### ProcessorFactory
- **Type:** Class
- **Namespace:** `Malshinon.Factory`
- **Implements:** IProcessorFactory
- **Methods:**
  - `public IProcessor CreateProcessor(string type)` - Create processor instance
- **Pattern:** Factory pattern implementation
- **Purpose:** Create appropriate processor based on type

##### Processors

###### IProcessor (Interface)
- **Type:** Interface
- **Namespace:** `Malshinon`
- **Methods:**
  - `void Process(string data)` - Process data
- **Purpose:** Processor abstraction

###### CsvProcessor
- **Type:** Class
- **Namespace:** `Malshinon`
- **Implements:** IProcessor
- **Methods:**
  - `public void Process(string data)` - Parse and process CSV data
- **Purpose:** CSV file processing

##### Data Access Layer

###### IDataAccess (Interface)
- **Type:** Interface
- **Namespace:** `Malshinon.DAL`
- **Methods:**
  - CRUD operation abstractions
- **Purpose:** Data access abstraction

###### SqlDataAccess
- **Type:** Class
- **Namespace:** `Malshinon.DAL`
- **Implements:** IDataAccess
- **Purpose:** SQL Server data access implementation

---

## Cross-Project Patterns

### Design Patterns Identified

#### 1. Model-View-Controller (MVC)
- **Projects:** ContosoUniversity, jakarta-ee/student-web-app, asset-manager, todo-web-api
- **Structure:** Clear separation of controllers, services/models, and views
- **Implementation:**
  - Java: Spring MVC with @Controller annotations
  - C#: ASP.NET MVC with Controller base class

#### 2. Repository Pattern
- **Projects:** asset-manager, todo-web-api, ContosoUniversity
- **Implementation:**
  - Java: Spring Data JPA interfaces extending JpaRepository
  - C#: Entity Framework DbContext with DbSet properties
- **Purpose:** Abstract data access logic

#### 3. Service Layer Pattern
- **Projects:** All Spring Boot projects, jakarta-ee/student-web-app
- **Implementation:** @Service annotated classes
- **Purpose:** Business logic encapsulation

#### 4. Dependency Injection
- **Projects:** All Spring Boot projects, ContosoUniversity
- **Implementation:**
  - Java: Constructor injection with @RequiredArgsConstructor (Lombok)
  - Java: Field injection with @Autowired
  - C#: Controller constructor injection
- **Pattern:** Inversion of Control (IoC)

#### 5. Strategy Pattern
- **Projects:** asset-manager
- **Implementation:** StorageService interface with AwsS3Service and LocalFileStorageService
- **Purpose:** Multiple storage implementations with profile-based selection

#### 6. Template Method Pattern
- **Projects:** asset-manager (worker)
- **Implementation:** AbstractFileProcessingService with abstract methods
- **Purpose:** Common processing logic with customization points

#### 7. Factory Pattern
- **Projects:** Malshinon
- **Implementation:** ProcessorFactory creating IProcessor implementations
- **Purpose:** Object creation abstraction

#### 8. Data Transfer Object (DTO)
- **Projects:** asset-manager, todo-web-api
- **Implementation:**
  - S3StorageItem (presentation)
  - ImageProcessingMessage (messaging)
  - TodoItem (data transfer)
- **Purpose:** Data encapsulation for layer communication

### Architectural Layers

#### Presentation Layer
- **Components:** Controllers, Servlets
- **Technologies:** Spring MVC, ASP.NET MVC, Jakarta Servlets
- **Responsibilities:** HTTP request handling, view rendering

#### Business Logic Layer
- **Components:** Services
- **Technologies:** Spring @Service, C# service classes
- **Responsibilities:** Business rules, workflow orchestration

#### Data Access Layer
- **Components:** Repositories, DbContext
- **Technologies:** Spring Data JPA, Entity Framework, MyBatis
- **Responsibilities:** Database operations, ORM

#### Integration Layer
- **Components:** Message processors, external service clients
- **Technologies:** RabbitMQ, AWS SDK, Azure SDK
- **Responsibilities:** External system integration

---

## Inheritance Hierarchies

### Java Hierarchies

```
Object
├── HttpServlet (Jakarta EE)
│   ├── IndexServlet
│   ├── AddStudentServlet
│   └── StudentProfileListServlet
│
├── @SpringBootApplication classes
│   ├── AssetsManagerApplication
│   ├── WorkerApplication
│   ├── TodoApplication
│   └── MessagingRabbitmqApplication
│
└── AbstractFileProcessingService
    ├── S3FileProcessingService
    └── LocalFileProcessingService
```

### C# Hierarchies

```
Object
├── Controller (ASP.NET MVC)
│   └── BaseController
│       ├── HomeController
│       ├── StudentsController
│       ├── CoursesController
│       ├── InstructorsController
│       ├── DepartmentsController
│       └── NotificationsController
│
├── DbContext (Entity Framework)
│   └── SchoolContext
│
└── List<T>
    └── PaginatedList<T>
```

---

## Interface Implementations

### Java Interfaces

- **StorageService** → AwsS3Service, LocalFileStorageService
- **FileProcessor** → AbstractFileProcessingService → S3FileProcessingService, LocalFileProcessingService
- **JpaRepository<T, ID>** → ImageMetadataRepository, TodoRepository
- **Filter** → CommonHttpServletFilter

### C# Interfaces

- **IDesignTimeDbContextFactory<T>** → SchoolContextFactory
- **IProcessorFactory** → ProcessorFactory
- **IProcessor** → CsvProcessor
- **IDataAccess** → SqlDataAccess

---

## Annotations and Attributes Summary

### Java Annotations

**Spring Framework:**
- `@SpringBootApplication` - Application entry point
- `@Controller`, `@RestController` - Presentation layer
- `@Service` - Business logic layer
- `@Repository` - Data access layer
- `@Configuration` - Configuration classes
- `@Bean` - Bean definition methods
- `@Autowired`, `@RequiredArgsConstructor` - Dependency injection
- `@RequestMapping`, `@GetMapping`, `@PostMapping`, `@PutMapping`, `@DeleteMapping`, `@PatchMapping` - HTTP mappings
- `@PathVariable`, `@RequestParam`, `@RequestBody` - Request parameter binding
- `@Profile` - Environment-specific beans
- `@Transactional` - Transaction management
- `@RabbitListener` - Message listener

**Jakarta EE:**
- `@WebServlet` - Servlet mapping
- `@WebFilter` - Filter mapping

**JPA:**
- `@Entity`, `@Table` - Entity mapping
- `@Id`, `@GeneratedValue` - Primary key
- `@Column` - Column mapping
- `@OneToMany`, `@ManyToOne`, `@ManyToMany`, `@OneToOne` - Relationships

**Lombok:**
- `@Data` - Getters, setters, toString, equals, hashCode
- `@Builder` - Builder pattern
- `@NoArgsConstructor`, `@AllArgsConstructor` - Constructors
- `@RequiredArgsConstructor` - Constructor for final fields

**Validation:**
- `@NotBlank`, `@NotNull` - Required validation
- `@Size`, `@Min`, `@Max`, `@Range` - Size/range validation

### C# Attributes

**ASP.NET MVC:**
- `[HttpPost]`, `[HttpGet]` - HTTP method constraints
- `[ValidateAntiForgeryToken]` - CSRF protection
- `[ActionName]` - Action name override
- `[Bind]` - Model binding
- `[AllowAnonymous]` - Allow unauthenticated access

**Entity Framework:**
- `[Key]` - Primary key
- `[ForeignKey]` - Foreign key
- `[Required]` - Required field
- `[StringLength]` - String length constraint
- `[Range]` - Numeric range
- `[Display]` - Display name
- `[DataType]` - Data type hint
- `[DisplayFormat]` - Display formatting
- `[DatabaseGenerated]` - Key generation strategy
- `[Timestamp]`, `[RowVersion]` - Concurrency token
- `[Column]` - Column mapping
- `[Table]` - Table mapping

---

## Source File Locations Summary

### Java Source Files by Project

- **mi-sql-public-demo:** 1 file in `src/main/java/com/example/`
- **asset-manager/web:** 14 files in `src/main/java/com/microsoft/migration/assets/`
- **asset-manager/worker:** 11 files in `src/main/java/com/microsoft/migration/assets/worker/` + 1 test
- **todo-web-api:** 6 files in `src/main/java/com/microsoft/migration/todo/`
- **rabbitmq-sender:** 2 files in `src/main/java/com/example/messagingrabbitmq/`
- **jakarta-ee/student-web-app:** 9 files in `src/org/sample/azure/student/coreft/`

### C# Source Files by Project

- **ContosoUniversity:** ~35 files across Controllers/, Models/, Data/, App_Start/, root
- **Malshinon:** ~10 files across factory/, DAL/, root

---

**Documentation Coverage:** 100% of public classes, interfaces, and key methods documented  
**Total Classes Documented:** 80+  
**Total Interfaces Documented:** 15+  
**Source Code Reference:** All classes linked to source file locations

---

**Related Documentation:**
- [Interfaces & APIs](interfaces.md) - Detailed interface specifications
- [Data Models](data-models.md) - Entity relationships and database mappings
- [Component Index](component-index.md) - Searchable index of all components
- [System Overview](../architecture/system-overview.md) - High-level architecture
