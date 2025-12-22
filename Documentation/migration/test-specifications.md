# Test Specifications

**Analysis Date:** December 2024  
**Testing Strategy:** Multi-layer (Unit → Integration → End-to-End)  
**Total Projects:** 8 (6 Java, 2 .NET)  
**Coverage Target:** ≥80% for all layers

---

## Table of Contents
- [Testing Strategy Overview](#testing-strategy-overview)
- [Test Types and Frameworks](#test-types-and-frameworks)
- [Per-Project Test Specifications](#per-project-test-specifications)
- [Data Layer Tests](#data-layer-tests)
- [Service Layer Tests](#service-layer-tests)
- [API/Controller Layer Tests](#api-controller-layer-tests)
- [Integration Tests](#integration-tests)
- [End-to-End Tests](#end-to-end-tests)
- [Test Data Management](#test-data-management)
- [Performance and Load Tests](#performance-and-load-tests)

---

## Testing Strategy Overview

### Test Pyramid Approach
```
                    E2E Tests (10%)
                  ┌─────────────┐
                  │   Manual    │
                  │  Exploratory│
                  └─────────────┘
              Integration Tests (20%)
          ┌───────────────────────────┐
          │  API Tests, DB Integration│
          │  Message Queue Integration│
          └───────────────────────────┘
          Unit Tests (70%)
┌─────────────────────────────────────────────┐
│ Models, Services, Repositories, Controllers │
│         Fast, Isolated, Mocked              │
└─────────────────────────────────────────────┘
```

### Testing Principles
1. **Fast Feedback**: Unit tests run in <5 seconds per project
2. **Isolation**: Mock external dependencies (databases, APIs, queues)
3. **Repeatability**: Tests produce consistent results across runs
4. **Coverage**: Aim for 80%+ code coverage, 100% for critical paths
5. **Clarity**: Each test verifies one behavior with descriptive names

---

## Test Types and Frameworks

### Java Projects

#### Test Frameworks
- **JUnit 5** (Jupiter): Primary testing framework
- **Mockito**: Mocking framework for dependencies
- **Spring Boot Test**: Integration testing with `@SpringBootTest`
- **MockMvc**: Controller/API endpoint testing
- **Testcontainers**: Docker-based integration tests (PostgreSQL, Oracle, RabbitMQ)
- **AssertJ**: Fluent assertions library

#### Maven Configuration
```xml
<dependencies>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-test</artifactId>
        <scope>test</scope>
    </dependency>
    <dependency>
        <groupId>org.testcontainers</groupId>
        <artifactId>postgresql</artifactId>
        <scope>test</scope>
    </dependency>
</dependencies>
```

---

### .NET Projects

#### Test Frameworks
- **xUnit** or **NUnit**: Primary testing framework
- **Moq**: Mocking framework
- **FluentAssertions**: Assertion library
- **Entity Framework In-Memory Database**: Repository testing
- **WebApplicationFactory**: Controller integration testing

---

## Per-Project Test Specifications

### 1. mi-sql-public-demo

**Complexity**: Low  
**Test Files**: 1-2  
**Estimated Test Count**: 5-10 tests

#### Unit Tests (2-3 tests)
| Test Name | Component | Description | Expected Outcome |
|-----------|-----------|-------------|------------------|
| `testConnectionStringBuilding` | MainSQL | Verify connection string format | Connection string contains required parameters |
| `testManagedIdentityTokenRetrieval` | MainSQL | Test Azure MI token acquisition (mocked) | Token retrieved successfully |

#### Integration Tests (3-5 tests)
| Test Name | Component | Description | Expected Outcome |
|-----------|-----------|-------------|------------------|
| `testDatabaseConnection` | MainSQL | Connect to test Azure SQL | Connection established |
| `testQueryExecution` | MainSQL | Execute sample query | Result set returned |
| `testResultProcessing` | MainSQL | Process query results | Data extracted correctly |
| `testErrorHandlingOnConnectionFailure` | MainSQL | Simulate connection failure | Exception caught and logged |

#### Test Data
- Use test Azure SQL database with sample data
- Mock Azure Managed Identity credentials for unit tests

---

### 2. asset-manager (Web Module)

**Complexity**: High  
**Test Files**: 10-15  
**Estimated Test Count**: 60-80 tests

#### Model Tests (5-8 tests)
| Test Name | Component | Description | Expected Outcome |
|-----------|-----------|-------------|------------------|
| `testAssetMetadataCreation` | AssetMetadata | Create entity with all fields | Entity created successfully |
| `testAssetMetadataValidation` | AssetMetadata | Validate required fields | Validation errors for missing fields |
| `testUploadResponseSerialization` | UploadResponse | JSON serialization | JSON contains expected fields |
| `testAssetMetadataTimestamps` | AssetMetadata | Auto-generated timestamps | Timestamps populated on create |

#### Repository Tests (8-10 tests)
| Test Name | Component | Description | Expected Outcome |
|-----------|-----------|-------------|------------------|
| `testSaveAssetMetadata` | AssetMetadataRepository | Save entity to database | Entity persisted with ID |
| `testFindById` | AssetMetadataRepository | Retrieve by ID | Correct entity returned |
| `testFindAll` | AssetMetadataRepository | Retrieve all assets | List of assets returned |
| `testUpdateAssetMetadata` | AssetMetadataRepository | Update existing entity | Changes persisted |
| `testDeleteAssetMetadata` | AssetMetadataRepository | Delete entity | Entity removed from DB |
| `testFindByFilename` | AssetMetadataRepository | Custom query by filename | Matching assets returned |

**Test Setup**: Use `@DataJpaTest` with H2 in-memory database

#### Service Tests (20-25 tests)

##### S3Service Tests (10-12 tests)
| Test Name | Component | Description | Expected Outcome |
|-----------|-----------|-------------|------------------|
| `testUploadFileToS3` | S3Service | Upload file (mocked S3) | File uploaded, URL returned |
| `testUploadWithEmptyFile` | S3Service | Reject empty file | Exception thrown |
| `testGenerateUniqueFilename` | S3Service | Filename collision handling | Unique filename generated |
| `testUploadFailureHandling` | S3Service | S3 upload failure | Exception caught, logged |
| `testMetadataCapture` | S3Service | Capture file metadata | Size, type, timestamp captured |
| `testProfileBasedSelection` | S3Service | AWS profile check | S3 used when AWS profile active |

##### LocalStorageService Tests (5-6 tests)
| Test Name | Component | Description | Expected Outcome |
|-----------|-----------|-------------|------------------|
| `testSaveFileLocally` | LocalStorageService | Save to local filesystem | File saved in configured directory |
| `testLocalFileRetrieval` | LocalStorageService | Retrieve saved file | File contents match |
| `testDirectoryCreation` | LocalStorageService | Auto-create storage directory | Directory created if missing |

##### MessagePublisher Tests (5-7 tests)
| Test Name | Component | Description | Expected Outcome |
|-----------|-----------|-------------|------------------|
| `testPublishUploadMessage` | MessagePublisher | Publish to RabbitMQ (mocked) | Message sent to queue |
| `testMessagePayloadFormat` | MessagePublisher | Verify message structure | JSON contains file info |
| `testPublishOnlyForAWSProfile` | MessagePublisher | Conditional publishing | Message sent only when AWS active |
| `testConnectionFailureHandling` | MessagePublisher | RabbitMQ unavailable | Exception logged, upload continues |

**Test Setup**: Mock `AmazonS3`, `RabbitTemplate` using Mockito

#### Controller Tests (15-20 tests)

##### HomeController Tests (3-4 tests)
| Test Name | Component | Description | Expected Outcome |
|-----------|-----------|-------------|------------------|
| `testIndexPageRendering` | HomeController | GET / | Returns "index" view |
| `testModelAttributes` | HomeController | Check model data | Model contains expected attributes |

##### S3Controller Tests (12-16 tests)
| Test Name | Component | Description | Expected Outcome |
|-----------|-----------|-------------|------------------|
| `testUploadEndpoint` | S3Controller | POST /upload with valid file | 200 OK, upload response |
| `testUploadWithEmptyFile` | S3Controller | POST with empty file | 400 Bad Request |
| `testUploadWithNoFile` | S3Controller | POST without file parameter | 400 Bad Request |
| `testUploadLargeFile` | S3Controller | POST with large file | Handled within size limits |
| `testUploadResponseStructure` | S3Controller | Response JSON structure | Contains filename, URL, size |
| `testServiceExceptionHandling` | S3Controller | Service throws exception | 500 Internal Server Error |
| `testFileTypeValidation` | S3Controller | Upload unsupported file type | Handled appropriately |

**Test Setup**: Use `MockMvc` with `@WebMvcTest(S3Controller.class)`

#### Integration Tests (10-15 tests)
| Test Name | Component | Description | Expected Outcome |
|-----------|-----------|-------------|------------------|
| `testFullUploadFlow` | End-to-End | Upload file through API to DB | File saved, metadata in DB |
| `testS3IntegrationWithLocalStack` | S3Service | Real S3 operations (LocalStack) | File uploaded to S3 |
| `testRabbitMQIntegration` | MessagePublisher | Real RabbitMQ (Testcontainers) | Message published and consumed |
| `testDatabasePersistence` | Repository | Real PostgreSQL (Testcontainers) | Data persists across transactions |

**Test Setup**: Use `@SpringBootTest` with Testcontainers

---

### 3. asset-manager (Worker Module)

**Complexity**: Medium  
**Test Files**: 5-8  
**Estimated Test Count**: 25-35 tests

#### Service Tests (15-20 tests)

##### ThumbnailProcessor Tests (15-20 tests)
| Test Name | Component | Description | Expected Outcome |
|-----------|-----------|-------------|------------------|
| `testMessageConsumption` | ThumbnailProcessor | Consume message from queue | Message received and processed |
| `testImageDownload` | ThumbnailProcessor | Download image from S3 | Image retrieved |
| `testThumbnailGeneration` | ThumbnailProcessor | Generate thumbnail (mocked) | Thumbnail created with correct dimensions |
| `testThumbnailUpload` | ThumbnailProcessor | Upload thumbnail to S3 | Thumbnail uploaded |
| `testMetadataUpdate` | ThumbnailProcessor | Update DB with thumbnail URL | Metadata updated |
| `testInvalidImageHandling` | ThumbnailProcessor | Process corrupted image | Error logged, message acknowledged |
| `testS3DownloadFailure` | ThumbnailProcessor | S3 file not found | Exception handled gracefully |

**Test Setup**: Mock `AmazonS3`, `RabbitTemplate`, image processing library

#### Integration Tests (10-15 tests)
| Test Name | Component | Description | Expected Outcome |
|-----------|-----------|-------------|------------------|
| `testEndToEndThumbnailGeneration` | Full Flow | Message → Download → Process → Upload | Thumbnail available in S3 |
| `testRabbitMQListenerIntegration` | ThumbnailProcessor | Real RabbitMQ message | Listener triggered correctly |

---

### 4. todo-web-api-use-oracle-db

**Complexity**: Medium  
**Test Files**: 6-8  
**Estimated Test Count**: 40-50 tests

#### Model Tests (5-7 tests)
| Test Name | Component | Description | Expected Outcome |
|-----------|-----------|-------------|------------------|
| `testTodoItemCreation` | TodoItem | Create with required fields | Entity created |
| `testTitleValidation` | TodoItem | Validate title constraints | Validation errors for invalid title |
| `testDescriptionLength` | TodoItem | Validate description max length | Error for >4000 chars |
| `testDefaultValues` | TodoItem | Check default values | completed=false, priority=0 |

#### Repository Tests (8-10 tests)
| Test Name | Component | Description | Expected Outcome |
|-----------|-----------|-------------|------------------|
| `testSaveTodoItem` | TodoItemRepository | Save to database | Entity persisted |
| `testFindAll` | TodoItemRepository | Retrieve all items | List returned |
| `testFindById` | TodoItemRepository | Find by ID | Correct item returned |
| `testUpdateTodoItem` | TodoItemRepository | Update existing item | Changes persisted |
| `testDeleteTodoItem` | TodoItemRepository | Delete item | Item removed |
| `testFindByCompleted` | TodoItemRepository | Custom query by status | Filtered results |
| `testOracleVarchar2Handling` | TodoItemRepository | Oracle-specific types | VARCHAR2 handled correctly |

**Test Setup**: Use H2 database for unit tests, Testcontainers Oracle for integration

#### Service Tests (12-15 tests)
| Test Name | Component | Description | Expected Outcome |
|-----------|-----------|-------------|------------------|
| `testCreateTodoItem` | TodoService | Create new item | Item created, ID assigned |
| `testCreateWithEmptyTitle` | TodoService | Validation failure | Exception thrown |
| `testUpdateTodoItem` | TodoService | Update existing item | Item updated |
| `testUpdateNonExistent` | TodoService | Update non-existent ID | Exception thrown |
| `testDeleteTodoItem` | TodoService | Delete item | Item removed |
| `testGetAllTodoItems` | TodoService | Retrieve all items | List returned |
| `testToggleCompleted` | TodoService | Toggle completed status | Status changed |

**Test Setup**: Mock `TodoItemRepository` using Mockito

#### Controller Tests (15-18 tests)
| Test Name | Component | Description | Expected Outcome |
|-----------|-----------|-------------|------------------|
| `testGetAllEndpoint` | TodoController | GET /api/todos | 200 OK, JSON array |
| `testGetByIdEndpoint` | TodoController | GET /api/todos/{id} | 200 OK, item JSON |
| `testGetByIdNotFound` | TodoController | GET /api/todos/{invalid} | 404 Not Found |
| `testCreateEndpoint` | TodoController | POST /api/todos | 201 Created, location header |
| `testCreateWithInvalidData` | TodoController | POST with validation errors | 400 Bad Request |
| `testUpdateEndpoint` | TodoController | PUT /api/todos/{id} | 200 OK, updated item |
| `testUpdateNotFound` | TodoController | PUT /api/todos/{invalid} | 404 Not Found |
| `testDeleteEndpoint` | TodoController | DELETE /api/todos/{id} | 204 No Content |
| `testDeleteNotFound` | TodoController | DELETE /api/todos/{invalid} | 404 Not Found |

**Test Setup**: Use `MockMvc` with `@WebMvcTest(TodoController.class)`

---

### 5. rabbitmq-sender

**Complexity**: Low  
**Test Files**: 2-3  
**Estimated Test Count**: 10-15 tests

#### Service Tests (6-8 tests)
| Test Name | Component | Description | Expected Outcome |
|-----------|-----------|-------------|------------------|
| `testSendMessage` | MessageSenderService | Send message (mocked) | Message sent successfully |
| `testMessagePayload` | MessageSenderService | Verify message content | Payload formatted correctly |
| `testConnectionFailure` | MessageSenderService | RabbitMQ unavailable | Exception thrown or handled |
| `testQueueBinding` | MessageSenderService | Correct queue/exchange used | Message routed correctly |

#### Integration Tests (4-7 tests)
| Test Name | Component | Description | Expected Outcome |
|-----------|-----------|-------------|------------------|
| `testRealRabbitMQSend` | MessageSenderService | Real RabbitMQ (Testcontainers) | Message published |
| `testMessageConsumption` | End-to-End | Send and consume message | Message received by consumer |

---

### 6. jakarta-ee/student-web-app

**Complexity**: Medium  
**Test Files**: 6-8  
**Estimated Test Count**: 35-45 tests

#### Model Tests (5-7 tests)
| Test Name | Component | Description | Expected Outcome |
|-----------|-----------|-------------|------------------|
| `testStudentCreation` | Student | Create student entity | Entity created |
| `testRequiredFieldsValidation` | Student | Validate required fields | Errors for missing fields |
| `testEmailFormat` | Student | Validate email format | Error for invalid email |

#### DAO Tests (10-12 tests)
| Test Name | Component | Description | Expected Outcome |
|-----------|-----------|-------------|------------------|
| `testInsertStudent` | StudentDAO | Insert into database | Student saved with ID |
| `testFindById` | StudentDAO | Retrieve by ID | Student found |
| `testFindAll` | StudentDAO | Retrieve all students | List returned |
| `testUpdateStudent` | StudentDAO | Update student | Changes persisted |
| `testDeleteStudent` | StudentDAO | Delete student | Student removed |
| `testMyBatisMapperExecution` | StudentMapper | MyBatis XML mapper | SQL executed correctly |

**Test Setup**: Use H2 database with MyBatis configuration

#### Service Tests (10-12 tests)
| Test Name | Component | Description | Expected Outcome |
|-----------|-----------|-------------|------------------|
| `testCreateStudent` | StudentService | Create student | Student created |
| `testUpdateStudent` | StudentService | Update student | Student updated |
| `testDeleteStudent` | StudentService | Delete student | Student removed |
| `testValidationLogic` | StudentService | Business validation | Invalid data rejected |

#### Controller Tests (10-14 tests)
| Test Name | Component | Description | Expected Outcome |
|-----------|-----------|-------------|------------------|
| `testListStudentsServlet` | Servlet | GET /students | Students list rendered |
| `testCreateStudentForm` | Controller | GET /student/create | Form displayed |
| `testCreateStudentSubmit` | Controller | POST /student/create | Student created, redirect |
| `testUpdateStudentForm` | Controller | GET /student/edit/{id} | Form populated with data |
| `testUpdateStudentSubmit` | Controller | POST /student/update | Student updated |

---

### 7. ContosoUniversity (.NET)

**Complexity**: High  
**Test Files**: 12-15  
**Estimated Test Count**: 70-90 tests

#### Model Tests (10-12 tests)
| Test Name | Component | Description | Expected Outcome |
|-----------|-----------|-------------|------------------|
| `TestStudentEntityCreation` | Student | Create student | Entity created |
| `TestEnrollmentDateValidation` | Student | Validate date range (1753-9999) | Error for invalid date |
| `TestCourseCreditsValidation` | Course | Validate credits (0-5) | Error for invalid credits |
| `TestDepartmentRowVersion` | Department | Concurrency control | RowVersion populated |

#### Repository Tests (20-25 tests)
| Test Name | Component | Description | Expected Outcome |
|-----------|-----------|-------------|------------------|
| `TestAddStudent` | StudentRepository | Add student to context | Student saved |
| `TestGetStudentById` | StudentRepository | Retrieve by ID | Student found |
| `TestUpdateStudent` | StudentRepository | Update student | Changes persisted |
| `TestDeleteStudent` | StudentRepository | Delete student | Student removed |
| `TestCascadeDeleteEnrollments` | StudentRepository | Delete student with enrollments | Enrollments deleted too |
| `TestGetCoursesByDepartment` | CourseRepository | Query courses by department | Filtered results |

**Test Setup**: Use EF Core In-Memory Database

#### Service Tests (20-25 tests)
| Test Name | Component | Description | Expected Outcome |
|-----------|-----------|-------------|------------------|
| `TestCreateStudent` | StudentService | Create student | Student created |
| `TestEnrollStudentInCourse` | EnrollmentService | Enroll student | Enrollment created |
| `TestCalculateGPA` | StudentService | GPA calculation | Correct GPA computed |
| `TestDepartmentConcurrencyConflict` | DepartmentService | Handle concurrency | Conflict detected |

#### Controller Tests (20-28 tests)
| Test Name | Component | Description | Expected Outcome |
|-----------|-----------|-------------|------------------|
| `TestStudentsIndexView` | StudentsController | GET /Students | Students list view |
| `TestStudentDetailsView` | StudentsController | GET /Students/Details/{id} | Student details view |
| `TestCreateStudentGet` | StudentsController | GET /Students/Create | Create form view |
| `TestCreateStudentPost` | StudentsController | POST /Students/Create | Student created, redirect |
| `TestEditStudentGet` | StudentsController | GET /Students/Edit/{id} | Edit form populated |
| `TestEditStudentPost` | StudentsController | POST /Students/Edit/{id} | Student updated |
| `TestDeleteStudentGet` | StudentsController | GET /Students/Delete/{id} | Delete confirmation |
| `TestDeleteStudentPost` | StudentsController | POST /Students/Delete/{id} | Student deleted |

**Test Setup**: Use `WebApplicationFactory<Startup>` for integration tests

---

### 8. Malshinon (.NET)

**Complexity**: Low-Medium  
**Test Files**: 5-7  
**Estimated Test Count**: 25-35 tests

#### Model Tests (5-7 tests)
| Test Name | Component | Description | Expected Outcome |
|-----------|-----------|-------------|------------------|
| `TestEntityCreation` | Entity | Create entity | Entity created |
| `TestDataProcessorInterface` | IDataProcessor | Interface contract | Methods defined |

#### DAL Tests (8-10 tests)
| Test Name | Component | Description | Expected Outcome |
|-----------|-----------|-------------|------------------|
| `TestDatabaseConnection` | DAL | Connect to database | Connection established |
| `TestInsertData` | DAL | Insert data | Data saved |
| `TestQueryData` | DAL | Query data | Data retrieved |

#### Service Tests (12-18 tests)
| Test Name | Component | Description | Expected Outcome |
|-----------|-----------|-------------|------------------|
| `TestDataProcessorFactoryCreation` | DataProcessorFactory | Create processor by type | Correct processor returned |
| `TestCSVProcessorExecution` | CSVProcessor | Process CSV data | Data processed |
| `TestExcelProcessorExecution` | ExcelProcessor | Process Excel data | Data processed |
| `TestJSONProcessorExecution` | JSONProcessor | Process JSON data | Data processed |
| `TestInvalidTypeHandling` | DataProcessorFactory | Request unknown type | Exception thrown or null |

---

## Data Layer Tests

### Repository/DAO Test Pattern (All Projects)

#### Setup Pattern
```java
@DataJpaTest
class AssetMetadataRepositoryTest {
    
    @Autowired
    private AssetMetadataRepository repository;
    
    @Autowired
    private TestEntityManager entityManager;
    
    @BeforeEach
    void setUp() {
        // Seed test data
    }
    
    @Test
    void testFindById() {
        // Arrange
        AssetMetadata asset = new AssetMetadata(...);
        entityManager.persist(asset);
        entityManager.flush();
        
        // Act
        Optional<AssetMetadata> found = repository.findById(asset.getId());
        
        // Assert
        assertThat(found).isPresent();
        assertThat(found.get().getFilename()).isEqualTo(asset.getFilename());
    }
}
```

### Key Test Cases (All Repository Tests)
1. **Create (Save)**: Insert new entity
2. **Read (Find)**: Retrieve by ID, retrieve all, custom queries
3. **Update**: Modify existing entity
4. **Delete**: Remove entity
5. **Custom Queries**: Test named queries, criteria queries
6. **Relationships**: Test cascade operations, lazy loading
7. **Transactions**: Test rollback behavior
8. **Constraints**: Test unique constraints, foreign keys

---

## Service Layer Tests

### Service Test Pattern (All Projects)

#### Setup Pattern
```java
@ExtendWith(MockitoExtension.class)
class S3ServiceTest {
    
    @Mock
    private AmazonS3 s3Client;
    
    @Mock
    private AssetMetadataRepository repository;
    
    @InjectMocks
    private S3Service s3Service;
    
    @Test
    void testUploadFile() {
        // Arrange
        MultipartFile file = mock(MultipartFile.class);
        when(file.isEmpty()).thenReturn(false);
        when(file.getOriginalFilename()).thenReturn("test.jpg");
        when(s3Client.putObject(any())).thenReturn(new PutObjectResult());
        
        // Act
        String url = s3Service.uploadFile(file);
        
        // Assert
        assertThat(url).isNotNull();
        verify(s3Client).putObject(any());
    }
}
```

### Key Test Cases (All Service Tests)
1. **Happy Path**: Successful execution with valid inputs
2. **Validation**: Reject invalid inputs
3. **Exception Handling**: Handle downstream failures
4. **Business Logic**: Verify business rules applied
5. **Mocking**: All dependencies mocked, no real I/O
6. **State Changes**: Verify state transitions

---

## API/Controller Layer Tests

### Controller Test Pattern (All Projects)

#### Setup Pattern
```java
@WebMvcTest(S3Controller.class)
class S3ControllerTest {
    
    @Autowired
    private MockMvc mockMvc;
    
    @MockBean
    private S3Service s3Service;
    
    @Test
    void testUploadEndpoint() throws Exception {
        // Arrange
        MockMultipartFile file = new MockMultipartFile(
            "file", "test.jpg", "image/jpeg", "content".getBytes()
        );
        when(s3Service.uploadFile(any())).thenReturn("http://s3.../test.jpg");
        
        // Act & Assert
        mockMvc.perform(multipart("/upload").file(file))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.url").value("http://s3.../test.jpg"));
    }
}
```

### Key Test Cases (All Controller Tests)
1. **HTTP Methods**: GET, POST, PUT, DELETE
2. **Status Codes**: 200, 201, 400, 404, 500
3. **Request Validation**: Invalid inputs return 400
4. **Response Format**: JSON structure correct
5. **Authentication/Authorization**: Access control (if applicable)
6. **Error Handling**: Exceptions mapped to HTTP errors

---

## Integration Tests

### Database Integration Pattern
```java
@SpringBootTest
@Testcontainers
class DatabaseIntegrationTest {
    
    @Container
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:15");
    
    @Autowired
    private AssetMetadataRepository repository;
    
    @DynamicPropertySource
    static void configureProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", postgres::getJdbcUrl);
    }
    
    @Test
    void testPersistence() {
        // Test with real database
    }
}
```

### Messaging Integration Pattern
```java
@SpringBootTest
@Testcontainers
class RabbitMQIntegrationTest {
    
    @Container
    static RabbitMQContainer rabbitmq = new RabbitMQContainer("rabbitmq:3-management");
    
    @Autowired
    private MessagePublisher publisher;
    
    @Test
    void testMessagePublishing() {
        // Test with real RabbitMQ
    }
}
```

---

## End-to-End Tests

### E2E Test Scenarios

#### asset-manager E2E
| Scenario | Steps | Expected Outcome |
|----------|-------|------------------|
| File Upload Flow | 1. POST file to /upload<br>2. Verify DB entry<br>3. Verify S3 upload<br>4. Verify RabbitMQ message | File uploaded, metadata saved, message published |
| Thumbnail Generation Flow | 1. Upload file<br>2. Worker consumes message<br>3. Thumbnail generated<br>4. Thumbnail uploaded | Thumbnail available in S3 |

#### todo-web-api E2E
| Scenario | Steps | Expected Outcome |
|----------|-------|------------------|
| CRUD Workflow | 1. Create todo<br>2. Retrieve todo<br>3. Update todo<br>4. Delete todo | All operations successful |
| Validation Flow | 1. POST invalid todo<br>2. Verify error response | 400 with validation errors |

---

## Test Data Management

### Test Data Strategies
1. **In-Memory Databases**: H2 for fast unit tests
2. **Testcontainers**: Docker-based real databases for integration tests
3. **Test Fixtures**: Reusable test data builders
4. **Database Seeding**: SQL scripts for initial data
5. **Data Cleanup**: `@Transactional` or `@DirtiesContext` for isolation

### Example Test Data Builder
```java
public class AssetMetadataTestBuilder {
    private String filename = "test.jpg";
    private Long size = 1024L;
    
    public AssetMetadataTestBuilder withFilename(String filename) {
        this.filename = filename;
        return this;
    }
    
    public AssetMetadata build() {
        return new AssetMetadata(filename, size, ...);
    }
}
```

---

## Performance and Load Tests

### Performance Test Cases
| Project | Test Case | Load | Expected Response Time |
|---------|-----------|------|------------------------|
| asset-manager | File upload | 100 concurrent users | <2s per upload |
| todo-web-api | GET all todos | 500 req/s | <100ms |
| ContosoUniversity | Student search | 200 concurrent users | <500ms |

### Load Testing Tools
- **JMeter**: HTTP load testing
- **Gatling**: Scenario-based load testing
- **k6**: Modern load testing (JavaScript)

---

## Test Execution Strategy

### CI/CD Pipeline Integration
```yaml
# Example GitHub Actions
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - name: Run Unit Tests
        run: mvn test
      - name: Run Integration Tests
        run: mvn verify -P integration-tests
      - name: Upload Coverage
        run: bash <(curl -s https://codecov.io/bash)
```

### Test Execution Order
1. **Commit**: Run unit tests (fast feedback)
2. **PR**: Run unit + integration tests
3. **Merge to main**: Run full test suite + E2E
4. **Nightly**: Run performance/load tests

---

## Coverage and Quality Metrics

### Coverage Targets
- **Overall**: ≥80%
- **Service Layer**: ≥90% (critical business logic)
- **Controller Layer**: ≥80%
- **Model Layer**: ≥70% (mostly DTOs)

### Quality Gates
- All tests pass
- No critical SonarQube issues
- Code coverage above threshold
- No security vulnerabilities (Snyk, OWASP)

---

**Related Documentation:**
- [Component Migration Order](component-order.md) - Migration sequence guides test creation order
- [Validation Criteria](validation-criteria.md) - Acceptance criteria for each test phase
- [Program Structure](../reference/program-structure.md) - Component details for test planning
- [Technical Debt Report](../technical-debt-report.md) - Test coverage gaps and improvements
