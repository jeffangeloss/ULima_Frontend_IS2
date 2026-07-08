---
name: Academic Profile
description: View student profile with career, curriculum and specialties; select and manage specialties via setup wizard and profile page
targets:
  - ../../../lib/pages/perfil/**
  - ../../../lib/pages/setup_carrera/**
  - ../../../lib/services/auth_service.dart
---

# Academic Profile

## User Stories

| ID | Description |
| --- | --- |
| US05 | Seleccionar especialidad. |

## Requirements

- R12: Students can select one or more specialties.
- R13: The app reflects elective courses for selected specialties.

## Backend Endpoints

| Method | Endpoint | Purpose |
| --- | --- | --- |
| `GET` | `/academic-profile/me` | Full profile of authenticated student (includes career, curriculum, specialties) |
| `GET` | `/academic-profile/careers` | All available careers |
| `GET` | `/academic-profile/specialties?careerId=` | Specialties filtered by career (uses student's career if omitted) |
| `PUT` | `/academic-profile/me/specialties` | Replace student's active specialties |

## Screens

### 1. Profile page (`lib/pages/perfil/perfil.dart`)

Displays the authenticated student's academic data. All data comes from `GET /academic-profile/me`.

**UI sections:**

| Section | Data source | Description |
| --- | --- | --- |
| Header | `profile.fullName`, `profile.code` | Avatar with initials, student name and code |
| Career card | `profile.career` | Career name (read-only, "Fija" badge) |
| Specialties card | `profile.specialties` | Primary specialty chip + interest chips. "Editar" button opens bottom sheet. |
| Logout | — | Red button that calls `AuthService.logout()` |

**States:**

| State | Behavior |
| --- | --- |
| **Loading** | Skeleton placeholder in header and cards while `GET /me` resolves |
| **Error** | Red banner with retry button if `GET /me` fails |
| **Empty (no specialties)** | Text: "Sin especialización seleccionada" |
| **Success** | Full profile with career card and specialty chips |

**Specialty bottom sheet (`_EspecialidadSheet`):**

- Lists all specialties for the student's career (fetched from `AuthService.especialidades` catalog loaded by `loadCatalogs`)
- Each row has two toggle chips: "Principal" (star icon) and "Me interesa" (heart icon)
- Only one specialty can be primary at a time
- "Guardar" button calls `PUT /academic-profile/me/specialties` via `AuthService.completeSetup`
- The same specialty cannot be both primary and interest
- States: loading spinner while saving, error banner on failure, dismiss on success

### 2. Setup wizard (`lib/pages/setup_carrera/`)

Shown once after first login when `setupComplete == false`.

**Steps:**

| Step | Screen | Behavior |
| --- | --- | --- |
| 1. Carrera | `SetupStep.carrera` | Shows assigned career (read-only, "Fija" badge). "Continuar" advances. |
| 2. Decisión | `SetupStep.decision` | Three options: "Sí, quiero elegir ahora", "Todavía no estoy seguro", "Quiero explorar primero" |
| 3. Selección | `SetupStep.seleccion` | Specialty list with "Principal" and "Me interesa" toggles. "Finalizar configuración" saves. |

## Service Changes

### AuthService (`lib/services/auth_service.dart`)

**New/Modified methods:**

| Method | Change |
| --- | --- |
| `fetchProfile()` | **New.** Calls `GET /academic-profile/me`. Updates `_currentUser` with `profile.fullName`, `profile.code`, `profile.career`, `profile.specialties`. |
| `completeSetup()` | **Modified.** Instead of saving only to local storage, calls `PUT /academic-profile/me/specialties` with `{ primarySpecialtyId, interestSpecialtyIds }`. On success, refreshes profile via `fetchProfile()`. Falls back to local save only if backend is unreachable. |
| `tryRestoreSession()` | **Modified.** After restoring token, calls `fetchProfile()` instead of `_applyStoredSetup()`. |
| `loadCatalogs()` | **Unchanged.** Already calls `/academic-profile/careers` and `/academic-profile/specialties`. |

**Removed:**

- `_applyStoredSetup()` — no longer needed. Profile data comes from `GET /me`.

### UserModel (`lib/models/user_model.dart`)

**Modified `fromJson`** to accept the `GET /me` response format:

| JSON field | Maps to |
| --- | --- |
| `profile.code` | `code` |
| `profile.fullName` | Split into `firstName`, `lastName` |
| `profile.institutionalEmail` | `email` |
| `profile.role` | `role` (mapped: `'student'` → `'estudiante'`, `'delegate'` → `'delegado'`) |
| `profile.career.id` | `careerId` |
| `profile.currentLevel` | `currentLevel` (ignored for now, used by curriculum) |
| `profile.specialties` | `especialidadPrincipal` (where `selectionType == 'primary'`) + `especialidadesInteres` (where `selectionType == 'interest'`) |

**Fields kept for legacy compatibility** (will be removed when curriculum/grades specs are rewritten):
- `currentCycle` → hardcoded default or from backend when available
- `courseProgress` → from `/curriculum/me` endpoint

## Data Flow

### Profile loading flow

```
App starts → tryRestoreSession()
  → GET /auth/me → get user basic info + token
  → GET /academic-profile/me → get full profile with career, curriculum, specialties
  → GET /academic-profile/careers → load catalogs
  → GET /academic-profile/specialties → load catalogs
  → Navigate to /home
```

### Specialty saving flow

```
User edits specialties → tap "Guardar"
  → PUT /academic-profile/me/specialties { primarySpecialtyId, interestSpecialtyIds }
  → On success: GET /academic-profile/me (refresh)
  → On error: show error banner
  → Close bottom sheet
```

## Mock Data Elimination

The following files are no longer referenced by the academic profile feature:

| File | Status | Reason |
| --- | --- | --- |
| `assets/data/` | 🗑️ Eliminado | El directorio `assets/data/` no existe en el proyecto. |
| `lib/services/user_service.dart` | 🗑️ Legacy | Servicio que llama a `GET /academic-profile/users` — endpoint no implementado en backend. |

## Verification

- `flutter analyze` must pass after changes
- Login → profile page shows real data from backend
- Edit specialties → data persists in PostgreSQL across sessions
- Logout → re-login → profile shows persisted specialties
- `[@test]` links to be added when tests exist
