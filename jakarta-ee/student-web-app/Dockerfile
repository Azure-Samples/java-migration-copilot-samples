FROM open-liberty:25.0.0.7-kernel-slim-java17-openj9

# Copy Liberty configuration
COPY --chown=1001:0 liberty_config/server-docker.xml /config/server.xml
COPY --chown=1001:0 liberty_config/server-docker.env /config/server.env

# Copy application
COPY --chown=1001:0 dist/OpenLibertyApp.war /config/apps/

# Create directories for libraries
RUN mkdir -p /opt/ol/wlp/usr/shared/resources/mysql

# Copy MySQL connector for JDBC driver
COPY --chown=1001:0 mysql-connector/mysql-connector-j-8.0.33.jar /opt/ol/wlp/usr/shared/resources/mysql/

# Configure Liberty features
RUN features.sh

# Expose ports
EXPOSE 9080 9443

# Set environment variables for Docker environment
ENV WLP_USER_DIR=/opt/ol/wlp/usr \
    SERVER_NAME=defaultServer \
    MYSQL_LIB_DIR=/opt/ol/wlp/usr/shared/resources/mysql \
    LIBERTY_SERVER_DIR=/config \
    KEYSTORE_LOCATION=/config/resources/security/key.p12 \
    KEYSTORE_PASSWORD=defaultPassword \
    TRUSTED_KEYSTORE_LOCATION=/config/resources/security/trust.p12 \
    TRUSTED_KEYSTORE_PASSWORD=defaultPassword \
    LTPA_KEY_FILE_SFA=/config/resources/security/ltpa.keys \
    LTPA_KEY_PASSWORD_SFA=defaultPassword \
    JDBC_DRIVER_CLASS=com.mysql.cj.jdbc.Driver
