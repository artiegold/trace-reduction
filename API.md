# Ticket Processor API Documentation

## Overview

The Ticket Processor provides a RESTful API for managing support tickets with multiple assignees. The API supports both HTML and JSON responses.

## Base URL

```
http://localhost:4000/api
```

## Authentication

Currently, the API does not require authentication. In production, you should add authentication middleware.

## Endpoints

### Tickets

#### List All Tickets
```
GET /api/tickets
GET /api/tickets?status=open
```

**Response:**
```json
{
  "data": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "title": "Login issue",
      "description": "Cannot login to the system",
      "status": "open",
      "priority": "high",
      "assigned_to": ["alice@example.com", "bob@example.com"],
      "created_at": "2024-01-15T10:30:00Z",
      "updated_at": "2024-01-15T10:30:00Z"
    }
  ],
  "meta": {
    "count": 1
  }
}
```

#### Get Single Ticket
```
GET /api/tickets/:id
```

**Response:**
```json
{
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "title": "Login issue",
    "description": "Cannot login to the system",
    "status": "open",
    "priority": "high",
    "assigned_to": ["alice@example.com", "bob@example.com"],
    "created_at": "2024-01-15T10:30:00Z",
    "updated_at": "2024-01-15T10:30:00Z"
  }
}
```

#### Create Ticket
```
POST /api/tickets
Content-Type: application/json

{
  "ticket": {
    "title": "New ticket",
    "description": "Ticket description",
    "priority": "medium",
    "assigned_to": ["alice@example.com", "bob@example.com"]
  }
}
```

**Response:** `201 Created`
```json
{
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "title": "New ticket",
    "description": "Ticket description",
    "status": "open",
    "priority": "medium",
    "assigned_to": ["alice@example.com", "bob@example.com"],
    "created_at": "2024-01-15T10:30:00Z",
    "updated_at": "2024-01-15T10:30:00Z"
  }
}
```

#### Update Ticket
```
PUT /api/tickets/:id
Content-Type: application/json

{
  "ticket": {
    "title": "Updated title",
    "priority": "high",
    "assigned_to": ["charlie@example.com"]
  }
}
```

**Response:** `200 OK`

#### Add Assignee
```
PUT /api/tickets/:id/assign
Content-Type: application/json

{
  "assignee": "newuser@example.com"
}
```

**Response:** `200 OK`

#### Remove Assignee
```
PUT /api/tickets/:id/remove_assignee
Content-Type: application/json

{
  "assignee": "olduser@example.com"
}
```

**Response:** `200 OK`

#### Resolve Ticket
```
PUT /api/tickets/:id/resolve
```

**Response:** `200 OK`

#### Close Ticket
```
PUT /api/tickets/:id/close
```

**Response:** `200 OK`

#### Discard Ticket
```
PUT /api/tickets/:id/discard
```

**Response:** `200 OK`

#### Delete (Discard) Ticket
```
DELETE /api/tickets/:id
```

**Response:** `200 OK`
```json
{
  "message": "Ticket discarded successfully"
}
```

## Data Models

### Ticket

| Field | Type | Description | Required |
|-------|------|-------------|----------|
| id | UUID | Unique identifier | Yes |
| title | String | Ticket title | Yes |
| description | String | Detailed description | Yes |
| status | Enum | `open`, `in_progress`, `resolved`, `closed`, `discarded` | Yes |
| priority | Enum | `low`, `medium`, `high`, `urgent` | Yes |
| assigned_to | Array[String] | List of assignee emails | No |
| created_at | DateTime | Creation timestamp | Yes |
| updated_at | DateTime | Last update timestamp | Yes |

## Status Transitions

Valid status transitions:
- `open` → `in_progress`, `closed`, `discarded`
- `in_progress` → `resolved`, `closed`, `discarded`
- `resolved` → `closed`, `discarded`
- `closed` → `closed` (final state)
- `discarded` → `discarded` (final state)

