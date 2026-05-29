---
name: Grades
description: Grade calculator, assessment inputs, syllabus flow, and current course average.
targets:
  - ../../../lib/pages/calculadora/**
  - ../../../lib/components/calculadora/**
  - ../../../lib/services/notas_service.dart
  - ../../../lib/services/evaluations_service.dart
  - ../../../assets/data/notas_estudiantes.json
  - ../../../assets/data/evaluaciones.json
---

# Grades

## Requirements

- R6: Students can enter grades by assessment.
- R7: Students can upload syllabi.
- R8: Assessment weights come from the syllabus.
- R9: Course average updates after score changes.
- R14: Section average is calculated without exposing individual students.

## UI Behavior

- Calculator shows assessments, weights, and registered scores.
- Score entry validates the 0 to 20 range.
- Course average updates after local or API-backed changes.
- Syllabus upload flow feeds the assessment structure.

## API Dependencies

- `GET /grades/me/courses`
- `PUT /grades/me/scores`
- `GET /grades/me/courses/:sectionId/average`
- `POST /grades/syllabi`

## Verification

- Add linked tests for score validation and average calculations.
