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

    // Demonstrating Oracle-specific SQL with direct JDBC execution
    @Transactional
    public List<TodoItem> getOverdueTasks() {
        String oracleSpecificSql = "SELECT * FROM TODO_ITEMS " +
                                   "WHERE DUE_DATE < SYSDATE " +
                                   "AND COMPLETED = 0 " +
                                   "ORDER BY PRIORITY DESC, DUE_DATE ASC";

        Query query = entityManager.createNativeQuery(oracleSpecificSql, TodoItem.class);
        return query.getResultList();
    }

    // Another example of Oracle-specific SQL
    @Transactional
    public void updateTasksWithOracle(LocalDateTime cutoffDate, int newPriority) {
        String oracleSql = "UPDATE TODO_ITEMS " +
                           "SET PRIORITY = :newPriority, " +
                           "UPDATED_AT = SYSTIMESTAMP " +
                           "WHERE DUE_DATE < :cutoffDate " +
                           "AND COMPLETED = 0";

        Query query = entityManager.createNativeQuery(oracleSql)
                                    .setParameter("newPriority", newPriority)
                                    .setParameter("cutoffDate", cutoffDate);

        query.executeUpdate();
    }

    // Example using Oracle's VARCHAR2 data type specifics in a query
    @Transactional
    public List<TodoItem> searchWithOracleVarchar2(String searchTerm) {
        String oracleSql = "SELECT * FROM TODO_ITEMS " +
                           "WHERE DBMS_LOB.INSTR(TITLE, :searchTerm) > 0 " +
                           "OR DBMS_LOB.INSTR(DESCRIPTION, :searchTerm) > 0";

        Query query = entityManager.createNativeQuery(oracleSql, TodoItem.class)
                                    .setParameter("searchTerm", searchTerm);

        return query.getResultList();
    }
}
