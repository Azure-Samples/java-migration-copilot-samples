# Component Migration Order

**Analysis Date:** December 2024  
**Migration Strategy:** Bottom-up, dependency-driven  
**Total Projects:** 8 (6 Java, 2 .NET)  
**Estimated Duration:** 8-12 weeks

---

## Table of Contents
- [Migration Strategy Overview](#migration-strategy-overview)
- [Dependency Analysis](#dependency-analysis)
- [Phase-Based Migration Order](#phase-based-migration-order)
- [Per-Project Migration Sequence](#per-project-migration-sequence)
- [Critical Dependencies and Blockers](#critical-dependencies-and-blockers)
- [Parallel Migration Opportunities](#parallel-migration-opportunities)

---

## Migration Strategy Overview

### Guiding Principles
1. **Foundation First**: Migrate data models, entities, and DTOs before dependent components
2. **Data Layer Before Business Logic**: Repositories and data access before services
3. **Business Logic Before Presentation**: Services before controllers/endpoints
4. **Infrastructure Early**: Configuration, security, and cross-cutting concerns early in each phase
5. **Independent Components in Parallel**: Projects with no inter-dependencies can be migrated simultaneously
6. **Test as You Go**: Unit tests migrate with each component; integration tests at service boundaries

### Overall Pattern
```
Foundation Layer (Phase 1)
    ↓
Data Access Layer (Phase 2)
    ↓
Business Logic Layer (Phase 3)
    ↓
API/Presentation Layer (Phase 4)
    ↓
Integration & Infrastructure (Phase 5)
```

---

## Dependency Analysis

### Inter-Project Dependencies
Based on static analysis, the projects are **independent** with no compile-time dependencies between them:

- **mi-sql-public-demo**: Standalone demo (no dependencies on other projects)
- **asset-manager (web + worker)**: Multi-module internal dependency (worker depends on web models)
- **todo-web-api-use-oracle-db**: Standalone API
- **rabbitmq-sender**: Standalone sender
- **jakarta-ee/student-web-app**: Standalone web app
- **ContosoUniversity**: Standalone .NET app
- **Malshinon**: Standalone .NET app

**Migration Implication**: All 8 projects can be migrated in **parallel** from a dependency perspective, but resource constraints may require sequential or batched execution.

### Intra-Project Dependencies (Layered Architecture)
Each project follows a layered architecture with these typical dependencies:

```
Controllers/Endpoints (depend on ↓)
    ↓
Services/Business Logic (depend on ↓)
    ↓
Repositories/DAL (depend on ↓)
    ↓
Models/Entities/DTOs (depend on ↓)
    ↓
Configuration/Infrastructure
```

---

## Phase-Based Migration Order

### Phase 1: Foundation and Configuration (Week 1-2)
**Rationale**: These components have no dependencies and are required by all other layers.

#### Java Projects
1. **All Projects**: Configuration classes
   - Application properties/YAML files
   - Database configuration
   - Security configuration
   - Bean definitions
   - Profile management

2. **All Projects**: Models and Entities
   - JPA/Hibernate entities
   - DTOs (Data Transfer Objects)
   - Request/Response models
   - Enums and constants
   - Validation annotations

#### .NET Projects
1. **ContosoUniversity & Malshinon**: Configuration
   - appsettings.json
   - Startup.cs/Program.cs configuration
   - Dependency injection setup

2. **ContosoUniversity & Malshinon**: Models
   - Entity Framework models
   - ViewModels
   - DTOs
   - Enums

#### Migration Order Within Phase 1
1. **mi-sql-public-demo**: Configuration (minimal - connection strings)
2. **asset-manager-web**: AssetMetadata entity, UploadResponse DTO
3. **asset-manager-worker**: Worker configuration
4. **todo-web-api**: TodoItem entity, TodoItemDTO
5. **rabbitmq-sender**: Message models
6. **jakarta-ee/student-web-app**: Student entity, form beans
7. **ContosoUniversity**: Student, Course, Enrollment, Department entities; ViewModels
8. **Malshinon**: Entity models, DataProcessor interfaces

**Deliverable**: All models compile independently; configuration classes validated.

---

### Phase 2: Data Access Layer (Week 3-4)
**Rationale**: Data access depends only on models (Phase 1). Services depend on repositories.

#### Java Projects
1. **asset-manager-web**: 
   - `AssetMetadataRepository` (Spring Data JPA)
   - Database schema migration scripts

2. **todo-web-api**:
   - `TodoItemRepository` (Spring Data JPA)
   - Oracle-specific query annotations

3. **jakarta-ee/student-web-app**:
   - MyBatis mapper XML files
   - `StudentMapper.xml`, `StudentDAO`

#### .NET Projects
1. **ContosoUniversity**:
   - `SchoolContext` (EF DbContext)
   - Repository pattern classes
   - SQL Server migrations

2. **Malshinon**:
   - `DAL` (Data Access Layer) classes
   - Database abstraction interfaces

#### Special Cases
- **mi-sql-public-demo**: No repository layer (raw JDBC) - migrate in Phase 4
- **rabbitmq-sender**: No database - skip Phase 2

**Deliverable**: All repositories testable with in-memory databases or mocks.

---

### Phase 3: Business Logic and Services (Week 5-7)
**Rationale**: Services depend on repositories (Phase 2) and models (Phase 1).

#### Java Projects
1. **asset-manager-web**:
   - `S3Service` (AWS S3 integration)
   - `LocalStorageService`
   - `MessagePublisher` (RabbitMQ)
   - Profile-based storage selection logic

2. **asset-manager-worker**:
   - `ThumbnailProcessor` (message consumer)
   - Image processing logic
   - S3 upload logic

3. **todo-web-api**:
   - `TodoService` (CRUD operations)
   - Business validation logic

4. **rabbitmq-sender**:
   - `MessageSenderService`
   - Queue connection management

5. **jakarta-ee/student-web-app**:
   - `StudentService`
   - Business validation

#### .NET Projects
1. **ContosoUniversity**:
   - Student management services
   - Course management services
   - Enrollment processing
   - Department management

2. **Malshinon**:
   - `DataProcessorFactory`
   - `CSVProcessor`, `ExcelProcessor`, `JSONProcessor`
   - Processing orchestration logic

**Deliverable**: All services unit-tested with mocked repositories.

---

### Phase 4: Controllers and API Endpoints (Week 8-9)
**Rationale**: Controllers depend on services (Phase 3).

#### Java Projects
1. **asset-manager-web**:
   - `HomeController` (view rendering)
   - `S3Controller` (file upload endpoints)
   - Request validation
   - Response formatting

2. **todo-web-api**:
   - `TodoController` (REST endpoints)
   - HTTP status code handling
   - Exception handling

3. **jakarta-ee/student-web-app**:
   - Servlet controllers
   - Spring MVC controllers
   - Form submission handling

#### .NET Projects
1. **ContosoUniversity**:
   - `StudentsController`
   - `CoursesController`
   - `DepartmentsController`
   - `InstructorsController`
   - View rendering logic

2. **Malshinon**:
   - Controller endpoints (if any)
   - API wrappers

#### Special Cases
- **mi-sql-public-demo**: Main application class (combines data access and business logic)

**Deliverable**: All endpoints testable via REST clients or integration tests.

---

### Phase 5: Integration, Infrastructure, and Cross-Cutting Concerns (Week 10-12)
**Rationale**: Final integration after all components are migrated.

#### Components to Migrate
1. **Security and Authentication**:
   - Spring Security configurations
   - Azure Managed Identity (mi-sql-public-demo)
   - JWT token handling (if applicable)

2. **Messaging Infrastructure**:
   - RabbitMQ connection factories (asset-manager)
   - Queue/exchange declarations
   - Message serialization/deserialization

3. **Cloud Service Integration**:
   - AWS S3 client configuration
   - Azure service integrations
   - Credential management

4. **Observability**:
   - Logging configuration
   - Metrics/monitoring setup
   - Health check endpoints

5. **Deployment Assets**:
   - Dockerfiles
   - Kubernetes manifests
   - CI/CD pipeline definitions
   - Environment-specific configurations

6. **Testing Infrastructure**:
   - Integration test suites
   - End-to-end test scenarios
   - Performance test harnesses

**Deliverable**: Fully integrated, deployable applications with operational readiness.

---

## Per-Project Migration Sequence

### 1. mi-sql-public-demo (Simplest - 2 days)
```
Day 1: Configuration → MainSQL class → Connection logic
Day 2: Query execution → Result processing → Testing
```
**Dependencies**: None  
**Blocker Risk**: Low

---

### 2. asset-manager (Most Complex - 3 weeks)

#### Web Module (2 weeks)
```
Week 1:
  - AssetMetadata entity
  - AssetMetadataRepository
  - UploadResponse DTO
  - Database configuration

Week 2:
  - S3Service, LocalStorageService
  - MessagePublisher
  - HomeController, S3Controller
  - Thymeleaf templates
  - AWS S3 integration
  - RabbitMQ integration
```

#### Worker Module (1 week)
```
Week 3:
  - Worker configuration
  - ThumbnailProcessor (message listener)
  - Image processing logic
  - S3 upload integration
  - Deployment and testing
```

**Dependencies**: Web entities/DTOs must be available before worker  
**Blocker Risk**: Medium (AWS/RabbitMQ connectivity)

---

### 3. todo-web-api-use-oracle-db (1 week)
```
Day 1-2: TodoItem entity, TodoItemDTO, Configuration
Day 3-4: TodoItemRepository, Oracle-specific queries
Day 5: TodoService with validation
Day 6-7: TodoController, REST endpoints, Testing
```
**Dependencies**: None  
**Blocker Risk**: Low-Medium (Oracle database availability)

---

### 4. rabbitmq-sender (2 days)
```
Day 1: Configuration, Message models, RabbitMQ setup
Day 2: MessageSenderService, Testing
```
**Dependencies**: None  
**Blocker Risk**: Low-Medium (RabbitMQ availability)

---

### 5. jakarta-ee/student-web-app (1.5 weeks)
```
Week 1:
  - Student entity
  - MyBatis mapper XML
  - StudentDAO
  - StudentService

Week 2 (first half):
  - Servlet controllers
  - Spring MVC controllers
  - JSP views
  - Testing
```
**Dependencies**: None  
**Blocker Risk**: Low-Medium (MyBatis configuration)

---

### 6. ContosoUniversity (.NET - 2 weeks)
```
Week 1:
  - Student, Course, Enrollment, Department entities
  - ViewModels
  - SchoolContext (EF Core)
  - Repository pattern

Week 2:
  - Business services
  - StudentsController, CoursesController, etc.
  - Views (Razor)
  - SQL Server migrations
  - Testing
```
**Dependencies**: None  
**Blocker Risk**: Low-Medium (SQL Server availability)

---

### 7. Malshinon (.NET - 1 week)
```
Day 1-2: Entity models, DAL interfaces
Day 3-4: DataProcessorFactory, processor implementations
Day 5-7: Controller integration, Testing
```
**Dependencies**: None  
**Blocker Risk**: Low

---

## Critical Dependencies and Blockers

### External Dependencies
| Project | Dependency | Type | Migration Blocker Risk |
|---------|------------|------|----------------------|
| mi-sql-public-demo | Azure SQL Server | Database | Medium - Requires Azure credentials |
| mi-sql-public-demo | Azure Managed Identity | Auth | High - Requires Azure environment |
| asset-manager-web | PostgreSQL | Database | Low - Can use Docker |
| asset-manager-web | AWS S3 | Storage | Medium - Requires AWS credentials |
| asset-manager-web | RabbitMQ | Messaging | Low - Can use Docker |
| asset-manager-worker | RabbitMQ | Messaging | Low - Can use Docker |
| todo-web-api | Oracle Database | Database | High - Oracle license required |
| ContosoUniversity | SQL Server | Database | Low - Can use LocalDB/Docker |

### Mitigation Strategies
1. **Azure Dependencies**: Set up test Azure environment early; use Azure CLI for credentials
2. **Oracle Database**: Provision Oracle DB in Docker or use Oracle Cloud free tier
3. **AWS S3**: Use LocalStack or MinIO for local S3-compatible storage during development
4. **RabbitMQ**: Use Docker Compose for local RabbitMQ instance

---

## Parallel Migration Opportunities

### Batch 1 (Simple Projects - Week 1-2)
Can be migrated in parallel by different team members:
- mi-sql-public-demo (Developer A)
- rabbitmq-sender (Developer B)
- Malshinon (Developer C)

### Batch 2 (Medium Complexity - Week 3-5)
- todo-web-api (Developer A)
- jakarta-ee/student-web-app (Developer B)
- ContosoUniversity (Developer C)

### Batch 3 (Complex - Week 6-12)
- asset-manager (requires dedicated team due to complexity)

### Resource Optimization
- **Single Developer**: Follow priority order (mi-sql → rabbitmq → Malshinon → todo-api → jakarta-ee → ContosoU → asset-manager)
- **3 Developers**: Follow batch strategy above
- **5+ Developers**: All projects can start simultaneously in Phase 1

---

## Testing Strategy Per Phase

### Phase 1 (Models)
- **Unit Tests**: Model validation, serialization/deserialization
- **No Integration Tests**: Models are pure data structures

### Phase 2 (Repositories)
- **Unit Tests**: Repository methods with in-memory/H2 databases
- **Integration Tests**: Repository integration with real databases (Docker)

### Phase 3 (Services)
- **Unit Tests**: Business logic with mocked repositories
- **Integration Tests**: Service integration with real repositories

### Phase 4 (Controllers)
- **Unit Tests**: Controller logic with mocked services
- **Integration Tests**: HTTP endpoint testing with MockMvc/TestRestTemplate

### Phase 5 (Full Stack)
- **End-to-End Tests**: Complete user workflows
- **Performance Tests**: Load testing, stress testing
- **Security Tests**: Vulnerability scanning, penetration testing

---

## Validation Checkpoints

### After Each Phase
- [ ] All components compile without errors
- [ ] All unit tests pass
- [ ] Code coverage ≥ 80% for new code
- [ ] Static analysis (SonarQube) passes quality gates
- [ ] Peer code review completed
- [ ] Documentation updated

### Final Validation (After Phase 5)
- [ ] All integration tests pass
- [ ] All end-to-end tests pass
- [ ] Performance benchmarks met
- [ ] Security scan passes
- [ ] Deployment to staging successful
- [ ] Smoke tests in staging pass

---

**Related Documentation:**
- [Test Specifications](test-specifications.md) - Detailed test cases for each component
- [Validation Criteria](validation-criteria.md) - Acceptance criteria and quality gates
- [Program Structure](../reference/program-structure.md) - Complete component inventory
- [Dependencies](../architecture/dependencies.md) - External library dependencies
- [Technical Debt Report](../technical-debt-report.md) - Migration risks and considerations
