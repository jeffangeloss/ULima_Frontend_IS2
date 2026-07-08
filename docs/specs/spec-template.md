# Spec Template

Use this template for new frontend specs. Incluye secciones que los specs reales usan (Business Rules, Data Flow, Mock Data Elimination, Implementation Plan cuando aplica).

```markdown
---
name: Feature Name
description: Short description of the Flutter behavior.
targets:
  - ../../../lib/pages/feature/**
  - ../../../lib/services/feature_service.dart
---

# Feature Name

## User Stories

| ID | Description |
| --- | --- |
| USXX | Descripción de la historia de usuario. |

## Requirements

- R?: Requirement copied or referenced from the product catalog.

## Business Rules

### BR-FEAT-F-01: Rule name
- Specific rule about behavior.
- Error handling rule.

## UI Behavior

- Screen behavior.
- State behavior (loading, error, empty, success).
- Navigation behavior.

## Data Flow

\`\`\`
User action → Controller method → Service call → API request
  → Response → Model mapping → Controller state update → UI rebuild
\`\`\`

## API Dependencies

- `METHOD /path` — Purpose of the call.

## Mock Data Elimination

| File | Status | Reason |
| --- | --- | --- |
| `assets/data/file.json` | 🗑️ Remove | Replaced by API endpoint. |

## Verification

- `flutter analyze` must pass.
- `[@test] path/to/test` links after tests exist.
```

Do not add `[@test]` links that point to files that do not exist.

## Secciones Opcionales (según complejidad)

- **Implementation Plan**: solo si describe trabajo no realizado. Si la feature ya está implementada, no incluir plan.
- **Service Changes**: detalle de métodos a agregar/modificar en services existentes.
- **Screen Details**: especificación de componentes/widgets por pantalla.
