# Cambio: Configurar inicio de sesión con Google en Android

**Fecha:** 2026-06-18
**Repo:** `ULima_Frontend_IS2` (rama `jeff`)
**Feature:** Auth (US03 — login con Google)

## Contexto / problema

El login con Google ya funcionaba en **web** (botón oficial GIS + `onCurrentUserChanged`),
pero en **Android** estaba a medias:

- `AuthService` construía `GoogleSignIn` con `clientId: kIsWeb ? googleWebClientId : null`
  y **sin** `serverClientId`.
- En `google_sign_in` 6.x, Android devuelve `account.authentication.idToken == null`
  cuando no se pasa `serverClientId`. Como `finishGoogleLogin()` necesita ese `idToken`
  para canjearlo en `POST /auth/google`, el flujo fallaba con
  *"No se obtuvo información de Google."*

El backend (`auth.service.ts` → `googleClient.verifyIdToken({ idToken })`) verifica el
token **sin** restringir `audience`, así que acepta el `idToken` de Android sin cambios.

## Cambios de código (ya aplicados)

| Archivo | Cambio |
|---|---|
| `lib/services/auth_service.dart` | Se agregó `serverClientId: kIsWeb ? null : googleWebClientId` al constructor de `GoogleSignIn`, con comentario explicativo. |
| `lib/pages/login/login_page.dart` | El botón de Google en móvil usaba el logo de la ULima como placeholder; ahora usa el logo real de Google (`assets/images/google_logo.svg`), sin `colorMapper`. |
| `assets/images/google_logo.svg` | **Nuevo.** Logo oficial "G" de Google (4 colores). El folder `assets/images/` ya estaba registrado en `pubspec.yaml`. |
| `specs/features/auth/auth.spec.md` | Nueva US03, nueva regla **BR-AUTH-F-10** (flujo Google web + Android) y `targets` ampliados a `google_auth_config.dart` y `google_sign_in_button*.dart`. |

`flutter analyze` sobre los archivos tocados: **No issues found**.

> No requiere `google-services.json` ni Firebase: `google_sign_in` no depende de Firebase.
> El client de Android no se embebe en el código; Google lo resuelve en runtime por
> *package name + huella SHA-1*.

## Pasos manuales pendientes (Google Cloud Console)

El código ya pide el `idToken` con `aud = client web`, pero Android **no podrá** completar
`signIn()` (fallará con `ApiException: 10` DEVELOPER_ERROR) hasta crear un **OAuth Client de
tipo Android** en el **mismo proyecto** del client web ya existente
(`608661962945-...apps.googleusercontent.com`).

1. Ir a **Google Cloud Console → APIs y servicios → Credenciales** del proyecto `608661962945`.
2. **Crear credenciales → ID de cliente de OAuth → Tipo: Android**.
3. Completar:
   - **Nombre del paquete:** `com.example.ulima_plus`
   - **Huella digital del certificado SHA-1 (debug, esta máquina):**
     ```
     34:DB:7B:4E:F8:5F:BE:1C:36:EA:5D:4C:6E:F5:87:C6:C5:25:1A:B5
     ```
4. Guardar. (No hace falta copiar el ID generado al código.)

### Para release / Play Store

- La SHA-1 de arriba es la del **keystore de debug** (`~/.android/debug.keystore`), válida
  solo para correr en desarrollo (`flutter run`).
- Para builds firmados de release hay que **agregar también la SHA-1 del keystore de
  release** (el que se configura en `android/key.properties`, ver `key.properties.example`).
- Si se publica en Play Store con **Play App Signing**, agregar además la SHA-1 que Google
  asigna en *Play Console → Configuración → Integridad de la app → Firma de apps*.
- Recomendado antes de producción: cambiar el `applicationId` placeholder
  `com.example.ulima_plus` (`android/app/build.gradle.kts`) por uno propio y registrar
  ese package en el OAuth Client.

### Cómo recalcular la SHA-1 (si cambia la máquina o el keystore)

```powershell
& "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" `
  -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" `
  -alias androiddebugkey -storepass android -keypass android
```

(O `flutter build apk` + `./gradlew signingReport` desde `android/`.)

## Verificación

- [x] `flutter analyze` limpio.
- [ ] Crear el OAuth Client de Android en la consola (paso manual de arriba).
- [ ] Probar en dispositivo/emulador Android: botón Google → seleccionar cuenta
      `@aloe.ulima.edu.pe` → navega a `/home` o `/setup-carrera`.
- [ ] Probar caso de dominio inválido → muestra `"Debes usar tu correo @aloe.ulima.edu.pe."`.
