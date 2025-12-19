# Interfaces & Public APIs

**Analysis Date:** December 2024  
**Coverage:** All public interfaces and API contracts  
**Analysis Method:** Static Code Analysis

---

## Table of Contents
- [Overview](#overview)
- [Java Interfaces](#java-interfaces)
- [C# Interfaces](#c-interfaces)
- [REST API Specifications](#rest-api-specifications)
- [Message Queue Interfaces](#message-queue-interfaces)
- [Database Interfaces](#database-interfaces)

---

## Overview

This document catalogs all interfaces, public APIs, and contracts across the repository. Interfaces define:
- Service contracts for dependency injection
- Repository contracts for data access
- REST API endpoints for HTTP communication
- Message formats for async communication
- Extension points for plugin architectures

---

## Java Interfaces

### 1. StorageService

**Location:** `asset-manager/web/src/main/java/com/microsoft/migration/assets/service/StorageService.java`  
**Package:** `com.microsoft.migration.assets.service`  
**Purpose:** Abstraction for storage operations (Strategy pattern)  
**Implementations:** AwsS3Service, LocalFileStorageService

#### Method Signatures

```java
public interface StorageService {
    /**
     * List all objects in storage
     * @return List of storage items with keys, sizes, timestamps
     */
    List<S3StorageItem> listObjects();
    
    /**
     * Upload file to storage
     * @param file Multipart file from HTTP request
     * @throws IOException if upload fails
     */
    void uploadObject(MultipartFile file) throws IOException;
    
    /**
     * Get object from storage by key
     * @param key Storage object key
     * @return InputStream of object content
     * @throws IOException if object not found or retrieval fails
     */
    InputStream getObject(String key) throws IOException;

    /**
     * Delete object from storage by key
     * @param key Storage object key to delete
     * @throws IOException if deletion fails
     */
    void deleteObject(String key) throws IOException;

    /**
     * Get the storage type identifier
     * @return String identifier (e.g., "s3", "local")
     */
    String getStorageType();

    /**
     * Get the thumbnail key for a given original key
     * @param key Original object key
     * @return Thumbnail key with "_thumbnail" suffix before extension
     */
    default String getThumbnailKey(String key) {
        int dotIndex = key.lastIndexOf('.');
        if (dotIndex > 0) {
            return key.substring(0, dotIndex) + "_thumbnail" + key.substring(dotIndex);
        }
        return key + "_thumbnail";
    }

    /**
     * Generate a URL for viewing the object
     * @param key Object key
     * @return Relative URL path
     */
    default String generateUrl(String key) {
        return "/" + StorageConstants.STORAGE_PATH + "/view/" + key;
    }
}
```

#### Implementation Details

**AwsS3Service:**
- Profile: `@Profile("aws")`
- Storage: AWS S3 using SDK v2
- Features: RabbitMQ message publishing, metadata persistence

**LocalFileStorageService:**
- Profile: `@Profile("local")`
- Storage: Local filesystem
- Features: File-based storage for development/testing

---

### 2. FileProcessor

**Location:** `asset-manager/worker/src/main/java/com/microsoft/migration/assets/worker/service/FileProcessor.java`  
**Package:** `com.microsoft.migration.assets.worker.service`  
**Purpose:** File processing abstraction for worker module  
**Implementations:** AbstractFileProcessingService → S3FileProcessingService, LocalFileProcessingService

#### Method Signatures

```java
public interface FileProcessor {
    /**
     * Process an incoming image processing message
     * @param message Image processing message from queue
     */
    void processMessage(ImageProcessingMessage message);
}
```

#### Template Method Pattern (AbstractFileProcessingService)

```java
public abstract class AbstractFileProcessingService implements FileProcessor {
    /**
     * Download file from storage (implementation-specific)
     * @param key Storage object key
     * @return InputStream of file content
     * @throws IOException if download fails
     */
    protected abstract InputStream downloadFile(String key) throws IOException;
    
    /**
     * Upload thumbnail to storage (implementation-specific)
     * @param key Thumbnail storage key
     * @param thumbnailData Byte array of thumbnail image
     * @throws IOException if upload fails
     */
    protected abstract void uploadThumbnail(String key, byte[] thumbnailData) throws IOException;
    
    /**
     * Generate thumbnail from input stream (common logic)
     * @param inputStream Original image stream
     * @return Byte array of thumbnail image
     * @throws IOException if generation fails
     */
    protected byte[] generateThumbnail(InputStream inputStream) throws IOException {
        // Thumbnail generation logic (resizing, compression)
    }
    
    /**
     * Process message (template method - common workflow)
     * @param message Image processing message
     */
    @Override
    public void processMessage(ImageProcessingMessage message) {
        // 1. Download original file
        // 2. Generate thumbnail
        // 3. Upload thumbnail
        // 4. Update metadata
    }
}
```

---

### 3. JpaRepository Interfaces (Spring Data)

#### ImageMetadataRepository (Web)

**Location:** `asset-manager/web/src/main/java/com/microsoft/migration/assets/repository/ImageMetadataRepository.java`  
**Package:** `com.microsoft.migration.assets.repository`  
**Extends:** `JpaRepository<ImageMetadata, Long>`  
**Entity:** ImageMetadata  
**Purpose:** PostgreSQL data access for image metadata

#### ImageMetadataRepository (Worker)

**Location:** `asset-manager/worker/src/main/java/com/microsoft/migration/assets/worker/repository/ImageMetadataRepository.java`  
**Package:** `com.microsoft.migration.assets.worker.repository`  
**Extends:** `JpaRepository<ImageMetadata, Long>`  
**Purpose:** Worker module data access

#### TodoRepository

**Location:** `todo-web-api-use-oracle-db/src/main/java/com/microsoft/migration/todo/repository/TodoRepository.java`  
**Package:** `com.microsoft.migration.todo.repository`  
**Extends:** `JpaRepository<TodoItem, Long>`  
**Entity:** TodoItem  
**Database:** Oracle Database  
**Purpose:** Todo item CRUD operations

#### Standard JpaRepository Methods (Inherited)

```java
public interface JpaRepository<T, ID> extends ListCrudRepository<T, ID>, 
                                               ListPagingAndSortingRepository<T, ID>, 
                                               QueryByExampleExecutor<T> {
    // CRUD Operations
    <S extends T> S save(S entity);
    <S extends T> List<S> saveAll(Iterable<S> entities);
    Optional<T> findById(ID id);
    boolean existsById(ID id);
    List<T> findAll();
    List<T> findAllById(Iterable<ID> ids);
    long count();
    void deleteById(ID id);
    void delete(T entity);
    void deleteAllById(Iterable<? extends ID> ids);
    void deleteAll(Iterable<? extends T> entities);
    void deleteAll();
    
    // Batch Operations
    void flush();
    <S extends T> S saveAndFlush(S entity);
    <S extends T> List<S> saveAllAndFlush(Iterable<S> entities);
    void deleteAllInBatch(Iterable<T> entities);
    void deleteAllByIdInBatch(Iterable<ID> ids);
    void deleteAllInBatch();
    
    // Reference Operations
    T getOne(ID id); // Deprecated
    T getById(ID id); // Returns reference
    T getReferenceById(ID id); // Preferred in newer versions
}
```

---

### 4. Jakarta EE Filter Interface

#### CommonHttpServletFilter

**Location:** `jakarta-ee/student-web-app/src/org/sample/azure/student/coreft/filter/CommonHttpServletFilter.java`  
**Package:** `org.sample.azure.student.coreft.filter`  
**Implements:** `Filter` (jakarta.servlet.Filter)  
**URL Pattern:** `/*` (all requests)

#### Method Signatures

```java
public class CommonHttpServletFilter implements Filter {
    /**
     * Initialize filter
     * @param filterConfig Filter configuration
     */
    @Override
    public void init(FilterConfig filterConfig) throws ServletException {
        // Initialization logic
    }
    
    /**
     * Filter requests and responses
     * @param request ServletRequest
     * @param response ServletResponse
     * @param chain FilterChain to continue request processing
     */
    @Override
    public void doFilter(ServletRequest request, 
                         ServletResponse response, 
                         FilterChain chain) 
            throws IOException, ServletException {
        // Pre-processing
        chain.doFilter(request, response); // Continue chain
        // Post-processing
    }
    
    /**
     * Cleanup filter resources
     */
    @Override
    public void destroy() {
        // Cleanup logic
    }
}
```

---

## C# Interfaces

### 1. IDesignTimeDbContextFactory<TContext>

**Location:** `ContosoUniversity/Data/SchoolContextFactory.cs`  
**Namespace:** `ContosoUniversity.Data`  
**Implemented By:** SchoolContextFactory  
**Purpose:** Entity Framework design-time context creation for migrations

#### Method Signatures

```csharp
public interface IDesignTimeDbContextFactory<TContext> 
    where TContext : DbContext
{
    /// <summary>
    /// Create a DbContext instance for design-time operations
    /// </summary>
    /// <param name="args">Command-line arguments</param>
    /// <returns>DbContext instance</returns>
    TContext CreateDbContext(string[] args);
}
```

#### Implementation

```csharp
public class SchoolContextFactory : IDesignTimeDbContextFactory<SchoolContext>
{
    public SchoolContext CreateDbContext(string[] args)
    {
        var optionsBuilder = new DbContextOptionsBuilder<SchoolContext>();
        // Configure connection string from configuration
        optionsBuilder.UseSqlServer(connectionString);
        return new SchoolContext(optionsBuilder.Options);
    }
}
```

---

### 2. IProcessorFactory

**Location:** `Malshinon/Factory/IProcessorFactory.cs`  
**Namespace:** `Malshinon.Factory`  
**Implemented By:** ProcessorFactory  
**Purpose:** Factory pattern for creating processors  
**Pattern:** Factory Method

#### Method Signatures

```csharp
public interface IProcessorFactory
{
    /// <summary>
    /// Create processor based on type identifier
    /// </summary>
    /// <param name="type">Processor type identifier</param>
    /// <returns>Processor instance</returns>
    IProcessor CreateProcessor(string type);
}
```

---

### 3. IProcessor

**Location:** `Malshinon/IProcessor.cs`  
**Namespace:** `Malshinon`  
**Implemented By:** CsvProcessor, [other processors]  
**Purpose:** Data processing abstraction

#### Method Signatures

```csharp
public interface IProcessor
{
    /// <summary>
    /// Process data
    /// </summary>
    /// <param name="data">Data to process</param>
    void Process(string data);
}
```

---

### 4. IDataAccess

**Location:** `Malshinon/DAL/IDataAccess.cs`  
**Namespace:** `Malshinon.DAL`  
**Implemented By:** SqlDataAccess  
**Purpose:** Data access layer abstraction

#### Method Signatures (Inferred)

```csharp
public interface IDataAccess
{
    // CRUD operations
    void Create<T>(T entity);
    T Read<T>(int id);
    void Update<T>(T entity);
    void Delete<T>(int id);
    IEnumerable<T> GetAll<T>();
}
```

---

## REST API Specifications

### asset-manager REST API

#### Base URL
- Development: `http://localhost:8080`
- Profile-dependent storage path: `/s3` or `/local`

#### Endpoints

##### 1. List Objects
```
GET /{STORAGE_PATH}
```
**Purpose:** List all stored objects  
**Controller:** S3Controller.listObjects()  
**Response:** HTML view with object list  
**Model Attribute:** `List<S3StorageItem> objects`

##### 2. Show Upload Form
```
GET /{STORAGE_PATH}/upload
```
**Purpose:** Display file upload form  
**Controller:** S3Controller.uploadForm()  
**Response:** HTML upload form view

##### 3. Upload File
```
POST /{STORAGE_PATH}/upload
Content-Type: multipart/form-data
```
**Purpose:** Upload file to storage  
**Controller:** S3Controller.uploadObject()  
**Request Parameters:**
- `file`: MultipartFile (required, non-empty)

**Success Response:**
- Redirect to `/{STORAGE_PATH}`
- Flash attribute: `success = "File uploaded successfully"`

**Error Responses:**
- Empty file: Flash attribute `error = "Please select a file to upload"`
- Upload failure: Flash attribute `error = "Failed to upload file: {message}"`

**Side Effects:**
- File stored in S3/local storage
- Metadata saved to PostgreSQL
- RabbitMQ message published for processing (AWS profile only)

##### 4. View Object Page
```
GET /{STORAGE_PATH}/view-page/{key}
```
**Purpose:** Display object details page  
**Controller:** S3Controller.viewObjectPage()  
**Path Variable:** `key` - Storage object key  
**Response:** HTML view with object details  
**Model Attribute:** `S3StorageItem object`

**Error Response:**
- Object not found: Redirect with error message

##### 5. Stream Object Content
```
GET /{STORAGE_PATH}/view/{key}
```
**Purpose:** Download/stream object content  
**Controller:** S3Controller.viewObject()  
**Path Variable:** `key` - Storage object key  
**Response:**
- Status: 200 OK
- Body: InputStreamResource (file content)
- Content-Type: application/octet-stream

**Error Response:**
- Status: 404 Not Found (if object doesn't exist)

##### 6. Delete Object
```
POST /{STORAGE_PATH}/delete/{key}
```
**Purpose:** Delete object from storage  
**Controller:** S3Controller.deleteObject()  
**Path Variable:** `key` - Storage object key  
**Response:** Redirect to `/{STORAGE_PATH}`

**Flash Attributes:**
- Success: `success = "File deleted successfully"`
- Failure: `error = "Failed to delete file: {message}"`

---

### todo-web-api REST API

#### Base URL
- Development: `http://localhost:8080`
- API Path: `/api/todos`

#### Endpoints

##### 1. Get All Todos
```
GET /api/todos
```
**Purpose:** Retrieve all todo items  
**Controller:** TodoController.getAllTodos()  
**Response:**
```json
[
  {
    "id": 1,
    "title": "Task title",
    "description": "Task description",
    "completed": false,
    "createdAt": "2024-12-01T10:00:00",
    "updatedAt": "2024-12-01T10:00:00"
  }
]
```
**Status:** 200 OK

##### 2. Get Todo by ID
```
GET /api/todos/{id}
```
**Purpose:** Retrieve specific todo item  
**Controller:** TodoController.getTodoById()  
**Path Variable:** `id` - Todo item ID  
**Success Response:**
- Status: 200 OK
- Body: TodoItem JSON

**Error Response:**
- Status: 404 Not Found (if ID doesn't exist)

##### 3. Create Todo
```
POST /api/todos
Content-Type: application/json
```
**Purpose:** Create new todo item  
**Controller:** TodoController.createTodo()  
**Request Body:**
```json
{
  "title": "New task",
  "description": "Task description",
  "completed": false
}
```
**Validation:**
- `title`: Required, not blank, max 255 characters
- `description`: Optional, max 1000 characters
- `completed`: Optional, defaults to false

**Success Response:**
- Status: 201 Created
- Body: Created TodoItem with generated ID and timestamps

**Error Response:**
- Status: 400 Bad Request (validation failures)

##### 4. Update Todo
```
PUT /api/todos/{id}
Content-Type: application/json
```
**Purpose:** Update existing todo item  
**Controller:** TodoController.updateTodo()  
**Path Variable:** `id` - Todo item ID  
**Request Body:** TodoItem JSON (full replacement)

**Success Response:**
- Status: 200 OK
- Body: Updated TodoItem

**Error Responses:**
- Status: 404 Not Found (if ID doesn't exist)
- Status: 400 Bad Request (validation failures)

##### 5. Delete Todo
```
DELETE /api/todos/{id}
```
**Purpose:** Delete todo item  
**Controller:** TodoController.deleteTodo()  
**Path Variable:** `id` - Todo item ID  
**Success Response:**
- Status: 204 No Content

**Error Response:**
- Status: 404 Not Found (if ID doesn't exist)

##### 6. Complete Todo
```
PATCH /api/todos/{id}/complete
```
**Purpose:** Mark todo as completed  
**Controller:** TodoController.completeTodo()  
**Path Variable:** `id` - Todo item ID  
**Success Response:**
- Status: 200 OK
- Body: Updated TodoItem with `completed=true`

**Error Response:**
- Status: 404 Not Found (if ID doesn't exist)

---

### ContosoUniversity MVC Routes

#### Base URL Pattern
```
/{controller}/{action}/{id}
```
**Default Route:** `Home/Index`

#### Student Routes

```
GET  /Students                      → Index (list with paging/sorting)
GET  /Students/Details/{id}         → Details
GET  /Students/Create               → Create (form)
POST /Students/Create               → Create (submit)
GET  /Students/Edit/{id}            → Edit (form)
POST /Students/Edit/{id}            → Edit (submit)
GET  /Students/Delete/{id}          → Delete (confirmation)
POST /Students/Delete/{id}          → DeleteConfirmed
```

**Similar patterns for:**
- `/Courses` - Course management
- `/Instructors` - Instructor management
- `/Departments` - Department management
- `/Notifications` - Notification management

---

## Message Queue Interfaces

### RabbitMQ Message Formats

#### ImageProcessingMessage

**Purpose:** Async communication between asset-manager web and worker  
**Queue:** Image processing queue  
**Direction:** Web → Worker

**Message Structure (Java):**
```java
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ImageProcessingMessage {
    private String key;          // S3 object key
    private String filename;     // Original filename
    private String operation;    // Operation type (e.g., "thumbnail")
}
```

**JSON Format:**
```json
{
  "key": "uploads/image123.jpg",
  "filename": "original_image.jpg",
  "operation": "thumbnail"
}
```

**Producer:** AwsS3Service (in uploadObject method)  
**Consumer:** S3FileProcessingService (@RabbitListener annotation)

**Processing Flow:**
1. Web module uploads file to S3
2. Web module publishes ImageProcessingMessage to queue
3. Worker module consumes message
4. Worker downloads original, generates thumbnail, uploads thumbnail
5. Worker updates metadata with thumbnail key

---

## Database Interfaces

### JPA/Entity Framework Contracts

#### Entity Annotations/Attributes

**Java (JPA):**
```java
@Entity
@Table(name = "table_name")
public class EntityClass {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @Column(name = "column_name", nullable = false, length = 255)
    private String field;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "foreign_key_column")
    private RelatedEntity relatedEntity;
}
```

**C# (Entity Framework):**
```csharp
[Table("TableName")]
public class EntityClass
{
    [Key]
    [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
    public int Id { get; set; }
    
    [Column("ColumnName")]
    [Required]
    [StringLength(255)]
    public string Field { get; set; }
    
    [ForeignKey("RelatedEntityId")]
    public virtual RelatedEntity RelatedEntity { get; set; }
}
```

#### DbContext Interface (C#)

```csharp
public class SchoolContext : DbContext
{
    // Entity sets (tables)
    public DbSet<Student> Students { get; set; }
    public DbSet<Course> Courses { get; set; }
    
    // Configuration
    protected override void OnModelCreating(DbModelBuilder modelBuilder)
    {
        // Fluent API configuration
        modelBuilder.Entity<Student>()
            .HasMany(s => s.Enrollments)
            .WithRequired(e => e.Student)
            .HasForeignKey(e => e.StudentID);
    }
}
```

---

## API Contract Summary

### Java Spring Boot APIs

| Project | Base Path | Endpoints | Response Format | Authentication |
|---------|-----------|-----------|-----------------|----------------|
| asset-manager | `/{storage}` | 6 | HTML + Binary | None |
| todo-web-api | `/api/todos` | 6 | JSON | None |
| rabbitmq-sender | N/A | N/A (CLI) | N/A | N/A |

### .NET MVC APIs

| Project | Pattern | Controllers | Response Format | Authentication |
|---------|---------|-------------|-----------------|----------------|
| ContosoUniversity | `/{controller}/{action}/{id}` | 7 | HTML | Role-based |

### Messaging APIs

| Project | Queue | Message Type | Format | Protocol |
|---------|-------|--------------|--------|----------|
| asset-manager | Image processing | ImageProcessingMessage | JSON | AMQP |

---

## Interface Usage Patterns

### Dependency Injection

**Java (Constructor Injection):**
```java
@Controller
@RequiredArgsConstructor // Lombok
public class S3Controller {
    private final StorageService storageService; // Interface injection
}
```

**C# (Constructor Injection):**
```csharp
public class StudentsController : BaseController
{
    private readonly INotificationService _notificationService;
    
    public StudentsController(INotificationService notificationService)
    {
        _notificationService = notificationService;
    }
}
```

### Profile-Based Implementation Selection

```java
@Service
@Profile("aws")
public class AwsS3Service implements StorageService {
    // AWS implementation
}

@Service
@Profile("local")
public class LocalFileStorageService implements StorageService {
    // Local implementation
}
```

---

## Contract Evolution Considerations

### Backward Compatibility
- REST API version changes require new endpoints or version headers
- Message format changes require queue migration strategies
- Interface method additions should use default methods (Java 8+)

### Documentation Requirements
- All public API methods require Javadoc/XML comments
- Breaking changes must be documented in CHANGELOG
- Deprecation warnings must include migration paths

---

**Related Documentation:**
- [Program Structure](program-structure.md) - Implementation classes
- [Data Models](data-models.md) - Entity definitions
- [Architecture Patterns](../architecture/patterns.md) - Design pattern usage
- [Migration Guide](../migration/component-order.md) - Interface stability during migration
