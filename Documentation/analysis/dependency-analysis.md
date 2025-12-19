# Dependency Analysis - Criticality and Risk Assessment

**Analysis Date:** December 2024  
**Method:** Static analysis of dependency configurations and component relationships

---

## Executive Summary

This analysis evaluates all external and internal dependencies for criticality, risk, and migration impact. Findings prioritize modernization efforts and identify high-risk components.

---

## Criticality Ratings

### CRITICAL Dependencies (Immediate Action Required)

#### 1. Spring Boot 2.7.18 (asset-manager)
- **Risk Level:** CRITICAL
- **Issue:** End of OSS support (November 2023)
- **Impact:** Security vulnerabilities, no bug fixes
- **Dependent Components:** Web module, Worker module
- **Migration Path:** Spring Boot 2.7.18 → 3.2.x (requires Java 17+)
- **Effort:** HIGH (Jakarta EE namespace migration)
- **Blocking:** Java 8 upgrade must happen first

#### 2. Java 8 Runtime (asset-manager)
- **Risk Level:** CRITICAL
- **Issue:** Public updates ended, only commercial support
- **Impact:** Security patches unavailable publicly
- **Migration Path:** Java 8 → Java 17 LTS or Java 21 LTS
- **Effort:** MEDIUM
- **Blocks:** Spring Boot 3.x upgrade

#### 3. .NET Framework 4.8 (ContosoUniversity, Malshinon)
- **Risk Level:** CRITICAL
- **Issue:** Legacy platform, maintenance mode only
- **Impact:** Windows-only deployment, missing modern features
- **Migration Path:** .NET Framework 4.8 → .NET 6 LTS or .NET 8
- **Effort:** HIGH (API changes, EF Core migration)
- **Benefits:** Cross-platform, performance improvements

---

### HIGH Priority Dependencies

#### 4. Java 11 (jakarta-ee)
- **Risk Level:** HIGH
- **Issue:** LTS extended support ends September 2026
- **Migration Path:** Java 11 → Java 17 LTS or Java 21 LTS
- **Effort:** LOW-MEDIUM

#### 5. Apache Ant Build System (jakarta-ee)
- **Risk Level:** HIGH
- **Issue:** Outdated build tool, poor dependency management
- **Migration Path:** Ant → Maven or Gradle
- **Effort:** MEDIUM (build script rewrite)

#### 6. Entity Framework Core 3.1.32 (ContosoUniversity)
- **Risk Level:** HIGH
- **Issue:** Last EF Core version for .NET Framework
- **Migration:** Tied to .NET Framework 4.8 → .NET 6/8 migration
- **Target:** EF Core 7 or 8 (requires .NET 6+)

---

### MEDIUM Priority Dependencies

#### 7. AWS SDK 2.25.13 (asset-manager)
- **Risk Level:** MEDIUM
- **Issue:** May not be latest version
- **Action:** Check for updates, security patches
- **Effort:** LOW (usually backward compatible)

#### 8. PostgreSQL Driver (asset-manager)
- **Risk Level:** MEDIUM
- **Status:** Using "latest" (no version pinning)
- **Issue:** Unpredictable behavior with auto-updates
- **Action:** Pin specific version for reproducibility

#### 9. mssql-jdbc 10.2.0 (mi-sql-public-demo)
- **Risk Level:** MEDIUM
- **Issue:** Not latest version (current is 12.x)
- **Action:** Update to latest
- **Effort:** LOW

---

## Component Dependency Analysis

### asset-manager Web Module

**Direct Dependencies:** 11  
**Total (including transitive):** ~80

**Critical Path:**
```
Web Application
├── Spring Boot 2.7.18 (CRITICAL)
├── AWS SDK S3 2.25.13 (MEDIUM)
├── Spring Boot AMQP (CRITICAL - depends on Spring Boot)
├── PostgreSQL Driver (MEDIUM)
└── Thymeleaf (LOW)
```

