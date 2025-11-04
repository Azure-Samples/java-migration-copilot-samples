package com.microsoft.migration.todo.controller;

import com.microsoft.migration.todo.model.TodoItem;
import com.microsoft.migration.todo.service.TodoService;
import com.microsoft.migration.todo.util.OracleSqlDemonstrator;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.Optional;

@RestController
@RequestMapping("/api/todos")
public class TodoController {

    @Autowired
    private TodoService todoService;

    @Autowired
    private OracleSqlDemonstrator oracleSqlDemonstrator;

    @GetMapping
    public ResponseEntity<List<TodoItem>> getAllTodos() {
        return ResponseEntity.ok(todoService.getAllTodos());
    }

    @GetMapping("/{id}")
    public ResponseEntity<TodoItem> getTodoById(@PathVariable Long id) {
        Optional<TodoItem> todo = todoService.getTodoById(id);
        return todo.map(ResponseEntity::ok)
                .orElseGet(() -> ResponseEntity.notFound().build());
    }

    @PostMapping
    public ResponseEntity<TodoItem> createTodo(@RequestBody TodoItem todo) {
        return new ResponseEntity<>(todoService.createTodo(todo), HttpStatus.CREATED);
    }

    @PutMapping("/{id}")
    public ResponseEntity<TodoItem> updateTodo(@PathVariable Long id, @RequestBody TodoItem todoDetails) {
        try {
            TodoItem updatedTodo = todoService.updateTodo(id, todoDetails);
            return ResponseEntity.ok(updatedTodo);
        } catch (RuntimeException ex) {
            return ResponseEntity.notFound().build();
        }
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteTodo(@PathVariable Long id) {
        try {
            todoService.deleteTodo(id);
            return ResponseEntity.noContent().build();
        } catch (Exception ex) {
            return ResponseEntity.notFound().build();
        }
    }

    @GetMapping("/completed")
    public ResponseEntity<List<TodoItem>> getTodosByCompleted(@RequestParam boolean completed) {
        return ResponseEntity.ok(todoService.getTodosByCompleted(completed));
    }

    @GetMapping("/high-priority")
    public ResponseEntity<List<TodoItem>> getHighPriorityTodos(@RequestParam(defaultValue = "5") int minPriority) {
        return ResponseEntity.ok(todoService.getHighPriorityTodos(minPriority));
    }

    @GetMapping("/search")
    public ResponseEntity<List<TodoItem>> searchTodos(@RequestParam String keyword) {
        return ResponseEntity.ok(todoService.searchTodos(keyword));
    }

    @GetMapping("/top-priority")
    public ResponseEntity<List<TodoItem>> getTopPriorityTasks(
            @RequestParam(defaultValue = "3") int priority,
            @RequestParam(defaultValue = "5") int limit) {
        return ResponseEntity.ok(todoService.getTopPriorityTasks(priority, limit));
    }

    @GetMapping("/overdue")
    public ResponseEntity<List<TodoItem>> getOverdueTasks() {
        return ResponseEntity.ok(todoService.getOverdueTasks());
    }

    @PutMapping("/update-priority")
    public ResponseEntity<Void> updateTasksPriority(
            @RequestParam LocalDateTime cutoffDate,
            @RequestParam int newPriority) {
        todoService.updateTasksWithOracle(cutoffDate, newPriority);
        return ResponseEntity.ok().build();
    }

    @GetMapping("/oracle-search")
    public ResponseEntity<List<TodoItem>> searchWithOracleVarchar2(@RequestParam String term) {
        return ResponseEntity.ok(todoService.searchWithOracleVarchar2(term));
    }

    // Endpoint to demonstrate raw Oracle SQL usage
    @GetMapping("/oracle-demo")
    public ResponseEntity<List<Map<String, Object>>> demonstrateOracleSpecificQuery(
            @RequestParam(defaultValue = "") String keyword,
            @RequestParam(defaultValue = "0") int minPriority) {
        return ResponseEntity.ok(oracleSqlDemonstrator.executeRawOracleQuery(keyword, minPriority));
    }

    // Endpoint to run the Oracle operations demo
    @PostMapping("/run-oracle-operations")
    public ResponseEntity<String> runOracleOperations() {
        try {
            oracleSqlDemonstrator.performOracleSpecificOperations();
            return ResponseEntity.ok("Oracle-specific operations executed successfully");
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body("Error executing Oracle operations: " + e.getMessage());
        }
    }
}
