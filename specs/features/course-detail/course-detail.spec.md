---
name: Course Detail
description: Course detail tabs for announcements, advising, and contacts.
targets:
  - ../../../lib/pages/descripcion_cursos/**
  - ../../../lib/components/descripcion_cursos/**
  - ../../../lib/services/anuncio_service.dart
  - ../../../lib/services/asesoria_service.dart
  - ../../../lib/services/contacto_service.dart
  - ../../../lib/services/docente_service.dart
---

# Course Detail

## Requirements

- R18: Students can view announcements from the section delegate.
- R20: Students can view advising schedules inside the course detail.

## UI Behavior

- Course detail keeps separate tabs for announcements, advising, and contacts.
- Announcements display newest information first.
- Advising details include teacher, modality, location, and time.

## API Dependencies

- `GET /course-detail/sections/:sectionId`
- `GET /course-detail/sections/:sectionId/announcements`
- `GET /course-detail/sections/:sectionId/advising`

## Verification

- Add linked tests for tab rendering and empty states.
