# Functional Spec: Core Features (Baseline)

> Generated from `scaffold-core-prd-fullstack-planning-v1.0.0-20251202-zh-cn.md`

## 1. Authentication Module

### 1.1 Registration
- **User Story**: As a new user, I want to create an account so that I can access the system.
- **Inputs**: Email, Password, Profile Info.
- **Outputs**: Success message (or auto-login).
- **API**: `POST /api/v1/auth/register`

### 1.2 Login
- **User Story**: As a registered user, I want to log in so that I can access protected resources.
- **Inputs**: Email, Password.
- **Outputs**: Access Token (JWT), Refresh Token.
- **API**: `POST /api/v1/auth/login`

### 1.3 Token Refresh
- **User Story**: As a user, I want my session to stay active transparently when my access token expires.
- **Inputs**: Refresh Token.
- **Outputs**: New Access Token.
- **API**: `POST /api/v1/auth/refresh`

### 1.4 Get Current User (Me)
- **User Story**: As a logged-in user, I want to see my profile information.
- **Inputs**: Bearer Token.
- **Outputs**: User Profile Object.
- **API**: `GET /api/v1/auth/me`

## 2. Account Module

### 2.1 View Profile
- **User Story**: As a user, I want to view my profile details.
- **API**: `GET /api/v1/accounts/profile`

### 2.2 Update Profile
- **User Story**: As a user, I want to update my nickname or avatar.
- **API**: `PATCH /api/v1/accounts/profile`

## 3. System & UI

### 3.1 Theme Switching
- **User Story**: As a user, I want to toggle between Dark and Light mode.
- **Requirement**: Persist preference in LocalStorage.

### 3.2 Health Check
- **User Story**: As a devops engineer, I want to check if the system is running.
- **API**: `GET /health`
