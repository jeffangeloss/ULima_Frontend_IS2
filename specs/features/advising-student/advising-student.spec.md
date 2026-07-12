---
name: Advising Student — RSVP del alumno
description: Pantalla de asesorías con botón "Asistiré", contador de confirmados y toggle para retirar confirmación (HU17)
targets:
  - ../../../lib/services/asesoria_service.dart
  - ../../../lib/pages/descripcion_cursos/descrip_cursos_controller.dart
  - ../../../lib/components/descripcion_cursos/asesoria_card.dart
  - ../../../lib/models/asesoria_model.dart
---

# Advising Student — RSVP del alumno

Vista de asesorías para el alumno dentro del detalle de curso (pestaña "Asesorías"). El alumno ve asesorías recurrentes y extra, confirma su asistencia y puede retirarla.

## Requirements

- **R1**: Cada asesoría muestra un botón "Asistiré" (o "Asistiré · Cancelar" si ya confirmó) y el contador de confirmados ("N asistirán").
- **R2**: Pulsar "Asistiré" registra la confirmación vía API. El botón cambia a estado confirmado con check (✓) y permite deshacer.
- **R3**: Pulsar el botón en estado confirmado retira la confirmación vía API. El botón vuelve a "Asistiré".
- **R4**: El contador se actualiza optimistamente en la UI mientras la request está en curso; si falla, revierte al estado previo con snackbar de error.
- **R5**: No se puede confirmar asistencia a asesorías ya pasadas (el backend las filtra del listado; si llega una al frontend por desfase, el POST rechaza con 409 y el snackbar lo informa).
- **R6**: El toggle es idempotente: si otra request ya está en curso para la misma asesoría, se ignora el tap (protección vía `rsvpEnCurso`).
- **R7**: La pestaña "Asesorías" muestra tanto asesorías recurrentes como extras, ordenadas con extras primero y luego recurrentes.

## UI Behavior

- La pestaña "Asesorías" se renderiza dentro de `DescripCursosPage` (índice de tab = 1) usando `AsesoriasTab`.
- Cada asesoría se renderiza con `CardAsesoria`, que muestra:
  - Badges: `kind` ("Extra · fecha") y `dictanteRol` ("Profesor" o "JP").
  - Día y hora: "Lunes 10:00 - 11:00".
  - Contador: "N asistirán" (ícono de grupos + número).
  - Botón RSVP (`_RsvpButton`): filled "Asistiré" si no confirmó, outlined "Asistiré · Cancelar" con check si ya confirmó.
  - Expansión: docente, aula, enlace Zoom.
- Estados: loading (skeleton cards), vacío (empty state), datos (lista de cards).
- Actualización optimista: al pulsar el botón, el contador y estado cambian inmediatamente. Al recibir respuesta del backend, se reconcilia con el valor autoritativo. Si hay error, se revierte.

### Flujo de confirmación

1. Alumno pulsa "Asistiré" en una asesoría no confirmada.
2. Controller llama `toggleRsvp(asesoria)`:
   - Setea `rsvpEnCurso.add(id)` para bloquear doble tap.
   - Actualiza optimistamente: `myRsvp = true`, `asistentes += 1`.
   - Llama `AsesoriaService.confirmarAsistencia(id)` → `POST /advising-student/:id/rsvp`.
   - Reconcilia `asistentes` y `myRsvp` con el response.
   - Si error: revierte al estado previo, snackbar "No pudimos confirmar tu asistencia. Inténtalo de nuevo.".
   - Libera `rsvpEnCurso`.

### Flujo de cancelación

1. Alumno pulsa "Asistiré · Cancelar" en una asesoría ya confirmada.
2. Mismo `toggleRsvp` con `quiereAsistir = false`:
   - Actualiza optimistamente: `myRsvp = false`, `asistentes -= 1` (clamp ≥ 0).
   - Llama `AsesoriaService.cancelarAsistencia(id)` → `DELETE /advising-student/:id/rsvp`.
   - Reconcilia y maneja errores igual que en confirmación.

## API Dependencies

- `GET /advising/section/:sectionId` — listado de asesorías (reemplaza al viejo `GET /course-detail/sections/:sectionId/advising`).
- `POST /advising/:sessionId/rsvp` — confirmar asistencia.
- `DELETE /advising/:sessionId/rsvp` — cancelar asistencia.

### Cambios en AsesoriaService

Se actualizan las rutas en `lib/services/asesoria_service.dart`:

| Método | Ruta anterior | Ruta nueva |
|--------|---------------|------------|
| `fetchAsesorias` | `/course-detail/sections/$idSeccion/advising` | `/advising/section/$idSeccion` |
| `confirmarAsistencia` | `/course-detail/advising/$sessionId/rsvp` | `/advising/$sessionId/rsvp` |
| `cancelarAsistencia` | `/course-detail/advising/$sessionId/rsvp` | `/advising/$sessionId/rsvp` |

El modelo `Asesoria`, `RsvpResult`, y el controller `DescripCursosController.toggleRsvp` no requieren cambios de lógica (solo referencias a rutas vía el service).

## Verification

- `flutter analyze` después de cambios.
- Verificar que el listado incluya asesorías extra.
- Verificar que el toggle RSVP funcione con las nuevas rutas.
- Verificar snackbar de error en caso de fallo de red.
