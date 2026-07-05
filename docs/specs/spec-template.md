# Spec Template

Use this template for new frontend specs.

```markdown
---
name: Feature Name
description: Short description of the Flutter behavior.
targets:
  - ../../../lib/pages/feature/**
  - ../../../lib/services/feature_service.dart
---

# Feature Name

## Requirements

- R?: Requirement copied or referenced from the product catalog.

## UI Behavior

- Screen behavior.
- State behavior.
- Empty/error/loading behavior.

## API Dependencies

- `METHOD /path`

## Verification

- Add `[@test] path/to/test` links after tests exist.
```

Do not add `[@test]` links that point to files that do not exist.
