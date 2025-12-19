# Dependencies - External and Internal

**Analysis Date:** December 2024  
**Total Projects:** 8 (6 Java, 2 .NET)  
**Analysis Method:** Static analysis of build configuration files

---

## Table of Contents
- [Overview](#overview)
- [Java Project Dependencies](#java-project-dependencies)
- [.NET Project Dependencies](#net-project-dependencies)
- [Internal Dependencies](#internal-dependencies)
- [Dependency Version Matrix](#dependency-version-matrix)
- [Critical Dependencies](#critical-dependencies)

---

## Overview

This document catalogs all external library dependencies and internal component dependencies across the repository. Dependencies are analyzed from:
- Maven POM files (pom.xml)
- Ant build files (build.xml)
- .NET project files (.csproj, packages.config)

---

## Java Project Dependencies

### 1. mi-sql-public-demo

**Build System:** Maven  
**Parent:** N/A (standalone)

#### Core Dependencies
| Dependency | Version | Scope | Purpose |
|------------|---------|-------|---------|
| mssql-jdbc | 10.2.0 | runtime | SQL Server JDBC driver |
| azure-identity | Latest | compile | Azure Managed Identity authentication |

**Key Features:**
- Azure SDK for Managed Identity
- SQL Server connectivity

**Dependency Count:** ~5 (including transitive)

---

### 2. asset-manager (Multi-Module)

**Build System:** Maven  
**Parent POM:** Spring Boot 2.7.18

#### Parent Module

**Coordinates:**
- GroupId: `com.microsoft.migration`
- ArtifactId: `assets-manager-parent`
- Version: `0.0.1-SNAPSHOT`

**Modules:**
- web
- worker

**Java Version:** 8

---

#### Web Module Dependencies

**ArtifactId:** `assets-manager-web`

| Dependency | Group | Version | Scope | Purpose |
|------------|-------|---------|-------|---------|
| spring-boot-starter-thymeleaf | org.springframework.boot | 2.7.18* | compile | HTML templating engine |
| spring-boot-starter-web | org.springframework.boot | 2.7.18* | compile | Spring MVC, embedded Tomcat |
| spring-boot-starter-amqp | org.springframework.boot | 2.7.18* | compile | RabbitMQ messaging |
| s3 | software.amazon.awssdk | 2.25.13 | compile | AWS S3 SDK v2 |
| spring-boot-starter-data-jpa | org.springframework.boot | 2.7.18* | compile | JPA/Hibernate ORM |
| postgresql | org.postgresql | Latest | runtime | PostgreSQL JDBC driver |
| lombok | org.projectlombok | Latest | compile (optional) | Boilerplate code reduction |
| spring-boot-devtools | org.springframework.boot | 2.7.18* | runtime (optional) | Development tools |
| spring-boot-starter-test | org.springframework.boot | 2.7.18* | test | Testing framework |

*Inherited from parent Spring Boot version

**Transitive Dependencies (Major):**
- spring-webmvc
- spring-web
- tomcat-embed-core
- jackson-databind (JSON)
- hibernate-core
- spring-rabbit (AMQP)
- aws-core, aws-http-client

**Total Dependencies:** ~80 (including transitive)

---

#### Worker Module Dependencies

**ArtifactId:** `assets-manager-worker`

| Dependency | Group | Version | Scope | Purpose |
|------------|-------|---------|-------|---------|
| spring-boot-starter-amqp | org.springframework.boot | 2.7.18* | compile | RabbitMQ message consumption |
| s3 | software.amazon.awssdk | 2.25.13 | compile | AWS S3 SDK v2 |
| spring-boot-starter-data-jpa | org.springframework.boot | 2.7.18* | compile | JPA for metadata |
| postgresql | org.postgresql | Latest | runtime | PostgreSQL JDBC driver |
| lombok | org.projectlombok | Latest | compile (optional) | Boilerplate code reduction |
| spring-boot-starter-test | org.springframework.boot | 2.7.18* | test | Testing framework |

**Key Differences from Web:**
- No web/Thymeleaf dependencies (headless worker)
- Includes image processing libraries (inferred)

---

### 3. todo-web-api-use-oracle-db

**Build System:** Maven  
**Parent:** Spring Boot 3.2.4  
**Java Version:** 17

| Dependency | Group | Version | Scope | Purpose |
|------------|-------|---------|-------|---------|
| spring-boot-starter-web | org.springframework.boot | 3.2.4* | compile | Spring MVC REST API |
| spring-boot-starter-data-jpa | org.springframework.boot | 3.2.4* | compile | JPA/Hibernate ORM |
| ojdbc11 | com.oracle.database.jdbc | Latest | runtime | Oracle JDBC driver (Java 11+) |
| spring-boot-starter-validation | org.springframework.boot | 3.2.4* | compile | Bean Validation |
| lombok | org.projectlombok | Latest | compile (optional) | Boilerplate code reduction |
| spring-boot-devtools | org.springframework.boot | 3.2.4* | runtime (optional) | Development tools |
| spring-boot-starter-test | org.springframework.boot | 3.2.4* | test | Testing framework |

**Oracle-Specific:**
- ojdbc11 for Java 11+ compatibility
- Supports Oracle-specific features (VARCHAR2, sequences)

**Total Dependencies:** ~70 (including transitive)

---

### 4. rabbitmq-sender

**Build System:** Maven  
**Parent:** Spring Boot

| Dependency | Group | Purpose |
|------------|-------|---------|
| spring-boot-starter-amqp | org.springframework.boot | RabbitMQ messaging |
| spring-boot-starter | org.springframework.boot | Core Spring Boot |

**Purpose:** Minimal RabbitMQ producer demonstration

---

### 5. jakarta-ee/student-web-app

**Build System:** Apache Ant  
**Server:** Open Liberty  
**Java Version:** 11

#### Build Dependencies (from build.xml)
- Jakarta EE APIs (Servlets, JSP)
- Spring Framework JARs (for hybrid architecture)
- MyBatis SQL mapper
- Open Liberty runtime libraries

**Note:** Ant-based projects manage dependencies via manual JAR inclusion in lib/ directories rather than dependency management tools.

**Architectural Debt:** Mixing Jakarta EE and Spring frameworks creates complex dependency management

---

## .NET Project Dependencies

### 6. ContosoUniversity

**Framework:** .NET Framework 4.8  
**Package Manager:** NuGet  
**Configuration:** packages.config

#### Core Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| Microsoft.AspNet.Mvc | 5.2.9 | ASP.NET MVC framework |
| Microsoft.EntityFrameworkCore | 3.1.32 | ORM (EF Core on .NET Framework) |
| Microsoft.EntityFrameworkCore.SqlServer | 3.1.32 | SQL Server provider for EF Core |
| Microsoft.Data.SqlClient | 2.1.4 | SQL Server client library |
| bootstrap | 5.3.3 | UI framework |
| jQuery | 3.7.1 | JavaScript library |
| Newtonsoft.Json | 13.0.3 | JSON serialization |

#### Entity Framework Packages

| Package | Version | Purpose |
|---------|---------|---------|
| Microsoft.EntityFrameworkCore | 3.1.32 | Core EF functionality |
| Microsoft.EntityFrameworkCore.Abstractions | 3.1.32 | EF abstractions |
| Microsoft.EntityFrameworkCore.Analyzers | 3.1.32 | Code analyzers |
| Microsoft.EntityFrameworkCore.Relational | 3.1.32 | Relational database support |
| Microsoft.EntityFrameworkCore.SqlServer | 3.1.32 | SQL Server specific |
| Microsoft.EntityFrameworkCore.Tools | 3.1.32 | Migration tools |

#### Microsoft Extensions (Dependency Injection, Configuration, Logging)

| Package | Version | Purpose |
|---------|---------|---------|
| Microsoft.Extensions.Caching.Memory | 3.1.32 | In-memory caching |
| Microsoft.Extensions.Configuration | 3.1.32 | Configuration framework |
| Microsoft.Extensions.DependencyInjection | 3.1.32 | DI container |
| Microsoft.Extensions.Logging | 3.1.32 | Logging abstractions |
| Microsoft.Extensions.Options | 3.1.32 | Options pattern |

#### UI and Web Optimization

| Package | Version | Purpose |
|---------|---------|---------|
| bootstrap | 5.3.3 | Responsive UI framework |
| jQuery | 3.7.1 | DOM manipulation |
| jQuery.Validation | 1.21.0 | Client-side validation |
| Microsoft.jQuery.Unobtrusive.Validation | 4.0.0 | Unobtrusive validation |
| Microsoft.AspNet.Web.Optimization | 1.1.3 | Bundling and minification |
| WebGrease | 1.5.2 | CSS/JS optimization |

#### Supporting Libraries

| Package | Version | Purpose |
|---------|---------|---------|
| System.Collections.Immutable | 1.7.1 | Immutable collections |
| System.ComponentModel.Annotations | 4.7.0 | Data annotations |
| System.Diagnostics.DiagnosticSource | 4.7.1 | Diagnostic tracing |
| Microsoft.Identity.Client | 4.21.1 | Azure AD authentication (if used) |

**Total NuGet Packages:** 47

**Version Note:** EF Core 3.1.32 is the last version supporting .NET Framework (EF Core 5+ requires .NET 5+)

---

### 7. Malshinon

**Framework:** .NET Framework 4.8

#### Dependencies (Inferred)
- System.Data (ADO.NET for data access)
- System.IO (File operations)
- Custom DAL libraries

**Package Count:** Minimal (standard .NET Framework libraries)

---

## Internal Dependencies

### asset-manager Multi-Module Structure

```
assets-manager-parent (POM)
├── web (module)
│   └── Depends on parent for Spring Boot version
└── worker (module)
    └── Depends on parent for Spring Boot version
```

**Shared Configuration:**
- Spring Boot version: 2.7.18 (inherited)
- Java version: 8 (inherited)
- AWS SDK version: 2.25.13 (managed)

**Module Independence:**
- Web and worker are separate deployable units
- Share data model classes (duplicated for independence)
- Communicate via RabbitMQ (loose coupling)
- Share PostgreSQL database

---

### Component-Level Dependencies

#### asset-manager Web Internal Dependencies

```
Controllers (Presentation)
└── Depends on Services

Services (Business Logic)
├── Depends on Repositories
├── Depends on AWS S3Client
└── Depends on RabbitTemplate

Repositories (Data Access)
└── Depends on JPA/Hibernate
```

**Dependency Injection Pattern:** Constructor injection (via @RequiredArgsConstructor)

---

#### asset-manager Worker Internal Dependencies

```
Message Listeners
└── Depends on FileProcessor Services

FileProcessor Services
├── Depends on S3Client
└── Depends on Repositories

Repositories
└── Depends on JPA/Hibernate
```

---

#### ContosoUniversity Internal Dependencies

```
Controllers
├── Depends on DbContext (data access)
└── Depends on INotificationService

DbContext
└── Depends on Entity Framework

Entities (Domain Models)
└── No dependencies (POCOs)
```

**Pattern:** Direct DbContext usage in controllers (no repository abstraction layer)

---

## Dependency Version Matrix

### Spring Boot Versions

| Project | Spring Boot | Status | End of Support |
|---------|-------------|--------|----------------|
| asset-manager | 2.7.18 | ⚠️ EOL | November 2023 |
| todo-web-api | 3.2.4 | ✅ Current | May 2025 |
| rabbitmq-sender | (unspecified) | ❓ Unknown | - |

---

### Java Versions

| Project | Java | Status | Recommendation |
|---------|------|--------|----------------|
| asset-manager | 8 | 🔴 Outdated | Upgrade to 17 or 21 |
| todo-web-api | 17 | ✅ LTS | Consider 21 LTS |
| mi-sql-public-demo | 17 | ✅ LTS | Current |
| jakarta-ee | 11 | ⚠️ Aging | Upgrade to 17 or 21 |

---

### Database Drivers

| Project | Driver | Version | Status |
|---------|--------|---------|--------|
| asset-manager | postgresql | Latest | ✅ Good |
| todo-web-api | ojdbc11 | Latest | ✅ Good |
| mi-sql-public-demo | mssql-jdbc | 10.2.0 | ⚠️ Not latest |
| ContosoUniversity | Microsoft.Data.SqlClient | 2.1.4 | ⚠️ Not latest |

---

### AWS SDK Versions

| Project | SDK | Version | Status |
|---------|-----|---------|--------|
| asset-manager | AWS SDK v2 | 2.25.13 | ⚠️ Check for updates |

---

### .NET Versions

| Project | Framework | Status | Recommendation |
|---------|-----------|--------|----------------|
| ContosoUniversity | .NET Framework 4.8 | 🔴 Legacy | Migrate to .NET 6/8 |
| Malshinon | .NET Framework 4.8 | 🔴 Legacy | Migrate to .NET 6/8 |

---

### Entity Framework Versions

| Project | Version | Status | Notes |
|---------|---------|--------|-------|
| ContosoUniversity | EF Core 3.1.32 | ⚠️ Last version for .NET Framework | Requires .NET 5+ for EF Core 5+ |

---

## Critical Dependencies

### High Priority Updates

1. **Spring Boot 2.7.18 (asset-manager)**
   - **Risk:** Security vulnerabilities, no support
   - **Action:** Upgrade to Spring Boot 3.x
   - **Impact:** Requires Java 17+, Jakarta namespace changes

2. **Java 8 (asset-manager)**
   - **Risk:** Security vulnerabilities, missing features
   - **Action:** Upgrade to Java 17 LTS or 21 LTS
   - **Impact:** Coordinate with Spring Boot 3 upgrade

3. **.NET Framework 4.8 (ContosoUniversity, Malshinon)**
   - **Risk:** Windows-only, no new features, maintenance mode
   - **Action:** Migrate to .NET 6 or .NET 8
   - **Impact:** Cross-platform support, modern C# features

---

### Dependency Management Best Practices

**Java (Maven):**
- Use `<dependencyManagement>` for version control
- Leverage Spring Boot's dependency management
- Pin critical versions explicitly
- Use dependency scanning (OWASP, Snyk)

**.NET (NuGet):**
- Keep packages.config or PackageReference updated
- Use central package management
- Enable security vulnerability scanning
- Consider migrating to .NET 6/8 for better dependency management

---

## Dependency Graphs

See: [Dependency Graphs](../diagrams/structural/dependency-graphs.md) for visual representations

---

## Vulnerability Scanning

**Recommended Tools:**
- **Java:** OWASP Dependency-Check, Snyk, GitHub Dependabot
- **.NET:** NuGet vulnerability scanning, OWASP Dependency-Check, WhiteSource

**Critical:** Run dependency scans regularly to identify vulnerable libraries

---

## Transitive Dependencies

**Note:** Transitive dependencies (dependencies of dependencies) can introduce vulnerabilities. Use dependency tree analysis:

**Maven:**
```bash
mvn dependency:tree
```

**.NET:**
```bash
dotnet list package --include-transitive
```

---

**Related Documentation:**
- [Dependency Analysis](../analysis/dependency-analysis.md) - Detailed criticality ratings
- [Technical Debt - Outdated Components](../technical-debt/outdated-components.md) - Upgrade priorities
- [Security Vulnerabilities](../technical-debt/security-vulnerabilities.md) - Security issues in dependencies
- [Dependency Graphs](../diagrams/structural/dependency-graphs.md) - Visual dependency mapping
