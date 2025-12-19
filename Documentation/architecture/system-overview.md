# System Overview - Architecture Summary

**Analysis Date:** December 2024  
**Total Projects:** 8  
**Architecture Patterns:** MVC, Microservices, Monolithic

---

## Project Architectures

### asset-manager: Multi-Module Microservices
**Architecture:** Microservices with message-driven communication
**Components:**
- Web Module: REST API for file management
- Worker Module: Background image processing
- PostgreSQL: Metadata storage
- RabbitMQ: Message queue
- AWS S3: Object storage

**Pattern:** Event-driven, asynchronous processing

### todo-web-api: REST API Monolith
**Architecture:** Single-module REST API
**Components:**
- Spring Boot application
- Oracle Database
- REST endpoints

**Pattern:** Standard 3-tier (Controller → Service → Repository)

### ContosoUniversity: MVC Web Application
**Architecture:** Traditional ASP.NET MVC monolith
**Components:**
- ASP.NET MVC 5 controllers
- Entity Framework data access
- SQL Server database
- Razor views

**Pattern:** MVC with direct data access

### mi-sql-public-demo: Console Application
**Architecture:** Simple JDBC application
**Components:**
- Single MainSQL class
- Azure Managed Identity
- SQL Server

**Pattern:** Direct database access

### jakarta-ee: Hybrid Web Application  
**Architecture:** Mixed Jakarta EE + Spring MVC (anti-pattern)
**Components:**
- Jakarta EE servlets
- Spring MVC controllers
- MyBatis SQL mapping
- Open Liberty server

**Pattern:** Hybrid (architectural debt)

### Malshinon: Factory-Based Processor
**Architecture:** Factory pattern data processor
**Components:**
- Factory for processor creation
- DAL for data access
- CSV processing

**Pattern:** Factory + DAL abstraction

---

**Related:** [Components](components.md), [Patterns](patterns.md), [System Context](../diagrams/architecture/system-context.md)
