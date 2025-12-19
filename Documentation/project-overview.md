# Project Overview

## Repository Summary
**Repository:** java-migration-copilot-samples  
**Purpose:** Multi-project sample repository demonstrating Java and .NET migration patterns  
**Total Source Files:** 87 (45 Java files, 42 C# files)  
**Analysis Date:** December 2024  
**Analysis Type:** Static Code Analysis Only (No Build/Execution)

---

## Projects Inventory

### Java Projects (6 Projects, 45 Source Files)

#### 1. mi-sql-public-demo
- **Language:** Java 17
- **Build System:** Maven
- **Purpose:** Demonstrates Azure Managed Identity authentication with SQL Server
- **Key Technologies:**
  - JDBC for SQL Server connectivity
  - Azure Managed Identity for authentication
  - SQL Server database
- **Source Files:** Minimal console application

#### 2. asset-manager (Multi-Module Spring Boot)
- **Language:** Java 8
- **Framework:** Spring Boot 2.7.18
- **Build System:** Maven (multi-module)
- **Architecture:** Microservices with web and worker modules
- **Modules:**
  - **web:** REST API for file/image management
  - **worker:** Background processing for image operations
- **Key Technologies:**
  - AWS SDK 2.25.13
  - AWS S3 for object storage
  - Spring Boot Web
  - Spring Boot AMQP (RabbitMQ integration)
  - PostgreSQL database
  - Message-driven architecture
- **Source Files:** ~15-20 Java classes across both modules

#### 3. todo-web-api-use-oracle-db
- **Language:** Java 17
- **Framework:** Spring Boot 3.2.4
- **Build System:** Maven
- **Purpose:** RESTful API for Todo management with Oracle Database
- **Key Technologies:**
  - Spring Boot Web
  - Spring Data JPA / Hibernate
  - Oracle JDBC driver (ojdbc11)
  - Oracle-specific SQL features (VARCHAR2)
  - Bean Validation
  - Lombok
- **Source Files:** ~8-10 Java classes

#### 4. rabbitmq-sender
- **Language:** Java
- **Framework:** Spring Boot
- **Build System:** Maven
- **Purpose:** Message producer demonstrating RabbitMQ integration
- **Key Technologies:**
  - Spring Boot AMQP
  - RabbitMQ messaging
  - AMQP protocol
- **Source Files:** ~3-5 Java classes

#### 5. jakarta-ee/student-web-app
- **Language:** Java 11
- **Framework:** Hybrid Jakarta EE / Spring MVC
- **Build System:** Apache Ant
- **Server:** Open Liberty
- **Purpose:** Student profile management web application
- **Key Technologies:**
  - Jakarta Servlets
  - Spring MVC (hybrid architecture)
  - MyBatis for SQL mapping
  - JSP for views
  - Open Liberty runtime
- **Source Files:** ~10-12 Java classes
- **Note:** Uses legacy Ant build system

### .NET Projects (2 Projects, 42 Source Files)

#### 6. ContosoUniversity
- **Language:** C#
- **Framework:** .NET Framework 4.8
- **Architecture:** ASP.NET MVC
- **Purpose:** University management system (students, courses, instructors, departments)
- **Key Technologies:**
  - ASP.NET MVC 5
  - Entity Framework 6
  - SQL Server database
  - Azure Blob Storage (migration target)
  - File upload functionality
- **Source Files:** ~30-35 C# classes
- **Controllers:** 7 controllers (Students, Courses, Instructors, Departments, Notifications, Home, Base)
- **Models:** Student, Course, Instructor, Enrollment, Department, OfficeAssignment
- **Data Layer:** SchoolContext (DbContext), DbInitializer, SchoolContextFactory

#### 7. Malshinon
- **Language:** C#
- **Framework:** .NET Framework 4.8
- **Build System:** MSBuild
- **Purpose:** Data processing application with factory pattern
- **Key Technologies:**
  - CSV file processing
  - Factory design pattern
  - Data Access Layer (DAL)
  - Custom business logic
- **Source Files:** ~7-10 C# classes

---

## Technology Stack Summary

### Programming Languages
| Language | Version(s) | File Count | Projects |
|----------|-----------|------------|----------|
| Java | 8, 11, 17 | 45 | 6 |
| C# | .NET Framework 4.8 | 42 | 2 |

### Frameworks
| Framework | Version | Projects |
|-----------|---------|----------|
| Spring Boot | 2.7.18, 3.2.4 | 4 (asset-manager, todo-web-api, rabbitmq-sender, plus student-web-app hybrid) |
| Jakarta EE | N/A | 1 (jakarta-ee/student-web-app) |
| ASP.NET MVC | 5 | 1 (ContosoUniversity) |
| .NET Framework | 4.8 | 2 (ContosoUniversity, Malshinon) |

### Build Systems
| Build System | Projects |
|--------------|----------|
| Maven | 5 Java projects |
| Apache Ant | 1 Java project (jakarta-ee) |
| MSBuild | 2 .NET projects |

### Databases
| Database | Projects | Purpose |
|----------|----------|---------|
| SQL Server | mi-sql-public-demo, ContosoUniversity | Primary relational database |
| Oracle Database | todo-web-api-use-oracle-db | Todo item storage with Oracle-specific features |
| PostgreSQL | asset-manager | Metadata storage for images/files |

### Cloud Services
| Service | Provider | Projects | Usage |
|---------|----------|----------|-------|
| S3 | AWS | asset-manager | Object storage for images/files |
| Managed Identity | Azure | mi-sql-public-demo | SQL Server authentication |
| Blob Storage | Azure | ContosoUniversity | File upload migration target |

### Messaging
| Technology | Projects | Purpose |
|------------|----------|---------|
| RabbitMQ | asset-manager, rabbitmq-sender | Async message processing between web and worker |

### Key Libraries
- **AWS SDK:** 2.25.13 (asset-manager)
- **Entity Framework:** 6.x (ContosoUniversity)
- **Spring Data JPA:** 3.2.4 (todo-web-api)
- **MyBatis:** (jakarta-ee/student-web-app)
- **Lombok:** (todo-web-api)

---

## Project Characteristics

### Architecture Patterns
- **Microservices:** asset-manager (web/worker separation)
- **Monolithic Web Applications:** ContosoUniversity, jakarta-ee/student-web-app, todo-web-api
- **Message-Driven:** asset-manager with RabbitMQ
- **MVC Pattern:** All web applications
- **Layered Architecture:** Controllers → Services → Repositories/DAL → Database
- **Factory Pattern:** Malshinon

### Integration Patterns
- RESTful APIs (Spring Boot web applications)
- Message queuing (RabbitMQ/AMQP)
- Database connectivity (JDBC, Entity Framework, JPA, MyBatis)
- Cloud storage (AWS S3, Azure Blob)
- Managed Identity authentication (Azure)

### Key Technical Characteristics
1. **Multi-Language Environment:** Java and C# codebases
2. **Framework Diversity:** Spring Boot, Jakarta EE, ASP.NET MVC
3. **Database Diversity:** SQL Server, Oracle, PostgreSQL
4. **Cloud Migration Focus:** AWS and Azure integrations
5. **Legacy Components:** .NET Framework 4.8, Java 8, Ant build system
6. **Modern Components:** Spring Boot 3.x, Java 17

---

## Repository Structure

```
java-migration-copilot-samples/
├── asset-manager/                 # Spring Boot multi-module (web + worker)
│   ├── web/                       # REST API for file management
│   ├── worker/                    # Background image processing
│   └── pom.xml                    # Parent POM
├── ContosoUniversity/             # .NET MVC university system
│   ├── Controllers/               # 7 MVC controllers
│   ├── Models/                    # Domain entities
│   ├── Data/                      # EF DbContext
│   └── Views/                     # Razor views
├── Malshinon/                     # .NET data processing app
│   ├── factory/                   # Factory pattern implementation
│   └── DAL/                       # Data access layer
├── jakarta-ee/                    # Jakarta EE hybrid app
│   └── student-web-app/           # Student profile management
├── mi-sql-public-demo/            # Managed Identity demo
├── rabbitmq-sender/               # RabbitMQ producer
└── todo-web-api-use-oracle-db/    # Spring Boot 3 + Oracle
```

---

## Documentation Purpose

This comprehensive documentation ecosystem serves multiple purposes:

1. **Understanding:** Complete system comprehension for developers and architects
2. **Migration:** Detailed specifications for technology upgrades and platform migrations
3. **Maintenance:** Technical debt identification and remediation guidance
4. **Reimplementation:** Sufficient detail for accurate code reconstruction
5. **Knowledge Transfer:** Business logic and domain knowledge extraction
6. **Quality Assessment:** Code metrics, complexity analysis, and architectural evaluation

---

## Navigation Guide

- **Architecture Documentation:** [architecture/](architecture/) - System design, components, patterns
- **Reference Documentation:** [reference/](reference/) - Program structure, APIs, data models
- **Behavioral Documentation:** [behavior/](behavior/) - Business logic, workflows, decisions
- **Technical Debt Report:** [technical-debt-report.md](technical-debt-report.md) - Critical issues and remediation
- **Analysis Documentation:** [analysis/](analysis/) - Metrics, complexity, security, dependencies
- **Visual Diagrams:** [diagrams/](diagrams/) - Text-based structural and behavioral diagrams
- **Migration Planning:** [migration/](migration/) - Component order, test specs, validation
- **Technology-Specific Docs:** [specialized/](specialized/) - Spring Boot, databases, messaging, cloud

---

## Analysis Methodology

**Approach:** Static Code Analysis Only  
**No Build Required:** Documentation generated without compilation or execution  
**Coverage Target:** 90%+ of codebase documented  
**Tools Used:** AST parsing, dependency analysis, pattern recognition  
**Validation:** Cross-referenced documentation with source traceability

---

**Next Steps:** Explore specific documentation sections based on your role and needs.
