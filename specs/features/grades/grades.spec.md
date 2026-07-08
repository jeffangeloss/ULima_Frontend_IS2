---
name: Grades
description: Grade calculator, assessment inputs, syllabus flow, and current course average.
targets:
  - ../../../lib/pages/calculadora/**
  - ../../../lib/components/calculadora/**
  - ../../../lib/services/notas_service.dart
  - ../../../lib/services/evaluations_service.dart
---

# Grades

## Requirements

- R6: Students can enter grades by assessment.
- R8: Assessment weights come from the syllabus via `GET /grades/me/courses`.
- R9: Course average updates after score changes (calculated locally).

## UI Behavior

- Calculator shows assessments, weights, and registered scores.
- Score entry validates the 0 to 20 range.
- Course average updates after local changes.
- NotasService usa `shared_preferences` para persistencia local; no hay escritura en backend.
- El endpoint `PUT /grades/me/scores` no está implementado en backend.

## API Dependencies

- `GET /grades/me/courses` — obtiene cursos y evaluaciones del sílabo con sus pesos.
- ~~`PUT /grades/me/scores`~~ — NO IMPLEMENTADO (cálculo local).
- ~~`GET /grades/me/courses/:sectionId/average`~~ — NO IMPLEMENTADO (cálculo local).

## Verification

- Add linked tests for score validation and average calculations.
