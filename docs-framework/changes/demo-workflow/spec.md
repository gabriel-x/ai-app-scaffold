# Feature Specification: Add Request Logging

## 1. Overview
**Summary**: Add middleware to log incoming HTTP requests (method, URL, status, duration) to stdout.
**Rationale**: To improve observability and help debug issues in development and production.

## 2. User Scenarios (User Stories)
- **Scenario 1**: Developer checks logs.
  - **Input**: User sends `GET /api/v1/health`
  - **Output**: Console prints `[INFO] GET /api/v1/health 200 5ms`
  - **Constraint**: Must not log sensitive data (passwords).

## 3. Interface Contract (OpenAPI Changes)
> No changes to API endpoints. This is an internal behavior change.

## 4. Acceptance Criteria
- [ ] Requests to Node backend print logs.
- [ ] Requests to Python backend print logs.
- [ ] Log format includes Method, Path, Status Code, Response Time.
