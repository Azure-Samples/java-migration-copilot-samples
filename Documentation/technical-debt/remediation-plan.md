# Remediation Plan - Detailed Action Items

**Analysis Date:** December 2024

## Priority 1: Critical Issues (0-3 Months)

### Action 1.1: Upgrade asset-manager Java Runtime
**Timeline:** Weeks 1-2
**Steps:**
1. Update parent POM: `<java.version>17</java.version>`
2. Test compilation
3. Run existing tests
4. Deploy to dev environment

**Success Criteria:** All tests pass, application runs on Java 17

### Action 1.2: Upgrade asset-manager Spring Boot
**Timeline:** Weeks 3-8
**Prerequisites:** Java 17 upgrade complete
**Steps:**
1. Update parent POM: `<version>3.2.4</version>`
2. Change all `javax.*` imports to `jakarta.*`
3. Update dependency versions
4. Fix breaking API changes
5. Deploy and validate

**Success Criteria:** Application runs on Spring Boot 3.x

### Action 1.3: Security Dependency Scan
**Timeline:** Week 1
**Steps:**
1. Set up OWASP Dependency-Check for Java
2. Set up NuGet vulnerability scanning for .NET
3. Generate vulnerability reports
4. Update vulnerable dependencies

**Success Criteria:** Zero high/critical vulnerabilities

## Priority 2: High Priority (3-9 Months)

### Action 2.1: Migrate ContosoUniversity to .NET 6/8
**Timeline:** Months 4-7
**Steps:**
1. Create new .NET 6/8 project
2. Migrate ASP.NET MVC to ASP.NET Core
3. Migrate EF Core 3.1 to EF Core 7/8
4. Update all controllers and views
5. Comprehensive testing

**Success Criteria:** Application fully functional on .NET 6/8

### Action 2.2: Migrate jakarta-ee to Maven
**Timeline:** Months 4-5
**Steps:**
1. Create pom.xml with all dependencies
2. Migrate build scripts
3. Test build process
4. Remove Ant build files

**Success Criteria:** Maven build produces deployable artifact

## Priority 3: Architecture Improvements (9-12 Months)

### Action 3.1: Refactor jakarta-ee Architecture
**Timeline:** Months 10-12
**Steps:**
1. Standardize on Spring Boot
2. Remove servlet hybrid pattern
3. Update tests
4. Deploy

**Success Criteria:** Single framework architecture

## Resource Requirements

| Phase | Engineers | Duration | Risk |
|-------|-----------|----------|------|
| Priority 1 | 2 | 3 months | LOW |
| Priority 2 | 2-3 | 6 months | MEDIUM |
| Priority 3 | 1-2 | 3 months | MEDIUM |

**Related:** [Technical Debt Summary](summary.md), [Outdated Components](outdated-components.md)
