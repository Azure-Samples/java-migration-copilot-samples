1. **Install dependencies:**
   - Java 11+
   - Apache Ant
   - MySQL 8.0

2. **Setup database:**
   ```bash
   # Create database and user
   mysql -u root -p
   CREATE DATABASE studentdb;
   CREATE USER 'student'@'localhost' IDENTIFIED BY 'studentpass';
   GRANT ALL PRIVILEGES ON studentdb.* TO 'student'@'localhost';
   
   # Run table creation script
   mysql -u student -p studentdb < database/create_table.sql
   ```

3. **Configure MySQL connector:**
   ```bash
   mkdir -p mysql-connector
   # Download MySQL Connector/J 8.0.33 to mysql-connector/mysql-connector-j-8.0.33.jar
   ```

4. **Build and deploy:**
   ```bash
   ant clean war
   # Deploy OpenLibertyApp.war to your Open Liberty server
   ```