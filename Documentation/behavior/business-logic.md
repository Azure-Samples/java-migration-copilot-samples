# Business Logic - Domain Rules and Operations

**Analysis Date:** December 2024  
**Method:** Static code analysis of controllers, services, and business logic layers

---

## Overview

This document extracts and catalogs business rules, domain logic, validation patterns, and operational workflows implemented in the codebase.

---

## Project Business Logic Summary

### asset-manager
**Domain:** Image/file management with cloud storage and async processing

**Key Business Rules:**
- File uploads require non-empty files
- Metadata captured: filename, size, content type, timestamp
- Async thumbnail generation via RabbitMQ worker
- Profile-based storage selection (AWS S3 or local)

### todo-web-api  
**Domain:** Task management with Oracle Database

**Key Business Rules:**
- Title required (max 200 chars)
- Description optional (max 4000 chars)
- Default values: completed=false, priority=0
- Automatic timestamps on create/update
- Oracle-specific VARCHAR2 usage

### ContosoUniversity
**Domain:** University management system

**Key Business Rules:**
- Student enrollment date: 1753-9999 (SQL Server datetime2 range)
- Course credits: 0-5 range
- Department concurrency control via RowVersion
- Cascade delete on student enrollments
- Entity change notifications (CREATE/UPDATE/DELETE)

### mi-sql-public-demo
**Domain:** Azure Managed Identity authentication

**Key Business Rules:**
- Credential-less SQL Server authentication
- Azure Managed Identity token-based access

### jakarta-ee/student-web-app
**Domain:** Student profile management

**Key Business Rules:**
- Hybrid servlet/Spring MVC architecture
- MyBatis SQL mapping
- Required fields: name, email, enrollment date, major

### Malshinon
**Domain:** Data processing with factory pattern

**Key Business Rules:**
- Type-based processor creation (CSV, Excel, JSON)
- Factory pattern for extensibility
- DAL abstraction for data access

---

**Related Documentation:**
- [Workflows](workflows.md) - Process flows
- [Decision Logic](decision-logic.md) - Conditional logic
- [Error Handling](error-handling.md) - Exception handling
- [Program Structure](../reference/program-structure.md) - Implementation details
