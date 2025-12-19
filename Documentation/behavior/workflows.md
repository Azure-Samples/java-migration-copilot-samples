# Workflows - Process Flows

**Analysis Date:** December 2024

## Key Workflows

### asset-manager: File Upload and Processing
1. User uploads file via web interface
2. Web module validates and stores in S3
3. Metadata saved to PostgreSQL
4. Message published to RabbitMQ
5. Worker consumes message
6. Worker generates thumbnail
7. Thumbnail uploaded to S3
8. Metadata updated with thumbnail key

### todo-web-api: Todo CRUD
- Create: Validate → Set defaults → Save → Return with ID
- Read: Fetch by ID or list all
- Update: Find → Validate → Update → Save
- Delete: Find → Remove from database
- Complete: Find → Set completed=true → Save

### ContosoUniversity: Student Enrollment
1. Display create form with default enrollment date
2. User submits student data
3. Validate name and enrollment date (1753-9999 range)
4. Save to database
5. Send notification (CREATE operation)
6. Redirect to student list

**Related:** [Business Logic](business-logic.md), [Sequence Diagrams](../diagrams/behavioral/sequence-diagrams.md)
