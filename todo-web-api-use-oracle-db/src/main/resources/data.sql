-- Migrated from Oracle to PostgreSQL according to SQL check item 1: Use lowercase for identifiers (like table and column names) and data type (like varchar), use uppercase for SQL keywords (like SELECT, FROM, WHERE).
-- Migrated from Oracle to PostgreSQL according to SQL check item 9999: Migrated Oracle-specific SYSTIMESTAMP and INTERVAL expressions to PostgreSQL equivalents (CURRENT_TIMESTAMP and INTERVAL syntax).
INSERT INTO todo_items (title, description, completed, priority, due_date, created_at, updated_at)
VALUES ('Complete project documentation', 'Write comprehensive documentation for the Todo API project', 0, 5, CURRENT_TIMESTAMP + INTERVAL '7 days', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

INSERT INTO todo_items (title, description, completed, priority, due_date, created_at, updated_at)
VALUES ('Fix UI bugs', 'Address the UI bugs reported in the frontend application', 0, 8, CURRENT_TIMESTAMP + INTERVAL '2 days', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

INSERT INTO todo_items (title, description, completed, priority, due_date, created_at, updated_at)
VALUES ('Review pull requests', 'Review and provide feedback on pending pull requests', 1, 7, CURRENT_TIMESTAMP - INTERVAL '1 days', CURRENT_TIMESTAMP - INTERVAL '2 days', CURRENT_TIMESTAMP - INTERVAL '1 days');

INSERT INTO todo_items (title, description, completed, priority, due_date, created_at, updated_at)
VALUES ('Prepare for demo', 'Prepare slides and setup environment for the upcoming demo', 0, 9, CURRENT_TIMESTAMP + INTERVAL '3 days', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

INSERT INTO todo_items (title, description, completed, priority, due_date, created_at, updated_at)
VALUES ('Update dependencies', 'Update project dependencies to the latest versions', 1, 4, CURRENT_TIMESTAMP - INTERVAL '3 days', CURRENT_TIMESTAMP - INTERVAL '4 days', CURRENT_TIMESTAMP - INTERVAL '3 days');

INSERT INTO todo_items (title, description, completed, priority, due_date, created_at, updated_at)
VALUES ('Implement search functionality', 'Add search functionality to the application', 0, 6, CURRENT_TIMESTAMP + INTERVAL '5 days', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

INSERT INTO todo_items (title, description, completed, priority, due_date, created_at, updated_at)
VALUES ('Write unit tests', 'Increase test coverage with additional unit tests', 0, 7, CURRENT_TIMESTAMP + INTERVAL '4 days', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

INSERT INTO todo_items (title, description, completed, priority, due_date, created_at, updated_at)
VALUES ('Deploy to production', 'Deploy the latest changes to the production environment', 0, 10, CURRENT_TIMESTAMP + INTERVAL '10 days', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

INSERT INTO todo_items (title, description, completed, priority, due_date, created_at, updated_at)
VALUES ('Create user documentation', 'Write user guides and API documentation', 0, 5, CURRENT_TIMESTAMP + INTERVAL '8 days', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

INSERT INTO todo_items (title, description, completed, priority, due_date, created_at, updated_at)
VALUES ('Code review', 'Perform code review for the recent changes', 1, 6, CURRENT_TIMESTAMP - INTERVAL '2 days', CURRENT_TIMESTAMP - INTERVAL '3 days', CURRENT_TIMESTAMP - INTERVAL '2 days');

COMMIT;
