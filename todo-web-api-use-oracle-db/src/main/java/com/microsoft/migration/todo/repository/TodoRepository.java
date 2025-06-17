package com.microsoft.migration.todo.repository;

import com.microsoft.migration.todo.model.TodoItem;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface TodoRepository extends JpaRepository<TodoItem, Long> {

    // Custom query methods
    List<TodoItem> findByCompleted(boolean completed);

    List<TodoItem> findByPriorityGreaterThanEqual(int priority);

    // Migrated from Oracle to PostgreSQL according to java check item 1: Convert all table and column names from uppercase to lowercase in JPA annotations.
    // Migrated from Oracle to PostgreSQL according to java check item 6: Use lowercase for identifiers and uppercase for SQL keywords in SQL string literals.
    // Migrated from Oracle to PostgreSQL according to java check item 9999: Replace Oracle string concatenation with PostgreSQL CONCAT function.
    @Query(value = "SELECT * FROM todo_items WHERE CONCAT('%', :keyword, '%') ILIKE title OR CONCAT('%', :keyword, '%') ILIKE description",
           nativeQuery = true)
    List<TodoItem> findByKeyword(String keyword);

    // Migrated from Oracle to PostgreSQL according to java check item 1: Convert all table and column names from uppercase to lowercase in JPA annotations.
    // Migrated from Oracle to PostgreSQL according to java check item 6: Use lowercase for identifiers and uppercase for SQL keywords in SQL string literals.
    // Migrated from Oracle to PostgreSQL according to java check item 18: Replace ROWNUM pagination with LIMIT/OFFSET in native SQL queries.
    @Query(value = "SELECT * FROM todo_items WHERE priority > :priority ORDER BY created_at DESC LIMIT :limit",
           nativeQuery = true)
    List<TodoItem> findTopPriorityTasks(int priority, int limit);
}
