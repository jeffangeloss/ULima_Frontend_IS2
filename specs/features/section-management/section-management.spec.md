---
name: Section Management
description: Delegate/subdelegate screens for announcements and anonymized section progress.
targets:
  - ../../../lib/services/anuncio_service.dart
  - ../../../lib/services/seccion_service.dart
  - ../../../docs/images/UI/GestionCursosDelegado.png
  - ../../../docs/images/UI/GestionAnunciosDelegado.png
  - ../../../docs/images/UI/SeguimientoProgresoSeccion.png
---

# Section Management

## Requirements

- R14: Section average is calculated from valid grades.
- R17: Delegates can register announcements.
- R18: Students can view delegate announcements.
- R21: Delegates can view anonymized grade distribution.

## UI Behavior

- Delegate-only actions are hidden from regular students.
- Announcement management supports creating academic announcements.
- Progress dashboard shows aggregates, never individual student data.

## API Dependencies

- `GET /section-management/me/sections`
- `POST /section-management/sections/:sectionId/announcements`
- `GET /section-management/sections/:sectionId/progress`

## Verification

- Add linked tests for delegate visibility and aggregate-only progress display.
