# API Reference - Complete Endpoint Documentation

**Analysis Date:** December 2024  
**Total APIs:** 3 Web Applications  
**Protocol:** HTTP/HTTPS  
**Formats:** JSON, HTML, Binary Streams

---

## Table of Contents
- [Overview](#overview)
- [asset-manager Web API](#asset-manager-web-api)
- [todo-web-api REST API](#todo-web-api-rest-api)
- [ContosoUniversity MVC Routes](#contosouniversity-mvc-routes)
- [Common Patterns](#common-patterns)
- [Error Handling](#error-handling)

---

## Overview

This document provides complete API specifications for all web applications in the repository. Each API includes:
- Base URLs and routing patterns
- HTTP methods and endpoints
- Request/response formats
- Authentication requirements
- Error responses
- Usage examples

---

## asset-manager Web API

**Base URL:** `http://localhost:8080` (development)  
**Storage Path:** Profile-dependent (`/s3` for AWS, `/local` for local)  
**Framework:** Spring Boot 2.7.18  
**Response Format:** HTML views + Binary streams  
**Authentication:** None (demonstration application)

### Endpoints

#### 1. GET /{storage}

**Purpose:** List all stored objects  
**Controller:** `S3Controller.listObjects()`  
**Method:** GET  
**Path:** `/{STORAGE_PATH}` (e.g., `/s3` or `/local`)  
**Request Parameters:** None

**Response:**
- **Type:** HTML (Thymeleaf template)
- **View:** `list.html`
- **Model Attributes:**
  - `objects` - List<S3StorageItem>

**Example Objects:**
```json
[
  {
    "key": "uploads/image1.jpg",
    "size": 245760,
    "lastModified": "2024-12-01T10:30:00Z",
    "url": "/s3/view/uploads/image1.jpg"
  }
]
```

**Status Codes:**
- 200 OK - Success

---

#### 2. GET /{storage}/upload

**Purpose:** Display file upload form  
**Controller:** `S3Controller.uploadForm()`  
**Method:** GET  
**Path:** `/{STORAGE_PATH}/upload`

**Response:**
- **Type:** HTML
- **View:** `upload.html`
- **Contains:** File input form with multipart/form-data encoding

**Status Codes:**
- 200 OK - Form displayed

---

#### 3. POST /{storage}/upload

**Purpose:** Upload file to storage  
**Controller:** `S3Controller.uploadObject()`  
**Method:** POST  
**Path:** `/{STORAGE_PATH}/upload`  
**Content-Type:** `multipart/form-data`

**Request Parameters:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| file | MultipartFile | Yes | File to upload |

**Processing Flow:**
1. Validate file is not empty
2. Upload file to storage (S3 or local)
3. Save metadata to PostgreSQL
4. Publish message to RabbitMQ (AWS profile only)
5. Redirect to list page with success message

**Success Response:**
- **Type:** Redirect
- **Location:** `/{STORAGE_PATH}`
- **Flash Attribute:** `success = "File uploaded successfully"`

**Error Responses:**
- **Empty File:**
  - Redirect to upload form
  - Flash Attribute: `error = "Please select a file to upload"`
- **Upload Failed:**
  - Redirect to upload form
  - Flash Attribute: `error = "Failed to upload file: {errorMessage}"`

**Status Codes:**
- 302 Found - Redirect after processing
- 200 OK - Form re-displayed on validation error

**Side Effects:**
- File stored in S3/local storage
- ImageMetadata record created in PostgreSQL
- ImageProcessingMessage sent to RabbitMQ (AWS profile)

---

#### 4. GET /{storage}/view-page/{key}

**Purpose:** Display object details page  
**Controller:** `S3Controller.viewObjectPage()`  
**Method:** GET  
**Path:** `/{STORAGE_PATH}/view-page/{key}`

**Path Variables:**
| Variable | Type | Description |
|----------|------|-------------|
| key | String | Storage object key |

**Response:**
- **Type:** HTML
- **View:** `view.html`
- **Model Attributes:**
  - `object` - S3StorageItem with details

**Error Response:**
- **Object Not Found:**
  - Redirect to list page
  - Flash Attribute: `error = "Image not found"`
- **Retrieval Failed:**
  - Redirect to list page
  - Flash Attribute: `error = "Failed to view image: {errorMessage}"`

**Status Codes:**
- 200 OK - Object found
- 302 Found - Redirect on error

---

#### 5. GET /{storage}/view/{key}

**Purpose:** Stream object content (download/display)  
**Controller:** `S3Controller.viewObject()`  
**Method:** GET  
**Path:** `/{STORAGE_PATH}/view/{key}`

**Path Variables:**
| Variable | Type | Description |
|----------|------|-------------|
| key | String | Storage object key |

**Response:**
- **Type:** Binary stream
- **Body:** InputStreamResource
- **Headers:**
  - `Content-Type: application/octet-stream`

**Status Codes:**
- 200 OK - Object streamed successfully
- 404 Not Found - Object doesn't exist

**Usage:**
- Can be used as `<img src="/s3/view/{key}">` for images
- Browser will render or prompt download based on content type

---

#### 6. POST /{storage}/delete/{key}

**Purpose:** Delete object from storage  
**Controller:** `S3Controller.deleteObject()`  
**Method:** POST  
**Path:** `/{STORAGE_PATH}/delete/{key}`

**Path Variables:**
| Variable | Type | Description |
|----------|------|-------------|
| key | String | Storage object key to delete |

**Processing:**
1. Delete object from S3/local storage
2. Delete metadata from PostgreSQL
3. Redirect to list page

**Success Response:**
- **Type:** Redirect
- **Location:** `/{STORAGE_PATH}`
- **Flash Attribute:** `success = "File deleted successfully"`

**Error Response:**
- **Deletion Failed:**
  - Redirect to list page
  - Flash Attribute: `error = "Failed to delete file: {errorMessage}"`

**Status Codes:**
- 302 Found - Redirect after processing

**Side Effects:**
- Object removed from storage
- ImageMetadata record deleted from database

---

## todo-web-api REST API

**Base URL:** `http://localhost:8080` (development)  
**API Path:** `/api/todos`  
**Framework:** Spring Boot 3.2.4  
**Response Format:** JSON  
**Content-Type:** `application/json`  
**Authentication:** None (demonstration application)  
**Database:** Oracle Database

### Endpoints

#### 1. GET /api/todos

**Purpose:** Retrieve all todo items  
**Controller:** `TodoController.getAllTodos()`  
**Method:** GET  
**Path:** `/api/todos`

**Request:** No parameters

**Response:**
```json
[
  {
    "id": 1,
    "title": "Complete project documentation",
    "description": "Write comprehensive API docs",
    "completed": false,
    "priority": 1,
    "dueDate": "2024-12-31T23:59:59",
    "createdAt": "2024-12-01T10:00:00",
    "updatedAt": "2024-12-01T10:00:00"
  },
  {
    "id": 2,
    "title": "Review code changes",
    "description": null,
    "completed": true,
    "priority": 2,
    "dueDate": null,
    "createdAt": "2024-11-28T14:30:00",
    "updatedAt": "2024-12-01T09:15:00"
  }
]
```

**Status Codes:**
- 200 OK - Success (may return empty array)

---

#### 2. GET /api/todos/{id}

**Purpose:** Retrieve specific todo item by ID  
**Controller:** `TodoController.getTodoById()`  
**Method:** GET  
**Path:** `/api/todos/{id}`

**Path Variables:**
| Variable | Type | Description |
|----------|------|-------------|
| id | Long | Todo item ID |

**Success Response:**
```json
{
  "id": 1,
  "title": "Complete project documentation",
  "description": "Write comprehensive API docs",
  "completed": false,
  "priority": 1,
  "dueDate": "2024-12-31T23:59:59",
  "createdAt": "2024-12-01T10:00:00",
  "updatedAt": "2024-12-01T10:00:00"
}
```

**Error Response:**
```json
{
  "timestamp": "2024-12-01T10:30:00",
  "status": 404,
  "error": "Not Found",
  "message": "Todo item not found with id: 999",
  "path": "/api/todos/999"
}
```

**Status Codes:**
- 200 OK - Todo found
- 404 Not Found - Todo doesn't exist

---

#### 3. POST /api/todos

**Purpose:** Create new todo item  
**Controller:** `TodoController.createTodo()`  
**Method:** POST  
**Path:** `/api/todos`  
**Content-Type:** `application/json`

**Request Body:**
```json
{
  "title": "New todo item",
  "description": "Optional description",
  "completed": false,
  "priority": 1,
  "dueDate": "2024-12-31T23:59:59"
}
```

**Field Specifications:**
| Field | Type | Required | Constraints | Default |
|-------|------|----------|-------------|---------|
| title | String | Yes | Max 200 chars, not blank | - |
| description | String | No | Max 4000 chars | null |
| completed | Boolean | No | - | false |
| priority | Integer | No | - | 0 |
| dueDate | DateTime | No | ISO-8601 format | null |

**Success Response:**
```json
{
  "id": 3,
  "title": "New todo item",
  "description": "Optional description",
  "completed": false,
  "priority": 1,
  "dueDate": "2024-12-31T23:59:59",
  "createdAt": "2024-12-01T11:00:00",
  "updatedAt": "2024-12-01T11:00:00"
}
```

**Validation Error Response:**
```json
{
  "timestamp": "2024-12-01T11:00:00",
  "status": 400,
  "error": "Bad Request",
  "message": "Validation failed",
  "errors": [
    {
      "field": "title",
      "message": "Title is required"
    }
  ]
}
```

**Status Codes:**
- 201 Created - Todo created successfully
- 400 Bad Request - Validation failed

**Side Effects:**
- TodoItem record created in Oracle database
- Timestamps automatically set

---

#### 4. PUT /api/todos/{id}

**Purpose:** Update existing todo item (full replacement)  
**Controller:** `TodoController.updateTodo()`  
**Method:** PUT  
**Path:** `/api/todos/{id}`  
**Content-Type:** `application/json`

**Path Variables:**
| Variable | Type | Description |
|----------|------|-------------|
| id | Long | Todo item ID to update |

**Request Body:**
```json
{
  "title": "Updated todo title",
  "description": "Updated description",
  "completed": true,
  "priority": 2,
  "dueDate": "2024-12-15T18:00:00"
}
```

**Success Response:**
```json
{
  "id": 1,
  "title": "Updated todo title",
  "description": "Updated description",
  "completed": true,
  "priority": 2,
  "dueDate": "2024-12-15T18:00:00",
  "createdAt": "2024-12-01T10:00:00",
  "updatedAt": "2024-12-01T11:30:00"
}
```

**Status Codes:**
- 200 OK - Todo updated successfully
- 400 Bad Request - Validation failed
- 404 Not Found - Todo doesn't exist

**Side Effects:**
- TodoItem record updated in database
- `updatedAt` timestamp automatically updated

---

#### 5. DELETE /api/todos/{id}

**Purpose:** Delete todo item  
**Controller:** `TodoController.deleteTodo()`  
**Method:** DELETE  
**Path:** `/api/todos/{id}`

**Path Variables:**
| Variable | Type | Description |
|----------|------|-------------|
| id | Long | Todo item ID to delete |

**Success Response:**
- No content

**Status Codes:**
- 204 No Content - Todo deleted successfully
- 404 Not Found - Todo doesn't exist

**Side Effects:**
- TodoItem record deleted from database

---

#### 6. PATCH /api/todos/{id}/complete

**Purpose:** Mark todo as completed (partial update)  
**Controller:** `TodoController.completeTodo()`  
**Method:** PATCH  
**Path:** `/api/todos/{id}/complete`

**Path Variables:**
| Variable | Type | Description |
|----------|------|-------------|
| id | Long | Todo item ID to complete |

**Request:** No body required

**Success Response:**
```json
{
  "id": 1,
  "title": "Complete project documentation",
  "description": "Write comprehensive API docs",
  "completed": true,
  "priority": 1,
  "dueDate": "2024-12-31T23:59:59",
  "createdAt": "2024-12-01T10:00:00",
  "updatedAt": "2024-12-01T12:00:00"
}
```

**Status Codes:**
- 200 OK - Todo marked as completed
- 404 Not Found - Todo doesn't exist

**Side Effects:**
- `completed` field set to true
- `updatedAt` timestamp updated

---

## ContosoUniversity MVC Routes

**Base URL:** `http://localhost` (IIS/IIS Express)  
**Framework:** ASP.NET MVC 5 (.NET Framework 4.8)  
**Response Format:** HTML (Razor views)  
**Authentication:** Role-based (not fully implemented in sample)  
**Default Route:** `/{controller}/{action}/{id}`

### Route Pattern

```
{controller}/{action}/{id}
```
- **controller:** Controller name without "Controller" suffix
- **action:** Action method name
- **id:** Optional parameter

**Examples:**
- `/Students/Index` → StudentsController.Index()
- `/Students/Details/5` → StudentsController.Details(5)
- `/Courses/Create` → CoursesController.Create() (GET)

### Students Controller Routes

#### 1. GET /Students or /Students/Index

**Action:** `StudentsController.Index()`  
**Purpose:** List all students with pagination, sorting, and search

**Query Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| sortOrder | String | Sort field: "" (LastName asc), "name_desc", "Date", "date_desc" |
| currentFilter | String | Current search string (for pagination) |
| searchString | String | Search term for LastName or FirstMidName |
| page | int? | Page number (1-based) |

**Example URLs:**
- `/Students` - Default (sorted by LastName)
- `/Students?sortOrder=Date&page=2` - Sort by enrollment date, page 2
- `/Students?searchString=Smith` - Search for "Smith"

**Response:**
- **View:** `Index.cshtml`
- **Model:** `PaginatedList<Student>`
- **ViewBag:**
  - `CurrentSort` - Current sort order
  - `NameSortParm` - Next name sort parameter
  - `DateSortParm` - Next date sort parameter
  - `CurrentFilter` - Current search string

---

#### 2. GET /Students/Details/{id}

**Action:** `StudentsController.Details(id)`  
**Purpose:** Display student details with enrollments

**Route Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| id | int | Student ID |

**Response:**
- **View:** `Details.cshtml`
- **Model:** Student with Enrollments and Courses (eager loaded)

**Error Responses:**
- 400 Bad Request - If id is null
- 404 Not Found - If student doesn't exist

---

#### 3. GET /Students/Create

**Action:** `StudentsController.Create()`  
**Purpose:** Display student creation form

**Response:**
- **View:** `Create.cshtml`
- **Model:** New Student with default EnrollmentDate = Today

---

#### 4. POST /Students/Create

**Action:** `StudentsController.Create([Bind] Student)`  
**Purpose:** Create new student

**Form Data:**
| Field | Type | Required | Validation |
|-------|------|----------|------------|
| LastName | String | Yes | Max 50 chars |
| FirstMidName | String | Yes | 1-50 chars |
| EnrollmentDate | DateTime | Yes | 1753-9999 range |

**Success Response:**
- Redirect to `/Students` (Index)
- Notification sent

**Error Response:**
- Re-display Create view with validation errors
- ModelState errors populated

**Validation:**
- Anti-forgery token required
- SQL Server datetime range enforced (1753-9999)
- EnrollmentDate cannot be default/minimum value

---

#### 5. GET /Students/Edit/{id}

**Action:** `StudentsController.Edit(id)`  
**Purpose:** Display edit form for student

**Route Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| id | int | Student ID |

**Response:**
- **View:** `Edit.cshtml`
- **Model:** Student to edit

---

#### 6. POST /Students/Edit/{id}

**Action:** `StudentsController.Edit([Bind] Student)`  
**Purpose:** Update existing student

**Form Data:** Same as Create

**Success Response:**
- Redirect to `/Students` (Index)
- Notification sent

**Error Response:**
- Re-display Edit view with validation errors

---

#### 7. GET /Students/Delete/{id}

**Action:** `StudentsController.Delete(id)`  
**Purpose:** Display delete confirmation

**Response:**
- **View:** `Delete.cshtml`
- **Model:** Student to delete

---

#### 8. POST /Students/Delete/{id}

**Action:** `StudentsController.DeleteConfirmed(id)`  
**Purpose:** Delete student

**Success Response:**
- Redirect to `/Students` (Index)
- Notification sent

**Error Response:**
- Redirect to Index with error in TempData

---

### Courses, Instructors, Departments Controllers

Similar route patterns:
- `/Courses` - Course management
- `/Instructors` - Instructor management with course assignments
- `/Departments` - Department management with concurrency control

**Actions:** Index, Details, Create (GET/POST), Edit (GET/POST), Delete (GET/POST)

---

### Home Controller Routes

#### GET / or /Home/Index

**Action:** `HomeController.Index()`  
**Purpose:** Home page

---

#### GET /Home/About

**Action:** `HomeController.About()`  
**Purpose:** Display enrollment statistics grouped by date

**Response:**
- **View:** `About.cshtml`
- **Model:** `List<EnrollmentDateGroup>` with enrollment counts

---

## Common Patterns

### Request/Response Cycle

**Java (Spring Boot):**
1. HTTP request → DispatcherServlet
2. Controller method invoked
3. Service layer processes business logic
4. Repository layer accesses database
5. Response returned (JSON or view name)

**C# (ASP.NET MVC):**
1. HTTP request → MVC routing engine
2. Controller action invoked
3. Business logic in controller
4. DbContext accesses database
5. View rendered or redirect issued

---

### Error Handling

**Java (Spring Boot):**
- `@ExceptionHandler` methods in controllers
- Global exception handlers with `@ControllerAdvice`
- ResponseEntity<T> with HTTP status codes
- EntityNotFoundException → 404 Not Found

**C# (ASP.NET MVC):**
- ModelState validation errors
- TempData for error messages across redirects
- HTTP status code results (HttpNotFound, HttpBadRequest)
- Try-catch with error logging (Trace.TraceError)

---

### Validation

**Java:**
- Bean Validation annotations (@NotBlank, @Size, etc.)
- `@Valid` or `@Validated` on controller parameters
- Automatic validation before method invocation

**C#:**
- Data Annotations ([Required], [StringLength], etc.)
- ModelState.IsValid check in POST actions
- Manual validation in controller

---

### Content Negotiation

**Java (Spring Boot):**
- `@RestController` → JSON responses
- `@Controller` → View names (HTML)
- Accept header determines response format

**C# (ASP.NET MVC):**
- Controllers return ActionResult
- View() → Razor view (HTML)
- JsonResult for JSON responses

---

## Testing APIs

### Using cURL

**GET Request:**
```bash
curl -X GET http://localhost:8080/api/todos
```

**POST Request:**
```bash
curl -X POST http://localhost:8080/api/todos \
  -H "Content-Type: application/json" \
  -d '{"title":"Test todo","completed":false}'
```

**PUT Request:**
```bash
curl -X PUT http://localhost:8080/api/todos/1 \
  -H "Content-Type: application/json" \
  -d '{"title":"Updated","completed":true}'
```

**DELETE Request:**
```bash
curl -X DELETE http://localhost:8080/api/todos/1
```

---

### Using Postman

1. Import endpoints as collection
2. Set base URL variables
3. Configure headers (Content-Type: application/json)
4. Add request bodies for POST/PUT
5. Test response validation

---

## API Evolution Best Practices

1. **Versioning:** Add `/v1`, `/v2` to API paths
2. **Deprecation:** Use @Deprecated with migration guidance
3. **Backward Compatibility:** Additive changes only
4. **Documentation:** Keep this doc updated with changes
5. **Testing:** Maintain comprehensive API tests

---

**Related Documentation:**
- [Program Structure](program-structure.md) - Controller implementations
- [Interfaces](interfaces.md) - Service contracts
- [Data Models](data-models.md) - Request/response entity definitions
- [Business Logic](../behavior/business-logic.md) - API behavior and workflows
