# Decision Logic - Conditional Patterns

**Analysis Date:** December 2024

## Validation Decision Logic

### asset-manager
- IF file.isEmpty() THEN reject upload
- IF AWS profile THEN use S3 ELSE use local storage
- IF AWS profile THEN publish message to RabbitMQ

### todo-web-api
- IF title is blank THEN validation error
- IF title > 200 chars THEN validation error
- IF description > 4000 chars THEN validation error

### ContosoUniversity
- IF enrollmentDate < 1753 OR > 9999 THEN validation error
- IF enrollmentDate == MinValue THEN validation error
- IF credits < 0 OR > 5 THEN validation error

## Search and Filter Logic

### ContosoUniversity Students
- IF searchString NOT empty THEN filter by LastName OR FirstMidName contains
- SWITCH sortOrder: name_desc, Date, date_desc, default

## Error Handling Decisions

- IF EntityNotFoundException THEN return 404
- IF ValidationException THEN return 400 with errors
- IF IOException THEN log and return generic error

**Related:** [Business Logic](business-logic.md), [Error Handling](error-handling.md)
