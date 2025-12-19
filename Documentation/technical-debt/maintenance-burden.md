# Maintenance Burden

**Analysis Date:** December 2024

## High Maintenance Projects

### jakarta-ee/student-web-app
**Issues:**
- Hybrid servlet/Spring MVC architecture
- Ant build system (manual dependency management)
- Java 11 (approaching EOL)

**Impact:** HIGH - Complex to maintain and extend

### ContosoUniversity
**Issues:**
- .NET Framework 4.8 (Windows-only)
- No repository pattern (direct DbContext usage)
- EF Core 3.1.32 (last version for .NET Framework)

**Impact:** HIGH - Limited by platform

### asset-manager
**Issues:**
- Java 8 (outdated)
- Spring Boot 2.7.18 (EOL)
- Multi-module complexity

**Impact:** MEDIUM - Needs modernization

## Complexity Metrics (Estimated)

### Cyclomatic Complexity
- Controllers: Medium (multiple conditional paths)
- Services: Medium (business logic)
- Repositories: Low (CRUD operations)

### Maintainability Index
- todo-web-api: HIGH (modern, clean)
- asset-manager: MEDIUM (needs updates)
- jakarta-ee: LOW (hybrid architecture)
- ContosoUniversity: MEDIUM (legacy platform)

**Related:** [Complexity Analysis](../analysis/complexity-analysis.md)
