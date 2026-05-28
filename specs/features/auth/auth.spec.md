---
name: Auth
description: Flutter login, logout, user session persistence, and authenticated navigation.
targets:
  - ../../../lib/pages/login/**
  - ../../../lib/services/auth_service.dart
  - ../../../lib/services/storage_service.dart
  - ../../../lib/models/user_model.dart
---

# Auth

## Requirements

- R1: Users can sign in with code and password.
- R2: Users can close the active session.
- RNF7: Credentials and session data are handled securely.

## UI Behavior

- Login form collects code and password.
- Successful login stores session/user data and navigates to the main app.
- Failed login shows a controlled error without exposing backend internals.
- Logout clears local session state.

## API Dependencies

- `POST /auth/login`
- `POST /auth/logout`
- `GET /auth/me`

## Verification

- Add linked widget/service tests after Flutter test coverage is introduced for auth.
