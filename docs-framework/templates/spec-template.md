# Feature Specification: [Feature Name]

## 1. Overview
**Summary**: [Brief description of what this feature does]
**Rationale**: [Why are we building this? e.g., user request, technical debt, performance]

## 2. User Scenarios (User Stories)
> Describe how the user interacts with the feature.

- **Scenario 1**: [Description]
  - **Input**: [What user provides]
  - **Output**: [What system returns]
  - **Constraint**: [Any limitations]

- **Scenario 2**: [Description]
  ...

## 3. Interface Contract (OpenAPI Changes)
> Define the API changes required. This is the "Technical Spec".

### Endpoints
- `METHOD /api/v1/resource`
  - **Request Body**: [Link to schema or describe]
  - **Response**: [Link to schema or describe]

### Schemas
```yaml
# Optional: Inline YAML snippet for new schemas
NewResource:
  type: object
  properties:
    id:
      type: string
```

## 4. Acceptance Criteria
- [ ] UI displays X correctly.
- [ ] API returns 200 OK for valid input.
- [ ] API returns 400 Bad Request for invalid input.
- [ ] Performance: Response time < 200ms.
