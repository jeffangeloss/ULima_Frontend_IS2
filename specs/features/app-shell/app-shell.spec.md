---
name: Application shell
description: Comportamiento compartido del encabezado global de ULima++.
targets:
  - ../../../lib/components/header/app_header.dart
  - ../../../test/components/header/app_header_test.dart
---

# Application shell

## Scope

- Esta spec cubre únicamente el encabezado global reutilizado por las vistas
  autenticadas.
- No modifica navegación interna, sesión, permisos, APIs ni persistencia.

## UI Behavior

### BR-SHELL-F-01: Enlace promocional desde el nombre de la aplicación

- El texto `ULIMA++` del encabezado funciona como un control pulsable para
  alumnos y docentes.
- Al pulsarlo, la aplicación solicita abrir, fuera de ULima++, exactamente la
  siguiente URI mediante `url_launcher` y `LaunchMode.externalApplication`:
  `https://www.donbelisario.com.pe/clasico-combo-contundente?gsImpressionId=01KXPTTES6C5C0S9FKJG902C2G&gsListName=Recomendaciones%20-%20Promociones&gsIndex=3`.
- La acción no cambia de ruta dentro de GetX ni llama al backend.
- El control conserva el estilo visual del texto actual y expone semántica de
  botón para tecnologías de asistencia.
  `[@test] ../../../test/components/header/app_header_test.dart`

## Verification

- Ejecutar `dart format` sobre los archivos Dart modificados.
- Ejecutar `flutter analyze --no-pub`.
- Ejecutar `flutter test --no-pub test/components/header/app_header_test.dart`.
