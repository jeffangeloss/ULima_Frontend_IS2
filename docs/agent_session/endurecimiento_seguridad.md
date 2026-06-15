# Endurecimiento de Seguridad — Frontend (Release 1)

Sesión de correcciones de seguridad derivadas del análisis de deuda técnica. Sigue el flujo Spec-Driven (Tessl).

**Branch:** `jeff` (integrado con `origin/main`, sin conflictos). **Verificación:** `flutter analyze` → 0 errores.

---

## Contexto

El diagnóstico detectó que el build de release de Android se firmaba con llaves de debug y que varios endpoints del backend se consumían sin token. Esta sesión aborda la parte de frontend.

---

## Cambios realizados

### 1. Firma de release de Android (C8) — `android/app/build.gradle.kts`
- **Antes:** `release { signingConfig = signingConfigs.getByName("debug") }` → APK/AAB no apto para producción ni Play Store.
- **Después:** patrón estándar de Flutter:
  - Carga `android/key.properties` (NO versionado) y firma el release con keystore propio.
  - Si `key.properties` no existe, hace **fallback a debug** para no romper `flutter run --release` en desarrollo.
- **Nuevos archivos:** `android/key.properties.example` (plantilla con instrucciones de `keytool`) y reglas en `.gitignore` (`key.properties`, `*.jks`, `*.keystore`).
- **Spec:** nueva `specs/features/release-build/release-build.spec.md` (BR-RELEASE-01/02/03).
- **Acción pendiente (manual):** generar el keystore y crear `key.properties`.

### 2. Verificación del envío de token (relacionado con C3 del backend)
- El backend protegió `course-detail`, `grades` y `section-management` con `authMiddleware`.
- Esos servicios del frontend los llamaban **sin token**, por lo que protegerlos hubiera roto la app.
- Al integrar `origin/main` se confirmó que **el `ApiClient` ya centraliza el token**: si una llamada no pasa un token explícito, adjunta el JWT guardado (`StorageService.savedToken`) como `Authorization: Bearer <token>`, y maneja 401/logout global.
- **Conclusión:** no se requirió cambio adicional en el frontend; un cambio inicial duplicado en `api_client.dart` se **descartó** para no perder el manejo de 401 de `main`.

---

## Verificación

- `flutter analyze` → **0 errores** (tras integrar `origin/main`).
- `flutter pub get` OK.
- `.gitignore` cubre `key.properties`/keystores; **ningún secreto trackeado**.
- `flutter build apk --release` debe confirmarse en una máquina con Gradle operativo (no corre en el sandbox).

---

## Deuda pendiente (relacionada)

- **Keystore real:** generar el `.jks` y `key.properties` antes de publicar.
- **C9:** campos `late` en servicios/controladores que pueden lanzar `LateInitializationError`.
- **Tests:** ampliar cobertura (en `main` ya existe `test/services/api_client_test.dart`).
