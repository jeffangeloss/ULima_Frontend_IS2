# Flujo Frontend De Specs

Este repo tiene su propia instalacion de Tessl. Las specs frontend viven en:

```text
specs/features/<feature>/<feature>.spec.md
```

## Orden De Trabajo

1. Leer `.tessl/RULES.md`, `AGENTS.md`, `KNOWLEDGE.md`, `README.md` y `docs/specs/feature-index.md`.
2. Ubicar la historia de usuario real y la prioridad de la feature.
3. Confirmar el contrato esperado en `docs/specs/api-contracts.md`.
4. Abrir o crear la spec frontend correspondiente.
5. Definir pantallas, estados UI, validaciones, loading, errores, navegacion y consumo de API.
6. Esperar aprobacion explicita de la spec.
7. Implementar dentro de la estructura actual de `lib/`.
8. Ejecutar `flutter analyze` si hubo cambios Dart o configuracion Flutter.
9. Ejecutar `flutter test` cuando se agreguen o modifiquen tests.
10. Enlazar tests existentes con `[@test]` junto al requisito que verifican.

## Contexto De Datos

- PostgreSQL definitivo es la fuente de verdad a traves del backend.
- `assets/data/*.json` son mocks descartables.
- No usar JSON como fallback final cuando una feature consume API.
- Si faltan datos en backend/PostgreSQL, reportar el faltante.
- `shared_preferences` no reemplaza persistencia academica del backend.

## Orden Para Reescribir Specs

1. Auth: US01, US02.
2. Academic Profile: US05.
3. Curriculum: US03, US04.
4. Grades: US06, US07.
5. Schedule: US09.
6. Course Detail: US13, US14.
7. Alerts: US15.
8. Section Management: US16, US17, US18.

## Relacion Con Backend

Para features con API, permisos, reglas de negocio o persistencia, el contrato local del frontend debe estar alineado con el contrato local del backend antes de implementar UI final.

Se puede empezar por frontend solo cuando el cambio sea visual, local o de navegacion sin contrato nuevo. Si aparece una dependencia backend, se pausa la implementacion y se actualiza la spec backend primero.

El backend usa `routes -> controller -> service -> repository`, DTOs y observers internos. El frontend no debe copiar esa estructura: debe mantener paginas, controllers GetX, services y models.

Los services Flutter son la frontera de datos; widgets y componentes no deben llamar HTTP ni leer assets JSON directamente.
