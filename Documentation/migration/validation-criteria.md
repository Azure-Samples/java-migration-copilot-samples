# Validation Criteria

**Analysis Date:** December 2024  
**Validation Approach:** Multi-stage quality gates  
**Total Projects:** 8 (6 Java, 2 .NET)  
**Quality Standard:** Production-ready migration

---

## Table of Contents
- [Overview](#overview)
- [Phase-Based Validation Gates](#phase-based-validation-gates)
- [Per-Project Validation Criteria](#per-project-validation-criteria)
- [Functional Validation](#functional-validation)
- [Non-Functional Validation](#non-functional-validation)
- [Security Validation](#security-validation)
- [Performance Validation](#performance-validation)
- [Migration Acceptance Criteria](#migration-acceptance-criteria)

---

## Overview

### Validation Philosophy
**Progressive Quality Assurance**: Each migration phase must pass validation gates before proceeding to the next phase. This ensures early detection of issues and prevents compounding technical debt.

### Quality Levels
1. **Phase Gate**: Minimum criteria to proceed to next phase
2. **Project Complete**: Criteria for project readiness
3. **Production Ready**: Final deployment criteria

### Validation Types
- **Functional**: Features work as specified
- **Non-Functional**: Performance, scalability, maintainability
- **Security**: Vulnerabilities, authentication, authorization
- **Integration**: Inter-component and external system integration
- **Regression**: No existing functionality broken

---

## Phase-Based Validation Gates

### Phase 1: Foundation and Configuration
**Goal**: All models and configuration classes compile and pass basic validation

#### Compilation Criteria
| Criterion | Standard | Validation Method |
|-----------|----------|-------------------|
| Zero compilation errors | 100% success | Maven/MSBuild compile |
| No syntax errors | 100% clean | IDE/compiler output |
| All dependencies resolved | 100% resolved | Dependency check |
| Configuration files valid | All parseable | Application startup (dry-run) |

#### Model Validation Criteria
| Criterion | Standard | Validation Method |
|-----------|----------|-------------------|
| All entities have valid annotations | 100% compliant | Static analysis |
| Validation constraints defined | All required fields | Bean Validation check |
| Serialization/deserialization works | All models | Unit tests |
| No circular dependencies | Zero detected | Dependency analyzer |
| Database schema generation succeeds | No errors | Hibernate schema validation |

#### Exit Criteria for Phase 1
- [ ] All Java projects compile: `mvn clean compile` succeeds
- [ ] All .NET projects build: `dotnet build` succeeds
- [ ] Zero critical SonarQube issues (Blocker/Critical)
- [ ] All model unit tests pass (100%)
- [ ] Configuration files validated (application starts in test mode)
- [ ] Database connection configured (connection test passes)

**Acceptance Threshold**: 100% pass rate on all criteria

---

### Phase 2: Data Access Layer
**Goal**: All repositories/DAOs function correctly with database operations

#### Repository Functional Criteria
| Criterion | Standard | Validation Method |
|-----------|----------|-------------------|
| CRUD operations | All work correctly | Repository unit tests |
| Custom queries | All execute without error | Query tests |
| Transactional behavior | Rollback works | Transaction tests |
| Cascade operations | Behave as expected | Relationship tests |
| Database constraints | Enforced correctly | Constraint violation tests |

#### Database Integration Criteria
| Criterion | Standard | Validation Method |
|-----------|----------|-------------------|
| Schema creation | Matches entity definitions | Schema validation |
| Data persistence | Data survives restart | Integration tests |
| Query performance | <100ms for simple queries | Query profiling |
| Connection pooling | Configured correctly | Connection pool tests |
| Database migrations | Execute without errors | Flyway/Liquibase check |

#### Exit Criteria for Phase 2
- [ ] All repository unit tests pass (≥90% coverage)
- [ ] All integration tests with test database pass
- [ ] Database schema validated against entities
- [ ] No N+1 query problems detected
- [ ] Transaction boundaries correct
- [ ] Database connection pool configured
- [ ] All SQL queries optimized (no table scans on indexed columns)

**Acceptance Threshold**: ≥90% test pass rate, zero data integrity issues

---

### Phase 3: Business Logic and Services
**Goal**: All services implement business logic correctly

#### Service Functional Criteria
| Criterion | Standard | Validation Method |
|-----------|----------|-------------------|
| Business rules enforced | 100% coverage | Service unit tests |
| Validation logic | All constraints checked | Validation tests |
| Error handling | All exceptions caught | Exception tests |
| State transitions | Correct behavior | State machine tests |
| External service integration | Mocked correctly | Mock verification |

#### Service Quality Criteria
| Criterion | Standard | Validation Method |
|-----------|----------|-------------------|
| Code coverage | ≥90% for services | JaCoCo/Coverlet |
| Cyclomatic complexity | <15 per method | Complexity analyzer |
| Service layer isolated | No direct DB access | Architecture tests |
| Dependency injection | All dependencies injected | DI container validation |
| Logging | Appropriate log levels | Log output review |

#### Exit Criteria for Phase 3
- [ ] All service unit tests pass (≥90% coverage)
- [ ] Business rules documented and tested
- [ ] All validation rules enforced
- [ ] Error handling comprehensive
- [ ] Services properly mocked in tests
- [ ] No direct database access in services (except via repositories)
- [ ] Logging configured at appropriate levels

**Acceptance Threshold**: ≥90% test pass rate, ≥90% code coverage

---

### Phase 4: Controllers and API Endpoints
**Goal**: All API endpoints function correctly and return expected responses

#### API Functional Criteria
| Criterion | Standard | Validation Method |
|-----------|----------|-------------------|
| All endpoints accessible | 100% reachable | Endpoint tests |
| HTTP status codes correct | Per REST standards | HTTP tests |
| Request validation | Invalid requests rejected | Validation tests |
| Response format | JSON/XML valid | Schema validation |
| Authentication/Authorization | Access control works | Security tests |

#### API Quality Criteria
| Criterion | Standard | Validation Method |
|-----------|----------|-------------------|
| Response time | <500ms (p95) | Performance tests |
| Error responses | Consistent format | Error response tests |
| API documentation | All endpoints documented | OpenAPI/Swagger |
| CORS configuration | Correct headers | CORS tests |
| Content negotiation | Works correctly | Accept header tests |

#### Exit Criteria for Phase 4
- [ ] All controller unit tests pass (≥80% coverage)
- [ ] All API integration tests pass
- [ ] HTTP status codes correct (200, 201, 400, 404, 500, etc.)
- [ ] Request/response validation works
- [ ] API documentation generated (Swagger/OpenAPI)
- [ ] CORS configured correctly
- [ ] Authentication/authorization enforced (if applicable)
- [ ] Error responses consistent

**Acceptance Threshold**: ≥80% test pass rate, all critical endpoints functional

---

### Phase 5: Integration and Infrastructure
**Goal**: Fully integrated system ready for deployment

#### Integration Criteria
| Criterion | Standard | Validation Method |
|-----------|----------|-------------------|
| Database integration | Full CRUD works | End-to-end tests |
| Messaging integration | Messages sent/received | Message queue tests |
| Cloud service integration | S3/Azure services work | Cloud integration tests |
| External API integration | Third-party APIs work | API integration tests |
| Service-to-service | Inter-service calls work | Service mesh tests |

#### Infrastructure Criteria
| Criterion | Standard | Validation Method |
|-----------|----------|-------------------|
| Containerization | Docker builds succeed | Docker build test |
| Environment configuration | All envs configured | Config validation |
| Health checks | All respond correctly | Health endpoint tests |
| Monitoring | Metrics collected | Observability check |
| Logging | Centralized logging works | Log aggregation check |

#### Exit Criteria for Phase 5
- [ ] All end-to-end tests pass
- [ ] Cloud service integrations tested
- [ ] Message queue integration tested (if applicable)
- [ ] Docker containers build successfully
- [ ] Health check endpoints respond
- [ ] Logging configured and aggregated
- [ ] Metrics/monitoring configured
- [ ] Environment-specific configurations validated

**Acceptance Threshold**: 100% end-to-end test pass rate

---

## Per-Project Validation Criteria

### 1. mi-sql-public-demo

#### Functional Validation
- [ ] Application starts without errors
- [ ] Azure Managed Identity authentication succeeds
- [ ] SQL Server connection established
- [ ] Sample query executes successfully
- [ ] Results processed and displayed correctly

#### Non-Functional Validation
- [ ] Connection established in <3 seconds
- [ ] Query execution time <1 second
- [ ] Proper error handling for connection failures
- [ ] Logs contain appropriate information

#### Security Validation
- [ ] No hardcoded credentials
- [ ] Managed Identity token acquired securely
- [ ] SQL injection vulnerabilities absent

**Acceptance**: All criteria met

---

### 2. asset-manager (Web Module)

#### Functional Validation
- [ ] Home page renders correctly
- [ ] File upload endpoint accepts files
- [ ] Files stored in S3 or local storage based on profile
- [ ] Metadata saved to PostgreSQL database
- [ ] RabbitMQ message published on upload (AWS profile)
- [ ] Upload response contains correct information
- [ ] Empty file uploads rejected
- [ ] Large files handled within limits

#### Non-Functional Validation
- [ ] Upload response time <2 seconds (small files)
- [ ] Concurrent uploads handled (≥10 simultaneous)
- [ ] Database connection pool sized correctly
- [ ] S3 upload retries on failure
- [ ] Graceful degradation if RabbitMQ unavailable

#### Security Validation
- [ ] File type validation enforced
- [ ] File size limits enforced
- [ ] AWS credentials not exposed
- [ ] Database credentials secured
- [ ] No path traversal vulnerabilities

**Acceptance**: All functional criteria met, ≥80% non-functional criteria met

---

### 3. asset-manager (Worker Module)

#### Functional Validation
- [ ] Worker consumes messages from RabbitMQ
- [ ] Image downloaded from S3
- [ ] Thumbnail generated successfully
- [ ] Thumbnail uploaded to S3
- [ ] Metadata updated with thumbnail URL
- [ ] Corrupted images handled gracefully
- [ ] Failed processing retried (configurable)

#### Non-Functional Validation
- [ ] Thumbnail generation time <5 seconds
- [ ] Worker processes ≥10 messages/minute
- [ ] Memory usage stable (<512MB)
- [ ] Graceful shutdown on SIGTERM
- [ ] Dead letter queue configured for failures

**Acceptance**: All functional criteria met, ≥80% non-functional criteria met

---

### 4. todo-web-api-use-oracle-db

#### Functional Validation
- [ ] All CRUD endpoints functional:
  - [ ] GET /api/todos - List all todos
  - [ ] GET /api/todos/{id} - Get single todo
  - [ ] POST /api/todos - Create todo
  - [ ] PUT /api/todos/{id} - Update todo
  - [ ] DELETE /api/todos/{id} - Delete todo
- [ ] Validation enforced:
  - [ ] Title required (max 200 chars)
  - [ ] Description optional (max 4000 chars)
- [ ] Default values applied (completed=false, priority=0)
- [ ] Timestamps auto-generated
- [ ] 404 returned for non-existent IDs
- [ ] 400 returned for validation failures

#### Non-Functional Validation
- [ ] Response time <100ms for GET (p95)
- [ ] Response time <200ms for POST/PUT (p95)
- [ ] Oracle database connection pooled
- [ ] Concurrent requests handled (≥100 req/s)
- [ ] Oracle VARCHAR2 types handled correctly

#### Security Validation
- [ ] SQL injection prevented (parameterized queries)
- [ ] Oracle database credentials secured
- [ ] Input sanitization enforced

**Acceptance**: All CRUD operations functional, validation enforced

---

### 5. rabbitmq-sender

#### Functional Validation
- [ ] Application sends messages to RabbitMQ
- [ ] Message payload formatted correctly
- [ ] Queue/exchange binding correct
- [ ] Message persistence configured
- [ ] Connection retries on failure

#### Non-Functional Validation
- [ ] Message send time <100ms
- [ ] Throughput ≥100 messages/second
- [ ] Connection pooling configured
- [ ] Graceful degradation on RabbitMQ failure

**Acceptance**: Messages sent successfully, retry logic works

---

### 6. jakarta-ee/student-web-app

#### Functional Validation
- [ ] Student list page displays correctly
- [ ] Student create form works
- [ ] Student created successfully
- [ ] Student edit form populates data
- [ ] Student updated successfully
- [ ] Student deleted successfully
- [ ] MyBatis mapper executes SQL correctly
- [ ] Validation enforced (email format, required fields)

#### Non-Functional Validation
- [ ] Page load time <1 second
- [ ] MyBatis query cache configured
- [ ] Database connection pool configured
- [ ] Session management configured

**Acceptance**: All CRUD operations functional via web UI

---

### 7. ContosoUniversity (.NET)

#### Functional Validation
- [ ] All entity CRUD operations work:
  - [ ] Students: Create, Read, Update, Delete
  - [ ] Courses: Create, Read, Update, Delete
  - [ ] Departments: Create, Read, Update, Delete
  - [ ] Enrollments: Create, Read, Update, Delete
- [ ] Validation enforced:
  - [ ] Enrollment date range (1753-9999)
  - [ ] Course credits (0-5)
- [ ] Cascade delete on student (enrollments deleted)
- [ ] Concurrency control on Department (RowVersion)
- [ ] Search and filtering work
- [ ] Sorting works
- [ ] Pagination works

#### Non-Functional Validation
- [ ] Page load time <1 second
- [ ] Entity Framework queries optimized
- [ ] SQL Server connection pooled
- [ ] Concurrency conflicts handled

#### Security Validation
- [ ] SQL injection prevented (EF parameterization)
- [ ] SQL Server credentials secured
- [ ] Input validation enforced

**Acceptance**: All entity operations functional, concurrency handled

---

### 8. Malshinon (.NET)

#### Functional Validation
- [ ] DataProcessorFactory creates processors by type
- [ ] CSVProcessor processes CSV data
- [ ] ExcelProcessor processes Excel data
- [ ] JSONProcessor processes JSON data
- [ ] DAL performs database operations
- [ ] Invalid processor type handled gracefully

#### Non-Functional Validation
- [ ] Processor creation time <50ms
- [ ] Data processing throughput adequate
- [ ] Memory usage stable
- [ ] Factory pattern extensibility validated

**Acceptance**: All processor types functional, factory pattern works

---

## Functional Validation

### Acceptance Criteria by Component Type

#### Models/Entities
- [ ] All fields mapped correctly
- [ ] Validation annotations present
- [ ] Serialization/deserialization works
- [ ] Relationships configured correctly

#### Repositories/DAOs
- [ ] All CRUD operations work
- [ ] Custom queries execute correctly
- [ ] Transactions commit/rollback
- [ ] Cascade operations work

#### Services
- [ ] Business logic implemented correctly
- [ ] Validation rules enforced
- [ ] Error handling comprehensive
- [ ] External services integrated

#### Controllers/Endpoints
- [ ] All endpoints accessible
- [ ] HTTP methods correct
- [ ] Status codes appropriate
- [ ] Request/response format correct

---

## Non-Functional Validation

### Performance Criteria
| Metric | Standard | Measurement Method |
|--------|----------|--------------------|
| API response time (p95) | <500ms | Load testing |
| Database query time | <100ms | Query profiling |
| Throughput | ≥100 req/s | Load testing |
| Memory usage | Stable, no leaks | Profiling |
| CPU usage | <80% under load | Monitoring |

### Scalability Criteria
- [ ] Handles 100 concurrent users
- [ ] Horizontal scaling tested (if applicable)
- [ ] Database connection pool scales
- [ ] No resource exhaustion under load

### Maintainability Criteria
- [ ] Code coverage ≥80%
- [ ] Cyclomatic complexity <15
- [ ] SonarQube quality gate passed
- [ ] Technical debt ratio <5%
- [ ] Code duplicated <3%

### Reliability Criteria
- [ ] Error handling comprehensive
- [ ] Retry logic implemented (where applicable)
- [ ] Circuit breakers configured (where applicable)
- [ ] Health checks respond correctly
- [ ] Graceful shutdown implemented

---

## Security Validation

### Security Checklist (All Projects)

#### Authentication & Authorization
- [ ] No hardcoded credentials
- [ ] Credentials stored securely (environment variables, vault)
- [ ] Authentication enforced (if applicable)
- [ ] Authorization rules enforced (if applicable)
- [ ] Session management secure (if applicable)

#### Input Validation
- [ ] All user inputs validated
- [ ] SQL injection prevented (parameterized queries)
- [ ] XSS prevention implemented (web projects)
- [ ] CSRF protection enabled (web projects)
- [ ] File upload validation (type, size)

#### Data Protection
- [ ] Sensitive data encrypted in transit (HTTPS)
- [ ] Sensitive data encrypted at rest (if applicable)
- [ ] Database credentials secured
- [ ] API keys secured
- [ ] No sensitive data in logs

#### Vulnerability Scanning
- [ ] OWASP dependency check passes
- [ ] Snyk vulnerability scan passes
- [ ] No critical/high vulnerabilities
- [ ] Security headers configured (web projects)

**Acceptance**: Zero critical/high vulnerabilities, all security best practices followed

---

## Performance Validation

### Load Testing Scenarios

#### asset-manager
| Scenario | Concurrency | Duration | Success Criteria |
|----------|-------------|----------|------------------|
| File upload | 50 users | 5 minutes | <2s response time (p95), 0% errors |
| Concurrent uploads | 100 users | 10 minutes | No database deadlocks, <5% errors |

#### todo-web-api
| Scenario | Concurrency | Duration | Success Criteria |
|----------|-------------|----------|------------------|
| GET all todos | 200 users | 5 minutes | <100ms response time (p95) |
| CRUD operations | 100 users | 10 minutes | <200ms response time (p95), 0% errors |

#### ContosoUniversity
| Scenario | Concurrency | Duration | Success Criteria |
|----------|-------------|----------|------------------|
| Student search | 100 users | 5 minutes | <500ms response time (p95) |
| Student CRUD | 50 users | 10 minutes | <1s response time (p95), 0% errors |

### Performance Acceptance
- [ ] All load tests pass success criteria
- [ ] No memory leaks detected
- [ ] Database connection pool sized correctly
- [ ] No resource exhaustion under load

---

## Migration Acceptance Criteria

### Pre-Production Checklist

#### Code Quality
- [ ] All unit tests pass (≥80% coverage)
- [ ] All integration tests pass
- [ ] All end-to-end tests pass
- [ ] SonarQube quality gate passed
- [ ] Zero critical/high security vulnerabilities
- [ ] Code review completed

#### Functional Completeness
- [ ] All features migrated
- [ ] All endpoints functional
- [ ] All business logic implemented
- [ ] All validation rules enforced
- [ ] Error handling comprehensive

#### Non-Functional Readiness
- [ ] Performance benchmarks met
- [ ] Load testing completed
- [ ] Security scanning passed
- [ ] Logging configured
- [ ] Monitoring configured
- [ ] Health checks implemented

#### Deployment Readiness
- [ ] Docker containers build successfully
- [ ] Environment configurations validated
- [ ] Database migrations tested
- [ ] Rollback plan documented
- [ ] Deployment documentation complete
- [ ] Runbook created

#### Production Deployment Approval
- [ ] All acceptance criteria met
- [ ] Stakeholder sign-off obtained
- [ ] Production deployment scheduled
- [ ] Support team trained
- [ ] Incident response plan ready

---

## Regression Validation

### Regression Test Suite
- [ ] All existing tests still pass
- [ ] No previously working features broken
- [ ] Performance not degraded
- [ ] No new security vulnerabilities introduced
- [ ] Database schema changes backward compatible (if applicable)

### Smoke Tests (Post-Deployment)
| Test | Expected Outcome | Validation Method |
|------|------------------|-------------------|
| Application starts | No errors | Health check endpoint |
| Database connection | Successful | Connection test |
| API endpoints respond | 200 OK | Smoke test suite |
| Key user workflows | Successful | Critical path tests |
| Logging works | Logs visible | Log aggregator check |

**Acceptance**: All smoke tests pass within 15 minutes of deployment

---

## Final Production Readiness

### Go/No-Go Criteria
**GO**: All of the following must be true:
- [ ] All functional tests pass (100%)
- [ ] All integration tests pass (100%)
- [ ] All end-to-end tests pass (100%)
- [ ] Performance criteria met (≥80%)
- [ ] Security scan passes (zero critical/high)
- [ ] Code coverage ≥80%
- [ ] SonarQube quality gate passed
- [ ] Deployment tested in staging
- [ ] Rollback plan validated
- [ ] Stakeholder approval obtained

**NO-GO**: Any of the following:
- Critical functionality not working
- Critical security vulnerabilities present
- Performance significantly degraded
- Data integrity issues
- High-severity bugs unresolved

---

**Related Documentation:**
- [Component Migration Order](component-order.md) - Defines migration phases
- [Test Specifications](test-specifications.md) - Detailed test cases for validation
- [Program Structure](../reference/program-structure.md) - Component inventory
- [Technical Debt Report](../technical-debt-report.md) - Quality concerns
