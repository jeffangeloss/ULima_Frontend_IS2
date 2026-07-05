---
name: Curriculum
description: Interactive curriculum grid, course status, prerequisites, and electives in Flutter.
targets:
  - ../../../lib/pages/malla/**
  - ../../../lib/services/malla_service.dart
  - ../../../lib/models/malla_models.dart
  - ../../../assets/data/malla_sistemas.json
---

# Curriculum

## Requirements

- R4: Students can view their curriculum grid.
- R5: Students can update course status.
- R10: Students can view eligible courses.
- R11: Students can view the status of each course.
- R13: Specialty electives are visible when selected.

## UI Behavior

- The grid groups courses by cycle.
- Course cards expose the current status.
- Status changes update the visible grid state.
- Elective rendering follows selected specialties.

## API Dependencies

- `GET /curriculum/me`
- `PUT /curriculum/me/progress`
- `GET /curriculum/me/eligible-courses`

## Verification

- Add linked widget tests for rendering by cycle, status, and prerequisites.
