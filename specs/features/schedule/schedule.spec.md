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

- **Horario y Evaluaciones unificados**: El controlador `HorarioController` combina las sesiones de clase regulares con las evaluaciones programadas para el día seleccionado, ordenándolas en el cronograma semanal por bloques de tiempo.
- **Búsqueda y Mapeo Dinámico**: Las evaluaciones obtenidas desde `/schedule/me/assessments` contienen una fecha ISO (p. ej., "2026-01-12") que es parseada y mapeada dinámicamente al formato de texto del día (p. ej., "12 de Enero") para compararla de forma robusta e insensible a mayúsculas/minúsculas con `activeDay.dateText`.
- **Resaltado de Evaluaciones**: Los bloques de tiempo que correspondan a una evaluación se renderizan usando un **Card Premium Resaltado**:
  - Fondo degradado brillante (Coral/Rojo).
  - Borde grueso destacado de color Amarillo/Oro.
  - Sombra difusa de color Coral.
  - Indicador flotante: `📝 EVALUACIÓN: [SIGLA]`.
  - Al pulsar el card, abre un diálogo GetX personalizado (`Get.defaultDialog`) mostrando detalles como el nombre oficial, sigla, curso, aula y hora.
- **Alerta de Alta Carga Académica**: Si la semana actual del ciclo tiene **3 o más evaluaciones**, se activa una propiedad observable `isActiveWeekHighLoad` y la UI despliega un banner de advertencia destacado de color rojo y ambar debajo del selector de días.

## API Dependencies

- `GET /schedule/me/sessions`
- `GET /schedule/me/assessments`
- `GET /schedule/me/load`

## Verification

- Verificar que los Cards de evaluaciones y las clases regulares convivan en la misma grilla horaria.
- Verificar que el banner de alta carga se muestre solo en semanas con 3+ evaluaciones.
