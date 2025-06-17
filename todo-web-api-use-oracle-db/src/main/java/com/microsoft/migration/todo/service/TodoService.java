package com.microsoft.migration.todo.service;

import com.microsoft.migration.todo.model.TodoItem;
import com.microsoft.migration.todo.repository.TodoRepository;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import jakarta.persistence.Query;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Service
public class TodoService {

    @Autowired
    private TodoRepository todoRepository;

    @PersistenceContext
    private EntityManager entityManager;

    public List<TodoItem> getAllTodos() {
        return todoRepository.findAll();
    }

    public Optional<TodoItem> getTodoById(Long id) {
        return todoRepository.findById(id);
    }

    public List<TodoItem> getTodosByCompleted(boolean completed) {
        return todoRepository.findByCompleted(completed);
    }

    public List<TodoItem> getHighPriorityTodos(int minPriority) {
        return todoRepository.findByPriorityGreaterThanEqual(minPriority);
    }

    public List<TodoItem> searchTodos(String keyword) {
        return todoRepository.findByKeyword(keyword);
    }

    public List<TodoItem> getTopPriorityTasks(int priority, int limit) {
        return todoRepository.findTopPriorityTasks(priority, limit);
    }

    public TodoItem createTodo(TodoItem todo) {
        return todoRepository.save(todo);
    }

    public TodoItem updateTodo(Long id, TodoItem todoDetails) {
        TodoItem todo = todoRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Todo not found with id " + id));

        todo.setTitle(todoDetails.getTitle());
        todo.setDescription(todoDetails.getDescription());
        todo.setCompleted(todoDetails.isCompleted());
        todo.setPriority(todoDetails.getPriority());
        todo.setDueDate(todoDetails.getDueDate());

        return todoRepository.save(todo);
    }

    public void deleteTodo(Long id) {
        todoRepository.deleteById(id);
    }

    // Migrated from Oracle to PostgreSQL according to java check item 1, 3, 6, 9999: Table and column names to lowercase, replaced SYSDATE with CURRENT_DATE, SQL keywords uppercase, and removed Oracle-specific syntax.
    @Transactional
    public List<TodoItem> getOverdueTasks() {
        String postgresSql = "SELECT * FROM todo_items " +
                             "WHERE due_date < CURRENT_DATE " +
                             "AND completed = 0 " +
                             "ORDER BY priority DESC, due_date ASC";

        Query query = entityManager.createNativeQuery(postgresSql, TodoItem.class);
        return query.getResultList();
    }

    // Migrated from Oracle to PostgreSQL according to java check item 1, 3, 6, 9999: Table and column names to lowercase, replaced SYSTIMESTAMP with CURRENT_TIMESTAMP, SQL keywords uppercase, and removed Oracle-specific syntax.
    @Transactional
    public void updateTasksWithOracle(LocalDateTime cutoffDate, int newPriority) {
        String postgresSql = "UPDATE todo_items " +
                             "SET priority = :newPriority, " +
                             "updated_at = CURRENT_TIMESTAMP " +
                             "WHERE due_date < :cutoffDate " +
                             "AND completed = 0";

        Query query = entityManager.createNativeQuery(postgresSql)
                                    .setParameter("newPriority", newPriority)
                                    .setParameter("cutoffDate", cutoffDate);

        query.executeUpdate();
    }

    // Migrated from Oracle to PostgreSQL according to java check item 1, 3, 6, 9999: Table and column names to lowercase, replaced DBMS_LOB.INSTR with POSITION, SQL keywords uppercase, and removed Oracle-specific syntax.
    @Transactional
    public List<TodoItem> searchWithOracleVarchar2(String searchTerm) {
        String postgresSql = "SELECT * FROM todo_items " +
                             "WHERE POSITION(:searchTerm IN title) > 0 " +
                             "OR POSITION(:searchTerm IN description) > 0";

        Query query = entityManager.createNativeQuery(postgresSql, TodoItem.class)
                                    .setParameter("searchTerm", searchTerm);

        return query.getResultList();
    }
}
