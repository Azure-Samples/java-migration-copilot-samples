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

    // Oracle specific SQL with VARCHAR2
    @Query(value = "SELECT * FROM TODO_ITEMS WHERE TITLE LIKE '%' || :keyword || '%' OR DESCRIPTION LIKE '%' || :keyword || '%'",
           nativeQuery = true)
    List<TodoItem> findByKeyword(String keyword);

    // Another Oracle specific query showing off more Oracle SQL features
    @Query(value = "SELECT * FROM TODO_ITEMS WHERE PRIORITY > :priority AND ROWNUM <= :limit ORDER BY CREATED_AT DESC",
           nativeQuery = true)
    List<TodoItem> findTopPriorityTasks(int priority, int limit);
}
