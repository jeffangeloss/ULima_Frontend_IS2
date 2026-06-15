---
name: Android Release Build Signing
description: Firma del build de release de Android con keystore propio, con fallback seguro a debug en desarrollo
targets:
  - ../../../android/app/build.gradle.kts
  - ../../../android/key.properties.example
  - ../../../.gitignore
---

# Android Release Build Signing

## Scope

Esta spec cubre cómo se firma el APK/AAB de **release** de Android. No cambia lógica de la app, navegación, servicios ni contratos REST.

## Background

- Antes, `android/app/build.gradle.kts` firmaba el build de release con las **llaves de debug**
  (`signingConfig = signingConfigs.getByName("debug")`), lo que produce artefactos no aptos para
  producción ni para Play Store.

## Business Rules

### BR-RELEASE-01: Firma de release desde keystore externo
- La configuración de firma de release se carga desde `android/key.properties` (NO versionado).
- `key.properties` define `storeFile`, `storePassword`, `keyAlias` y `keyPassword`.
- Existe `android/key.properties.example` como plantilla versionada (sin credenciales reales).

### BR-RELEASE-02: Fallback seguro en desarrollo
- Si `android/key.properties` no existe, el build de release se firma con las llaves de **debug**
  para que `flutter run --release` siga funcionando en máquinas sin keystore.
- Este fallback **no** es apto para publicación; solo permite compilar en desarrollo.

### BR-RELEASE-03: No versionar secretos de firma
- `android/key.properties`, `*.jks` y `*.keystore` están en `.gitignore`.
- Nunca se commitea el keystore ni las contraseñas.

## Implementation Plan

### android/app/build.gradle.kts
- Importar `java.util.Properties` y `java.io.FileInputStream`.
- Cargar `key.properties` si existe (`rootProject.file("key.properties")`).
- Definir `signingConfigs.release` solo cuando el archivo existe.
- `buildTypes.release.signingConfig`: usar `release` si hay keystore, si no `debug`.

### android/key.properties.example
- Plantilla con las claves requeridas e instrucciones de `keytool` para generar el keystore.

### .gitignore
- Ignorar `/android/key.properties`, `**/*.jks`, `**/*.keystore`.

## Acceptance Criteria

- Con `key.properties` presente, `flutter build apk --release` firma con el keystore propio.
- Sin `key.properties`, `flutter build apk --release` compila usando firma debug (desarrollo).
- `key.properties` y los keystores no aparecen en `git status` como versionables.

## Test Links

*(Verificación manual con `flutter build apk --release`. No hay tests automatizados enlazados aún.)*
