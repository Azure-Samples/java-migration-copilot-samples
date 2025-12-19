# Error Handling - Exception Patterns

**Analysis Date:** December 2024

## Exception Handling Strategies

### Java (Spring Boot)
- Try-catch blocks in controllers
- Service layer throws business exceptions
- EntityNotFoundException → 404 Not Found
- ValidationException → 400 Bad Request
- IOException → 500 Internal Server Error

### C# (ASP.NET MVC)
- Try-catch with Trace.TraceError logging
- ModelState for validation errors
- TempData for error messages across redirects
- Generic error messages for security

## Project-Specific Error Handling

### asset-manager
- File upload errors: Redirect with flash attributes
- S3 errors: Logged and user-friendly message
- RabbitMQ errors: Logged, no user impact

### todo-web-api
- EntityNotFoundException for missing todos
- Bean validation errors returned as JSON
- Database errors logged and returned as 500

### ContosoUniversity
- Database errors: Trace.TraceError + generic message
- Concurrency conflicts: RowVersion mismatch detection
- Validation errors: ModelState + re-display form

**Related:** [Business Logic](business-logic.md), [Decision Logic](decision-logic.md)
