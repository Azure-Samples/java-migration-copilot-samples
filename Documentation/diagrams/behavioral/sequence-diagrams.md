# Sequence Diagrams - Interaction Flows

**Analysis Date:** December 2024  
**Format:** Mermaid text-based diagrams

---

## asset-manager: File Upload Flow

```mermaid
sequenceDiagram
    participant User
    participant WebController
    participant StorageService
    participant S3
    participant PostgreSQL
    participant RabbitMQ
    participant Worker
    
    User->>WebController: POST /s3/upload (file)
    WebController->>WebController: Validate file not empty
    WebController->>StorageService: uploadObject(file)
    StorageService->>S3: putObject(key, data)
    S3-->>StorageService: Success
    StorageService->>PostgreSQL: save(ImageMetadata)
    PostgreSQL-->>StorageService: Saved
    StorageService->>RabbitMQ: send(ImageProcessingMessage)
    RabbitMQ-->>StorageService: Queued
    StorageService-->>WebController: Success
    WebController-->>User: Redirect to /s3 (success)
    
    RabbitMQ->>Worker: deliver(ImageProcessingMessage)
    Worker->>S3: getObject(key)
    S3-->>Worker: File stream
    Worker->>Worker: generateThumbnail()
    Worker->>S3: putObject(thumbnailKey, thumbnail)
    Worker->>PostgreSQL: update(thumbnailKey)
    Worker-->>RabbitMQ: ACK
```

---

## todo-web-api: Create Todo Flow

```mermaid
sequenceDiagram
    participant Client
    participant TodoController
    participant TodoService
    participant TodoRepository
    participant OracleDB
    
    Client->>TodoController: POST /api/todos (JSON)
    TodoController->>TodoController: Validate (@Valid)
    TodoController->>TodoService: createTodo(todoItem)
    TodoService->>TodoService: Set defaults (completed=false)
    TodoService->>TodoRepository: save(todoItem)
    TodoRepository->>OracleDB: INSERT INTO TODO_ITEMS
    OracleDB-->>TodoRepository: Generated ID
    TodoRepository-->>TodoService: TodoItem with ID
    TodoService-->>TodoController: Created TodoItem
    TodoController-->>Client: 201 Created (JSON)
```

---

## ContosoUniversity: Student Creation Flow

```mermaid
sequenceDiagram
    participant User
    participant StudentsController
    participant SchoolContext
    participant NotificationService
    participant SQLServer
    
    User->>StudentsController: POST /Students/Create (form data)
    StudentsController->>StudentsController: Validate ModelState
    StudentsController->>StudentsController: Check datetime range (1753-9999)
    StudentsController->>SchoolContext: Students.Add(student)
    StudentsController->>SchoolContext: SaveChanges()
    SchoolContext->>SQLServer: INSERT INTO Student
    SQLServer-->>SchoolContext: Success
    SchoolContext-->>StudentsController: Saved
    StudentsController->>NotificationService: SendNotification(CREATE)
    NotificationService-->>StudentsController: Sent
    StudentsController-->>User: Redirect to /Students
```

---

## mi-sql-public-demo: Managed Identity Authentication

```mermaid
sequenceDiagram
    participant App as MainSQL
    participant AzureAD as Azure AD
    participant SQLServer as SQL Server
    
    App->>AzureAD: Request Managed Identity token
    AzureAD-->>App: Access token
    App->>SQLServer: Connect (token in connection string)
    SQLServer->>AzureAD: Validate token
    AzureAD-->>SQLServer: Token valid
    SQLServer-->>App: Connection established
    App->>SQLServer: Execute query
    SQLServer-->>App: ResultSet
    App->>App: Process results
```

---

**Related Documentation:**
- [Workflows](../../behavior/workflows.md)
- [Activity Diagrams](activity-diagrams.md)
- [Business Logic](../../behavior/business-logic.md)
