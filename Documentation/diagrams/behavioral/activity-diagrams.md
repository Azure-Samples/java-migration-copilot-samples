# Activity Diagrams - Business Process Flows

**Analysis Date:** December 2024  
**Format:** Text-based activity flows

---

## asset-manager: File Upload Activity

```
[Start] User initiates upload
   |
   v
[Choose File] Select file from filesystem
   |
   v
[Submit Form] POST to /s3/upload
   |
   v
<File Empty?> ──Yes──> [Show Error] "Please select a file"
   |                         |
   No                        v
   |                    [End - Failure]
   v
[Upload to S3] Store file with generated key
   |
   v
[Save Metadata] Insert into PostgreSQL (ImageMetadata)
   |
   v
<AWS Profile?> ──Yes──> [Publish Message] Send to RabbitMQ
   |                         |
   No                        v
   |                    [Worker Processes]
   v                         |
[Success Message]            |
   |                         v
   v                    [Generate Thumbnail]
[Redirect to List]           |
   |                         v
   v                    [Upload Thumbnail]
[End - Success]              |
                             v
                        [Update Metadata]
                             |
                             v
                        [End - Processing Complete]
```

---

## ContosoUniversity: Student Enrollment Activity

```
[Start] Navigate to /Students/Create
   |
   v
[Display Form] Show student creation form
   |           (default EnrollmentDate = Today)
   v
[Enter Data] User fills: Name, EnrollmentDate
   |
   v
[Submit Form] POST to /Students/Create
   |
   v
<Validate Name> ──Invalid──> [Show Validation Error]
   |                               |
   Valid                           v
   |                          [Re-display Form]
   v                               |
<Validate Date Range?>             v
(1753-9999)                   [End - Retry]
   |
   No (out of range)
   |
   v
[Show Date Error] "Must be between 1753 and 9999"
   |
   v
[Re-display Form]
   |
   v
[End - Retry]

<Validate Date Range?>
   |
   Yes (valid)
   |
   v
[Save to Database] INSERT INTO Student
   |
   v
<Save Success?> ──No──> [Log Error] Trace.TraceError
   |                         |
   Yes                       v
   |                    [Show Generic Error]
   v                         |
[Send Notification]          v
(CREATE operation)      [End - Failure]
   |
   v
[Redirect] To /Students
   |
   v
[End - Success]
```

---

## todo-web-api: Todo Update Activity

```
[Start] PUT /api/todos/{id}
   |
   v
[Receive JSON] Parse TodoItem data
   |
   v
<Find Todo by ID> ──Not Found──> [Return 404]
   |                                   |
   Found                               v
   |                              [End - Not Found]
   v
<Validate Data> ──Invalid──> [Return 400] Validation errors
   |                              |
   Valid                          v
   |                         [End - Invalid]
   v
[Update Fields] Replace all fields
   |
   v
[Set updatedAt] LocalDateTime.now()
   |
   v
[Save to Oracle] UPDATE TODO_ITEMS
   |
   v
<Save Success?> ──No──> [Return 500] Database error
   |                         |
   Yes                       v
   |                    [End - Error]
   v
[Return 200 OK] Updated TodoItem JSON
   |
   v
[End - Success]
```

---

**Related Documentation:**
- [Workflows](../../behavior/workflows.md)
- [Sequence Diagrams](sequence-diagrams.md)
- [Business Logic](../../behavior/business-logic.md)
