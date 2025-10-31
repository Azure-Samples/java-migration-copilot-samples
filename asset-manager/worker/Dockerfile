# Multi-stage build for Java 21 Spring Boot worker application
FROM maven:3.9.9-eclipse-temurin-21-alpine AS build

# Set working directory
WORKDIR /app

# Copy parent pom.xml first
COPY pom.xml ./pom.xml

# Copy all modules structure for proper Maven multi-module build
COPY web/pom.xml ./web/pom.xml
COPY worker/pom.xml ./worker/pom.xml
COPY worker/src ./worker/src

# Create empty web src directory to satisfy Maven
RUN mkdir -p ./web/src/main/java ./web/src/main/resources

# Build the worker module
RUN mvn clean package -pl worker -am -DskipTests

# Runtime stage
FROM eclipse-temurin:21-jre-alpine

# Install curl for health checks
RUN apk add --no-cache curl

# Create non-root user for security
RUN addgroup -g 1001 -S appgroup && \
    adduser -S appuser -u 1001 -G appgroup

# Set working directory
WORKDIR /app

# Copy the built jar from build stage
COPY --from=build /app/worker/target/*.jar app.jar

# Change ownership to non-root user
RUN chown -R appuser:appgroup /app

# Switch to non-root user
USER appuser

# Expose port for health checks
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=30s --retries=3 \
    CMD curl -f http://localhost:8080/actuator/health || exit 1

# Set JVM options for container environment
ENV JAVA_OPTS="-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0 -XX:+UseG1GC"

# Run the application
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]