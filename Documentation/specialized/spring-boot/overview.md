# Spring Boot - Framework Overview and Usage

**Analysis Date:** December 2024  
**Spring Boot Versions Detected:** 2.7.18, 3.2.4  
**Projects Using Spring Boot:** asset-manager, todo-web-api, rabbitmq-sender

---

## Table of Contents
- [Spring Boot Projects](#spring-boot-projects)
- [Spring Boot 2.7.18 (asset-manager)](#spring-boot-2718-asset-manager)
- [Spring Boot 3.2.4 (todo-web-api)](#spring-boot-324-todo-web-api)
- [Key Spring Technologies](#key-spring-technologies)
- [Migration Considerations](#migration-considerations)

---

## Spring Boot Projects

### Version Matrix
| Project | Spring Boot Version | Java Version | Key Dependencies |
|---------|-------------------|--------------|------------------|
| **asset-manager** (web + worker) | 2.7.18 | Java 8 | Web, JPA, AMQP, Thymeleaf, AWS SDK |
| **todo-web-api** | 3.2.4 | Java 17 | Web, JPA, Validation, Oracle JDBC |
| **rabbitmq-sender** | 2.x (inherited) | Java 8+ | AMQP |

---

## Spring Boot 2.7.18 (asset-manager)

### Project Structure
- **Multi-module Maven project**
- **Parent POM**: Defines Spring Boot version and common dependencies
- **Modules**: 
  - `web`: REST API and file upload
  - `worker`: Background message processing

### Spring Boot Starters Used

#### Web Module
| Starter | Purpose | Key Classes |
|---------|---------|-------------|
| `spring-boot-starter-web` | REST API, Spring MVC | `S3Controller`, `HomeController` |
| `spring-boot-starter-thymeleaf` | HTML templating | `index.html` view |
| `spring-boot-starter-data-jpa` | Database ORM | `AssetMetadataRepository` |
| `spring-boot-starter-amqp` | RabbitMQ messaging | `MessagePublisher` |
| `spring-boot-devtools` | Development tools | Hot reload |
| `spring-boot-starter-test` | Testing framework | JUnit, MockMvc |

#### Worker Module
| Starter | Purpose | Key Classes |
|---------|---------|-------------|
| `spring-boot-starter-amqp` | Message consumption | `ThumbnailProcessor` |
| `spring-boot-starter-data-jpa` | Database access | Repository integration |

### Configuration Files

#### application.yml (Web)
```yaml
spring:
  profiles:
    active: ${SPRING_PROFILES_ACTIVE:local}
  datasource:
    url: jdbc:postgresql://localhost:5432/assets
    username: ${DB_USERNAME}
    password: ${DB_PASSWORD}
  jpa:
    hibernate:
      ddl-auto: update
    show-sql: true
  rabbitmq:
    host: ${RABBITMQ_HOST:localhost}
    port: 5672
  servlet:
    multipart:
      max-file-size: 10MB
      max-request-size: 10MB

aws:
  s3:
    bucket-name: ${AWS_S3_BUCKET}
    region: ${AWS_REGION:us-east-1}

storage:
  local-path: ${LOCAL_STORAGE_PATH:./uploads}
```

### Application Entry Point

```java
@SpringBootApplication
public class AssetsManagerApplication {
    public static void main(String[] args) {
        SpringApplication.run(AssetsManagerApplication.class, args);
    }
}
```

### Profile-Based Configuration
- **aws profile**: Uses AWS S3 + RabbitMQ
- **local profile**: Uses local filesystem, no messaging

### Dependency Injection Patterns

#### Service Layer
```java
@Service
public class S3Service {
    @Autowired
    private AmazonS3 s3Client;
    
    @Autowired
    private AssetMetadataRepository repository;
    
    // Business logic
}
```

#### Controller Layer
```java
@Controller
public class S3Controller {
    @Autowired
    private StorageService storageService;  // Profile-based injection
    
    @PostMapping("/upload")
    public ResponseEntity<UploadResponse> upload(@RequestParam MultipartFile file) {
        // Handle upload
    }
}
```

### JPA Configuration

#### Entity Example
```java
@Entity
@Table(name = "asset_metadata")
public class AssetMetadata {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @Column(nullable = false)
    private String filename;
    
    @Column(name = "uploaded_at")
    private LocalDateTime uploadedAt;
    
    @PrePersist
    public void prePersist() {
        uploadedAt = LocalDateTime.now();
    }
}
```

#### Repository Interface
```java
public interface AssetMetadataRepository extends JpaRepository<AssetMetadata, Long> {
    List<AssetMetadata> findByFilename(String filename);
}
```

### RabbitMQ Integration

#### Message Publishing (Web)
```java
@Component
public class MessagePublisher {
    @Autowired
    private RabbitTemplate rabbitTemplate;
    
    public void publishFileUploadEvent(FileMetadata metadata) {
        rabbitTemplate.convertAndSend("file-upload-queue", metadata);
    }
}
```

#### Message Consumption (Worker)
```java
@Component
public class ThumbnailProcessor {
    @RabbitListener(queues = "file-upload-queue")
    public void processFile(FileMetadata metadata) {
        // Generate thumbnail
    }
}
```

### Testing Configuration

```java
@SpringBootTest
@AutoConfigureMockMvc
class S3ControllerTest {
    @Autowired
    private MockMvc mockMvc;
    
    @MockBean
    private S3Service s3Service;
    
    @Test
    void testUpload() throws Exception {
        // Test implementation
    }
}
```

---

## Spring Boot 3.2.4 (todo-web-api)

### Key Differences from 2.7.18
- **Jakarta EE namespace**: `javax.*` → `jakarta.*`
- **Java 17+ required**: Minimum Java version increased
- **Native compilation support**: GraalVM native image
- **Improved observability**: Micrometer tracing

### Spring Boot Starters Used

| Starter | Purpose | Key Classes |
|---------|---------|-------------|
| `spring-boot-starter-web` | REST API | `TodoController` |
| `spring-boot-starter-data-jpa` | ORM with Oracle | `TodoItemRepository` |
| `spring-boot-starter-validation` | Bean Validation | `@Valid` annotations |
| `spring-boot-starter-test` | Testing | JUnit 5, MockMvc |

### Configuration (application.properties)
```properties
spring.application.name=todo-web-api

# Oracle Database
spring.datasource.url=jdbc:oracle:thin:@localhost:1521:ORCL
spring.datasource.username=${ORACLE_USERNAME}
spring.datasource.password=${ORACLE_PASSWORD}
spring.datasource.driver-class-name=oracle.jdbc.OracleDriver

# JPA Configuration
spring.jpa.hibernate.ddl-auto=update
spring.jpa.show-sql=true
spring.jpa.properties.hibernate.dialect=org.hibernate.dialect.OracleDialect

# Server Configuration
server.port=8080
```

### REST Controller Pattern

```java
@RestController
@RequestMapping("/api/todos")
public class TodoController {
    @Autowired
    private TodoService todoService;
    
    @GetMapping
    public List<TodoItem> getAllTodos() {
        return todoService.getAllTodos();
    }
    
    @PostMapping
    public ResponseEntity<TodoItem> createTodo(@Valid @RequestBody TodoItem todo) {
        TodoItem created = todoService.createTodo(todo);
        return ResponseEntity.status(HttpStatus.CREATED).body(created);
    }
    
    @GetMapping("/{id}")
    public ResponseEntity<TodoItem> getTodoById(@PathVariable Long id) {
        return todoService.getTodoById(id)
            .map(ResponseEntity::ok)
            .orElse(ResponseEntity.notFound().build());
    }
}
```

### Validation with Bean Validation 3.0

```java
@Entity
@Table(name = "TODO_ITEMS")
public class TodoItem {
    @Id
    @GeneratedValue(strategy = GenerationType.SEQUENCE)
    private Long id;
    
    @NotBlank(message = "Title is required")
    @Size(max = 200, message = "Title max 200 characters")
    @Column(name = "TITLE", length = 200, nullable = false)
    private String title;
    
    @Size(max = 4000, message = "Description max 4000 characters")
    @Column(name = "DESCRIPTION", length = 4000)
    private String description;
}
```

### Oracle-Specific Features

```java
@Service
public class TodoService {
    @PersistenceContext
    private EntityManager entityManager;
    
    // Oracle SYSDATE function
    @Transactional
    public List<TodoItem> getOverdueTasks() {
        String sql = "SELECT * FROM TODO_ITEMS " +
                     "WHERE DUE_DATE < SYSDATE " +
                     "AND COMPLETED = 0 " +
                     "ORDER BY PRIORITY DESC";
        Query query = entityManager.createNativeQuery(sql, TodoItem.class);
        return query.getResultList();
    }
    
    // Oracle VARCHAR2 search with DBMS_LOB
    @Transactional
    public List<TodoItem> searchWithOracleVarchar2(String term) {
        String sql = "SELECT * FROM TODO_ITEMS " +
                     "WHERE DBMS_LOB.INSTR(TITLE, :term) > 0";
        Query query = entityManager.createNativeQuery(sql, TodoItem.class)
                                    .setParameter("term", term);
        return query.getResultList();
    }
}
```

---

## Key Spring Technologies

### Spring Data JPA

**Purpose**: Simplify database access with repository pattern

**Key Features**:
- Automatic CRUD operations
- Query methods by naming convention
- Custom queries with `@Query`
- Pagination and sorting

**Example**:
```java
public interface TodoItemRepository extends JpaRepository<TodoItem, Long> {
    // Automatic implementation by Spring
    List<TodoItem> findByCompleted(boolean completed);
    
    List<TodoItem> findByPriorityGreaterThanEqual(int priority);
    
    @Query("SELECT t FROM TodoItem t WHERE t.title LIKE %:keyword% OR t.description LIKE %:keyword%")
    List<TodoItem> findByKeyword(@Param("keyword") String keyword);
}
```

### Spring AMQP (RabbitMQ)

**Purpose**: Message-driven architecture for async processing

**Key Features**:
- Declarative message listeners
- Automatic JSON serialization
- Connection pooling
- Retry and error handling

**Configuration**:
```java
@Configuration
public class RabbitMQConfig {
    @Bean
    public Queue fileUploadQueue() {
        return new Queue("file-upload-queue", true);  // durable
    }
    
    @Bean
    public TopicExchange exchange() {
        return new TopicExchange("file-events");
    }
    
    @Bean
    public Binding binding(Queue queue, TopicExchange exchange) {
        return BindingBuilder.bind(queue).to(exchange).with("file.upload");
    }
}
```

### Spring MVC

**Purpose**: Web framework for REST APIs and web applications

**Key Features**:
- Request mapping annotations
- Content negotiation (JSON, XML)
- Exception handling
- Validation integration

**Exception Handling**:
```java
@ControllerAdvice
public class GlobalExceptionHandler {
    @ExceptionHandler(EntityNotFoundException.class)
    public ResponseEntity<ErrorResponse> handleNotFound(EntityNotFoundException ex) {
        return ResponseEntity.status(HttpStatus.NOT_FOUND)
            .body(new ErrorResponse(ex.getMessage()));
    }
    
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<Map<String, String>> handleValidation(MethodArgumentNotValidException ex) {
        Map<String, String> errors = new HashMap<>();
        ex.getBindingResult().getFieldErrors().forEach(error -> 
            errors.put(error.getField(), error.getDefaultMessage())
        );
        return ResponseEntity.badRequest().body(errors);
    }
}
```

### Spring Boot Actuator (if enabled)

**Purpose**: Production-ready features (health checks, metrics)

**Endpoints**:
- `/actuator/health` - Application health
- `/actuator/metrics` - Application metrics
- `/actuator/info` - Application info

---

## Migration Considerations

### Spring Boot 2.7 → 3.x Migration Path

#### Namespace Changes
```java
// Old (Spring Boot 2.7)
import javax.persistence.*;
import javax.validation.*;

// New (Spring Boot 3.x)
import jakarta.persistence.*;
import jakarta.validation.*;
```

#### Java Version
- **Spring Boot 2.7**: Java 8, 11, 17
- **Spring Boot 3.x**: Java 17+ required

#### Dependency Updates
```xml
<!-- Old -->
<dependency>
    <groupId>javax.validation</groupId>
    <artifactId>validation-api</artifactId>
</dependency>

<!-- New -->
<dependency>
    <groupId>jakarta.validation</groupId>
    <artifactId>jakarta.validation-api</artifactId>
</dependency>
```

### Technical Debt (asset-manager)

**Issue**: Using Spring Boot 2.7.18 with Java 8  
**Risk**: Spring Boot 2.7 reaches end-of-life in November 2024  
**Recommendation**: Upgrade to Spring Boot 3.x and Java 17

**Impact**:
- Namespace migration (`javax` → `jakarta`)
- Java 8 → 17 (language features, performance)
- Dependency updates (third-party libraries)

### Best Practices Observed

✅ **Good Practices**:
- Profile-based configuration for environments
- Repository pattern for data access
- Service layer for business logic
- Exception handling with `@ControllerAdvice`
- Integration testing with `@SpringBootTest`

⚠️ **Areas for Improvement**:
- Add Spring Boot Actuator for observability
- Implement API versioning
- Add OpenAPI/Swagger documentation
- Consider reactive programming for high-throughput scenarios
- Implement circuit breakers for external services (AWS S3, RabbitMQ)

---

**Related Documentation:**
- [Program Structure](../../reference/program-structure.md) - Detailed class and package structure
- [Dependencies](../../architecture/dependencies.md) - Complete dependency tree
- [Technical Debt Report](../../technical-debt-report.md) - Spring Boot upgrade recommendations
- [AWS Integration](../cloud-services/aws-integration.md) - AWS SDK usage with Spring Boot
- [Messaging Patterns](../messaging/queue-patterns.md) - RabbitMQ integration details
