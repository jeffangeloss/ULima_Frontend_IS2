---
name: Alerts
description: Student alert inbox and academic risk/high-load notification display.
targets:
  - ../../../lib/pages/home/**
  - ../../../lib/pages/perfil/**
  - ../../../docs/images/UI/BuzonAlertas.png
---

# Alerts

## Requirements

- R15: Academic risk is detected from progress and grade thresholds.
- R16: Students receive alerts for academic risk and high-load weeks.
- R22: Evaluation count by week supports load alerts.
- R23: High-load weeks are identified.

## UI Behavior

- Alert entry points are visible from the main authenticated experience.
- Alert cards distinguish risk, high load, reminders, course average, and system alerts.
- Read state is preserved when backed by the API.

## API Dependencies

- `GET /alerts/me`
- `PUT /alerts/me/:alertId/read`

## Verification

- Add linked tests for alert categorization and read-state behavior.
