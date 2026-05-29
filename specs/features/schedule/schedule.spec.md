---
name: Schedule
description: Academic schedule, evaluation calendar, and weekly load visualization.
targets:
  - ../../../lib/pages/horario/**
  - ../../../lib/services/evaluations_service.dart
  - ../../../lib/services/seccion_service.dart
  - ../../../assets/data/schedule_days.json
  - ../../../assets/data/evaluaciones.json
---

# Schedule

## Requirements

- R19: Students can view exams organized by week and day.
- R22: The system calculates evaluations per week.
- R23: High-load weeks are identified.

## UI Behavior

- Schedule view presents class sessions and evaluations in date order.
- Evaluation list groups by academic week where applicable.
- High-load indicators consume backend summary when available.

## API Dependencies

- `GET /schedule/me/sessions`
- `GET /schedule/me/assessments`
- `GET /schedule/me/load`

## Verification

- Add linked tests for ordering, grouping, and high-load display.