**Risk Assessment:**
- **Highest Risk:** Spring Boot 2.7.18 (EOL)
- **Second Risk:** Java 8 runtime
- **Migration Complexity:** HIGH (framework upgrade + Java upgrade)

---

### todo-web-api

**Direct Dependencies:** 7  
**Total (including transitive):** ~70

**Critical Path:**
```
REST API
├── Spring Boot 3.2.4 (✅ GOOD)
├── Oracle JDBC ojdbc11 (✅ GOOD)
├── Spring Data JPA (✅ GOOD)
└── Java 17 (✅ GOOD)
```

**Risk Assessment:**
- **Overall Status:** ✅ LOW RISK
- **Action:** Keep updated with Spring Boot patches
- **Notes:** Well-maintained, modern stack

---

### ContosoUniversity

**Direct NuGet Packages:** 47  
**Major Dependencies:** 15

**Critical Path:**
```
MVC Application
├── .NET Framework 4.8 (CRITICAL)
├── EF Core 3.1.32 (HIGH - last version for .NET Framework)
├── ASP.NET MVC 5.2.9 (HIGH - legacy)
├── Microsoft.Data.SqlClient 2.1.4 (MEDIUM)
└── Entity Framework packages (HIGH)
```

**Risk Assessment:**
- **Highest Risk:** .NET Framework 4.8 (legacy platform)
- **Blocker:** All EF Core, ASP.NET improvements require .NET 5+
- **Migration Complexity:** HIGH (platform change, EF migration, ASP.NET Core)

---

## Internal Component Dependencies

### asset-manager Internal Dependency Graph

```
┌─────────────────────────────────────────┐
│          Parent POM                     │
│  Spring Boot 2.7.18 (inherited)         │
└──────────┬──────────────────────────────┘
           │
           ├─────────────────┬────────────────────
           │                 │
     ┌─────▼─────┐     ┌─────▼──────┐
     │ Web Module│     │Worker Module│
     │           │     │             │
     │Controllers│     │ Listeners   │
     │     │     │     │     │       │
     │  Services │     │  Services   │
     │     │     │     │     │       │
     │Repositories◄────┼────Repositories
     └───────────┘     └─────────────┘
           │                  │
           └────────┬─────────┘
                    │
            ┌───────▼────────┐
            │  PostgreSQL DB │
            │  (Metadata)    │
            └────────────────┘
```

**Criticality:**
- **PostgreSQL:** HIGH (shared state between web/worker)
- **RabbitMQ:** HIGH (communication channel)
- **S3 Storage:** HIGH (data storage)

**Failure Impact:**
- DB failure: Both modules down
- RabbitMQ failure: Async processing stops (web still works)
- S3 failure: No file storage/retrieval

---

### ContosoUniversity Internal Dependency Graph

```
┌──────────────────────────┐
│      Controllers         │
│  (MVC Actions)           │
└──────────┬───────────────┘
           │
           │ Direct coupling
           │
    ┌──────▼──────────┐
    │  SchoolContext  │
    │  (EF DbContext) │
    └──────┬──────────┘
           │
    ┌──────▼──────────┐
    │  SQL Server DB  │
    │  (Data Storage) │
    └─────────────────┘
```

**Criticality:**
- **SQL Server:** CRITICAL (single point of failure)
- **DbContext:** HIGH (no abstraction layer)

**Pattern:** Direct data access from controllers (no repository pattern)

---

## Migration Dependency Order

### asset-manager Migration Path

1. **Upgrade Java 8 → 17** (enables Spring Boot 3)
2. **Upgrade Spring Boot 2.7 → 3.x** (major framework upgrade)
3. **Update AWS SDK** (if needed for Spring Boot 3 compatibility)
4. **Update PostgreSQL driver** (ensure compatibility)
5. **Test message queue integration** (ensure RabbitMQ still works)

**Estimated Timeline:** 2-3 months  
**Risk:** MEDIUM-HIGH (major version jumps)

---

### ContosoUniversity Migration Path

