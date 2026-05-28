---
name: Academic Profile
description: Career and specialty setup flow in Flutter.
targets:
  - ../../../lib/pages/setup_carrera/**
  - ../../../lib/services/user_service.dart
  - ../../../assets/data/carreras.json
  - ../../../assets/data/especialidades.json
---

# Academic Profile

## Requirements

- R3: Students can select a career.
- R12: Students can select one or more specialties.
- R13: The app reflects elective courses for selected specialties.

## UI Behavior

- Setup flow presents available careers before specialty selection.
- Specialty options are filtered by selected career.
- Saved selections are persisted locally until backend persistence is wired.

## API Dependencies

- `GET /academic-profile/careers`
- `GET /academic-profile/specialties?careerId=`
- `PUT /academic-profile/me/career`
- `PUT /academic-profile/me/specialties`

## Verification

- Add linked tests for career filtering and specialty persistence.