## Priority Levels

- `low` - Low priority issues
- `medium` - Normal priority issues
- `high` - High priority issues
- `urgent` - Critical issues requiring immediate attention

## Multiple Assignees

The system supports assigning tickets to multiple people:

- **Maximum assignees**: 50 per ticket
- **Email format**: Valid email addresses only
- **Uniqueness**: Duplicate emails are automatically filtered
- **Empty list**: Tickets can be unassigned

## Error Responses

### Validation Errors (422)
```json
{
  "errors": {
    "title": "can't be blank",
    "priority": "is invalid",
    "assigned_to": "must be valid email addresses"
  }
}
```

### Not Found (404)
```json
{
  "error": "Ticket not found"
}
```

## Query Parameters

### Filtering by Status
```
GET /api/tickets?status=open
GET /api/tickets?status=in_progress
GET /api/tickets?status=resolved
GET /api/tickets?status=closed
GET /api/tickets?status=discarded
```

### Pagination (Future Enhancement)
```
GET /api/tickets?page=1&per_page=20
```

## Usage Examples

### Create a ticket with multiple assignees
```bash
curl -X POST http://localhost:4000/api/tickets \
  -H "Content-Type: application/json" \
  -d '{
    "ticket": {
      "title": "Database connection issue",
      "description": "Cannot connect to PostgreSQL database",
      "priority": "high",
      "assigned_to": ["alice@example.com", "bob@example.com", "charlie@example.com"]
    }
  }'
```

### Add an assignee to existing ticket
```bash
curl -X PUT http://localhost:4000/api/tickets/550e8400-e29b-41d4-a716-446655440000/assign \
  -H "Content-Type: application/json" \
  -d '{"assignee": "dave@example.com"}'
```

### Get all open tickets
```bash
curl http://localhost:4000/api/tickets?status=open
```

### Resolve a ticket
```bash
curl -X PUT http://localhost:4000/api/tickets/550e8400-e29b-41d4-a716-446655440000/resolve
```

## Rate Limiting

Currently no rate limiting is implemented. Consider adding rate limiting for production use.

## CORS

Cross-Origin Resource Sharing is not configured. Add CORS middleware for cross-origin requests in production.

## Testing

### Test with curl
```bash
# List all tickets
curl http://localhost:4000/api/tickets

# Create a ticket
curl -X POST http://localhost:4000/api/tickets \
  -H "Content-Type: application/json" \
  -d '{"ticket": {"title": "Test", "description": "Test", "priority": "medium"}}'

# Get specific ticket
curl http://localhost:4000/api/tickets/:id
```

### Test with HTTPie
```bash
# List tickets
http GET http://localhost:4000/api/tickets

# Create ticket
http POST http://localhost:4000/api/tickets ticket:='{"title": "Test", "description": "Test", "priority": "medium"}'

# Update ticket
http PUT http://localhost:4000/api/tickets/:id ticket:='{"title": "Updated"}'
```

## Development

### Start the server
```bash
cd ticket_processor
mix phx.server
```

### Run tests
```bash
mix test
```

### Generate API documentation
```bash
# Install ex_doc if not already installed
mix deps.get ex_doc
mix docs
```

## Production Deployment

### Environment Variables
- `DATABASE_URL` - PostgreSQL connection string
- `SECRET_KEY_BASE` - Phoenix secret key base
- `PORT` - Server port (default: 4000)

### Build and Deploy
```bash
# Build assets
mix assets.deploy

# Create database
mix ecto.create

# Run migrations
mix ecto.migrate

# Start server
mix phx.server
```

## API Versioning

Current version: v1.0.0

Versioning strategy:
- Major version changes indicate breaking changes
- Minor version changes add features (backwards compatible)
- Patch version changes fix bugs (backwards compatible)

## Support

For API support and questions:
- Create an issue in the GitHub repository
- Check the documentation at `/api/docs`
- Review the code examples in this document