1. **Upgrade .NET Framework 4.8 → .NET 6/8** (platform migration)
2. **Migrate ASP.NET MVC 5 → ASP.NET Core MVC** (framework rewrite)
3. **Migrate EF Core 3.1 → EF Core 7/8** (ORM upgrade)
4. **Update Microsoft.Data.SqlClient** (ensure compatibility)
5. **Refactor to Repository Pattern** (optional but recommended)

**Estimated Timeline:** 4-6 months  
**Risk:** HIGH (major platform change)

---

## Dependency Conflict Analysis

### Multi-Module Version Conflicts (asset-manager)

**Potential Issue:** Web and Worker modules must use same versions of:
- Spring Boot framework
- AWS SDK
- PostgreSQL driver
- Shared model classes

**Mitigation:** Parent POM enforces version consistency

---

### Transitive Dependency Conflicts

**Java (Maven):**
- Spring Boot's dependency management resolves most conflicts
- Manual exclusions may be needed for specific cases

**.NET (NuGet):**
- NuGet automatically resolves to highest version
- May cause compatibility issues with older packages

**Recommendation:** Use dependency tree analysis to identify conflicts

---

## External Service Dependencies

### Cloud Service Dependencies

#### AWS Services (asset-manager)
- **S3:** Object storage (HIGH criticality)
- **Failure Impact:** File upload/download broken
- **Mitigation:** Implement retry logic, circuit breakers

#### Azure Services (mi-sql-public-demo, ContosoUniversity target)
- **Managed Identity:** Authentication (HIGH criticality)
- **Blob Storage:** File storage (ContosoUniversity target)
- **Failure Impact:** Authentication failure, storage unavailable

---

### Message Queue Dependencies

#### RabbitMQ (asset-manager)
- **Purpose:** Async worker communication
- **Criticality:** HIGH (for background processing)
- **Failure Mode:** Web still operates, thumbnails not generated
- **Mitigation:** Message persistence, dead letter queues

---

### Database Dependencies

#### PostgreSQL (asset-manager)
- **Purpose:** Image metadata storage
- **Criticality:** CRITICAL
- **Failure Mode:** Application cannot function
- **Mitigation:** Database clustering, replication

#### Oracle Database (todo-web-api)
- **Purpose:** Todo item persistence
- **Criticality:** CRITICAL
- **Failure Mode:** API cannot function

#### SQL Server (ContosoUniversity, mi-sql-public-demo)
- **Purpose:** Application data storage
- **Criticality:** CRITICAL
- **Failure Mode:** Application cannot function

---

## Dependency Security Analysis

### Known Vulnerabilities

**Action Required:**
1. Run OWASP Dependency-Check on all Java projects
2. Run NuGet vulnerability scanning on .NET projects
3. Review GitHub Dependabot alerts
4. Subscribe to security mailing lists for key dependencies

### High-Risk Dependency Patterns

1. **Outdated Spring Boot 2.7.18:** Known CVEs post-EOL
2. **Old Java 8:** Missing security patches
3. **.NET Framework 4.8:** Slower security patch cycles
4. **EF Core 3.1.32:** No longer receiving updates

---

## Recommendations

### Immediate Actions (0-1 Month)

1. Scan all projects for dependency vulnerabilities
2. Pin all "latest" versions to specific versions
3. Document all transitive dependencies
4. Create dependency update schedule

### Short-Term (1-3 Months)

1. Upgrade asset-manager: Java 8 → 17
2. Upgrade asset-manager: Spring Boot 2.7 → 3.x
3. Update all database drivers to latest versions
4. Implement dependency scanning in CI/CD

### Long-Term (3-12 Months)

1. Migrate ContosoUniversity to .NET 6/8
2. Migrate Malshinon to .NET 6/8
3. Migrate jakarta-ee from Ant to Maven
4. Standardize on modern dependency management practices

---

**Related Documentation:**
- [Dependencies Overview](../architecture/dependencies.md)
- [Technical Debt Report](../technical-debt-report.md)
- [Outdated Components](../technical-debt/outdated-components.md)
- [Dependency Graphs](../diagrams/structural/dependency-graphs.md)
