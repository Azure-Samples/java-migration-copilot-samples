    DROP TABLE IF EXISTS student_profiles;

    CREATE TABLE student_profiles (
        id INT AUTO_INCREMENT PRIMARY KEY,
        name VARCHAR(255),
        email VARCHAR(255),
        major VARCHAR(255)
    );