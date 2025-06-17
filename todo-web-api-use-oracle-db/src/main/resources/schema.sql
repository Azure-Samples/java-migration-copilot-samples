-- Migrated from Oracle to PostgreSQL according to SQL check item 1: Use lowercase for identifiers (like table and column names) and data type (like varchar), use uppercase for SQL keywords (like SELECT, FROM, WHERE).
-- Migrated from Oracle to PostgreSQL according to SQL check item 2: Replace Oracle-specific data types with PostgreSQL equivalents (NUMBER→INTEGER, VARCHAR2→VARCHAR, etc).
-- Migrated from Oracle to PostgreSQL according to SQL check item 10: Replace GENERATED ALWAYS AS IDENTITY with SERIAL for auto-incrementing keys.
-- First, try to drop the table if it exists using a simple DROP statement
-- Spring will continue if this fails because of continue-on-error=true in application.yaml
DROP TABLE todo_items;

-- Create the todo_items table with PostgreSQL compatible data types
CREATE TABLE todo_items (
    id serial PRIMARY KEY, -- Migrated from Oracle to PostgreSQL according to SQL check item 10
    title varchar(200) NOT NULL, -- Migrated from Oracle to PostgreSQL according to SQL check item 2
    description varchar(4000), -- Migrated from Oracle to PostgreSQL according to SQL check item 2
    completed integer DEFAULT 0 NOT NULL, -- Migrated from Oracle to PostgreSQL according to SQL check item 2
    priority integer DEFAULT 1 NOT NULL, -- Migrated from Oracle to PostgreSQL according to SQL check item 2
    due_date timestamp, -- Migrated from Oracle to PostgreSQL according to SQL check item 2
    created_at timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL, -- Migrated from Oracle to PostgreSQL according to SQL check item 2
    updated_at timestamp DEFAULT CURRENT_TIMESTAMP -- Migrated from Oracle to PostgreSQL according to SQL check item 2
);

-- Create indexes for better performance
CREATE INDEX idx_todo_completed ON todo_items(completed); -- Migrated from Oracle to PostgreSQL according to SQL check item 1
CREATE INDEX idx_todo_priority ON todo_items(priority); -- Migrated from Oracle to PostgreSQL according to SQL check item 1
CREATE INDEX idx_todo_due_date ON todo_items(due_date); -- Migrated from Oracle to PostgreSQL according to SQL check item 1

-- Comments
COMMENT ON TABLE todo_items IS 'Stores todo items and their details'; -- Migrated from Oracle to PostgreSQL according to SQL check item 1
COMMENT ON COLUMN todo_items.id IS 'Unique identifier for the todo item'; -- Migrated from Oracle to PostgreSQL according to SQL check item 1
COMMENT ON COLUMN todo_items.title IS 'Title of the todo item'; -- Migrated from Oracle to PostgreSQL according to SQL check item 1
COMMENT ON COLUMN todo_items.description IS 'Detailed description of the todo item'; -- Migrated from Oracle to PostgreSQL according to SQL check item 1
COMMENT ON COLUMN todo_items.completed IS 'Flag indicating if the todo item is completed (1) or not (0)'; -- Migrated from Oracle to PostgreSQL according to SQL check item 1
COMMENT ON COLUMN todo_items.priority IS 'Priority level of the todo item (higher number means higher priority)'; -- Migrated from Oracle to PostgreSQL according to SQL check item 1
COMMENT ON COLUMN todo_items.due_date IS 'Date and time when the todo item is due'; -- Migrated from Oracle to PostgreSQL according to SQL check item 1
COMMENT ON COLUMN todo_items.created_at IS 'Timestamp when the todo item was created'; -- Migrated from Oracle to PostgreSQL according to SQL check item 1
COMMENT ON COLUMN todo_items.updated_at IS 'Timestamp when the todo item was last updated'; -- Migrated from Oracle to PostgreSQL according to SQL check item 1
