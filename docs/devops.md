# DevOps del front de ULima++

Este documento explica cómo se ramifica, se integra y se publica la app Flutter de ULima++. Cubre las
ramas, la publicación de una versión, el hotfix, la integración continua (CI), la versión de Flutter y
la forma de apuntar una build de depuración al entorno de pruebas del backend. Los cambios entran por
pull request (PR), y el paquete de instalación de Android (APK) sale de un workflow de GitHub Actions.
Todo lo que hace falta para repetir esos pasos queda en este repo, en `.github/workflows/`,
`pubspec.yaml` y `CHANGELOG.md`.

## Ramas

El front vive en dos repos. El fork `jeffangeloss/ULima_Frontend_IS2` (remoto `origin`) es donde se
trabaja, y `meltiruiz/ULima_Frontend_IS2` (remoto `upstream`) es producción, porque su `main` compila y
publica el APK. El job `build-android` de `build-apk.yml` lleva la guarda
`github.repository == 'meltiruiz/ULima_Frontend_IS2'`, así que en el fork se omite aunque el workflow
se active.

| Rama | Sale de | Entra a | Despliegue |
|---|---|---|---|
| `develop` del fork (rama por defecto) | `main` del fork al crearla | `meltiruiz:main` por PR de versión | ninguno |
| `feat/*`, `fix/*`, `docs/*`, `chore/*`, `test/*`, `refactor/*` del fork | `develop` | `develop` por PR | ninguno |
| `hotfix/*` del fork | `main` del fork | `meltiruiz:main` por PR, y después `main` y `develop` del fork se igualan a `upstream/main` | APK de `build-apk.yml` |
| `main` del fork | no aplica | se iguala a `upstream/main` con `git push origin upstream/main:main` | ninguno |
| `main` de meltiruiz | PR de versión desde `jeffangeloss:develop`, PR de hotfix o PR del equipo | no aplica | APK de `build-apk.yml` |

La rama `develop` del fork acepta cambios solo por PR con el check `pruebas` en verde. No admite force
push ni borrado, no exige aprobaciones porque el dueño trabaja solo, y `enforce_admins` queda en `false`,
de modo que el dueño puede saltar la regla en una emergencia. La rama `main` del fork solo se protege
contra force push y borrado, porque se iguala a producción con un push directo. Este diseño no agrega
reglas de rama en meltiruiz, porque el dueño no es admin allí, y el equipo conserva sus ramas por
persona.

## Publicar una versión

Las versiones siguen SemVer y cada una lleva un tag `vX.Y.Z` en meltiruiz. El tag `v1.0.0` marca el
estado de producción al 2026-10-01 (APK build 77, commit `2058957`). Una corrección sube el tercer
número de la versión, una función compatible sube el segundo y un cambio incompatible sube el primero.

La versión vive en `pubspec.yaml` como `version: X.Y.Z+1`. El sufijo `+1` no se toca, porque
`build-apk.yml` fija el número de build con `--build-number`. En cada push a `main` de meltiruiz, el
workflow lee `X.Y.Z` de `pubspec.yaml` y compila con `--build-name=X.Y.Z` y con el número de ejecución
como `--build-number`. Después actualiza el release `latest` como antes y, si el release `vX.Y.Z` no
existe, lo crea con el APK adjunto y sin marcarlo como el último. Un push a `main` que no sube `version`
actualiza solo `latest`, porque `vX.Y.Z` ya existe. Si la línea `version:` no trae `X.Y.Z`, el workflow
falla antes de compilar con un `::error::` que lo dice. El release `vX.Y.Z` solo se crea cuando el
workflow corre sobre `main`, de modo que un disparo manual desde otra rama no publica versiones.

La compilación también recibe `--dart-define=APP_VERSION=X.Y.Z`, y la app usa ese valor como su
versión instalada para avisar de una versión nueva, así que una build sin él, como las de desarrollo,
no avisa. Al crear el release `vX.Y.Z`, el workflow sube además `version.json` (versión, número de
build y dirección del APK) al release `latest` con `gh release upload latest version.json --clobber`,
y la app lo lee para saber cuál es la última versión. Un push a `main` que no sube `version` no lo
toca.

Para publicar una versión nueva se siguen estos pasos.

1. Crear la rama de versión desde `develop` actualizado.

   ```bash
   git switch develop
   git pull origin develop
   git switch -c chore/version-X.Y.Z
   ```

2. Subir `version` en `pubspec.yaml` a `X.Y.Z+1` y agregar al `CHANGELOG.md` una sección
   `## [X.Y.Z] - <fecha>` con la fecha de publicación (año, mes y día) y lo que cambia desde la
   versión anterior, más la línea de enlace al pie del archivo,
   `[X.Y.Z]: https://github.com/meltiruiz/ULima_Frontend_IS2/compare/vA.B.C...vX.Y.Z`, donde `vA.B.C`
   es el tag de la versión anterior.
3. Subir la rama, abrir un PR a `develop`, esperar el check `pruebas` en verde y fusionarlo.
4. Abrir el PR de versión hacia producción, titulado «Versión X.Y.Z», con la sección del
   `CHANGELOG.md` como cuerpo.

   ```bash
   gh pr create -R meltiruiz/ULima_Frontend_IS2 --base main --head jeffangeloss:develop \
     --title "Versión X.Y.Z" --body-file <archivo con la sección del CHANGELOG>
   ```

   El PR se fusiona con merge commit, y no con squash ni rebase, para que `develop` siga siendo
   ancestro de `main` y el paso 6 sea un fast-forward.
5. Esperar a que `build-apk.yml` termine en meltiruiz y comprobar que el release `vX.Y.Z` aparece con
   el archivo `ULimaPlus-build-<n>.apk` adjunto. Luego confirmar que https://github.com/meltiruiz/ULima_Frontend_IS2/releases/download/latest/version.json muestra la nueva versión; si no es así (falló la carga o un push más reciente canceló la ejecución), regenerar `version.json` con el mismo printf del archivo `.github/workflows/build-apk.yml` y ejecutar `gh release upload latest version.json --clobber -R meltiruiz/ULima_Frontend_IS2`.
6. Igualar `main` y `develop` del fork con meltiruiz.

   ```bash
   git fetch upstream
   git push origin upstream/main:main
   git push origin upstream/main:develop
   ```

   El segundo push escribe en una rama protegida y funciona por el bypass de administrador del dueño
   (`enforce_admins` en `false`), así que solo el dueño lo hace. Es un fast-forward mientras `develop`
   no tenga commits que `main` no tiene. Si ya los tiene, el push se rechaza y no se fuerza. Entonces
   `main` entra a `develop` por un merge dentro de un PR `chore/sync-main`.

## Hotfix

Un hotfix corrige un defecto de producción sin esperar lo que hay en `develop`. Sale de `main`, que en
el fork es igual a `upstream/main`.

1. Crear la rama desde `upstream/main`.

   ```bash
   git fetch upstream
   git switch -c hotfix/<descripcion> upstream/main
   ```

2. Corregir el defecto, subir el tercer número de `version` en `pubspec.yaml` (de `1.1.0+1` a
   `1.1.1+1`, por ejemplo) y agregar su sección al `CHANGELOG.md`.
3. Subir la rama con `git push origin hotfix/<descripcion>` y abrir el PR
   `jeffangeloss:hotfix/<descripcion>` hacia `meltiruiz:main`, titulado «Versión X.Y.Z» con la versión
   nueva. Se fusiona con merge commit.
4. Cuando `build-apk.yml` publica el release, igualar el fork con los tres comandos del paso 6 de la
   sección anterior. Si `develop` ya tiene commits propios, el hotfix vuelve a `develop` por el merge
   de `main` dentro de un PR `chore/sync-main`.

## CI

El archivo `.github/workflows/ci.yml` define el workflow `CI`, que tiene un solo job, `pruebas`. Corre en
cada pull request a `develop` o a `main` y en cada push a `develop`. En meltiruiz corre en los PR a
`main`, también en los del equipo, desde que la versión 1.1.0 lleva el archivo.

El job instala Flutter 3.44.2 y corre `flutter pub get`, `flutter analyze --no-fatal-infos` y
`flutter test`. Los errores y los warnings del análisis hacen fallar el job, y los avisos de nivel
`info` no. Si llegan dos ejecuciones sobre la misma referencia, la nueva cancela la anterior
(`concurrency`), y el workflow solo lee el contenido del repo (`permissions: contents: read`).

El nombre `pruebas` es el que exige la regla de rama de `develop` del fork, así que no se cambia sin
cambiar también la regla. Para repetir la CI en local, con Flutter 3.44.2 instalado, se corren los
mismos tres comandos.

```bash
flutter pub get
flutter analyze --no-fatal-infos
flutter test
```

## Versión de Flutter

La CI y el APK compilan con Flutter 3.44.2 del canal stable. El valor está en `flutter-version` de
`ci.yml` y de `build-apk.yml`, ambos con la acción `subosito/flutter-action@v2`. Subir la versión es un
cambio de un PR propio que edita los dos archivos a la vez, para que las pruebas y el APK usen siempre
la misma.

Hay una deuda abierta con esta versión. `pubspec.lock` está escrito con un Flutter más nuevo que el
3.44.2 (el local es 3.47.2), y con 3.44.2 `flutter pub get` cambia `matcher` (0.12.20 a 0.12.19),
`meta` (1.19.0 a 1.18.0), `test_api` (0.7.12 a 0.7.11) y `vector_math` (2.4.2 a 2.2.0), que el kit de
desarrollo (SDK) de Flutter fija por debajo de las del lock, de modo que la CI imprime «Changed 4
dependencies!». El cambio queda en el workspace de la ejecución y no se versiona. Para cerrar la
deuda, todo el equipo fija Flutter 3.44.2 en su máquina, por ejemplo con FVM (Flutter Version
Management) y un `.fvmrc` en la raíz, o la CI y `build-apk.yml` suben juntos a una versión más nueva.
Mientras tanto, los resultados locales con otra versión son solo orientativos, porque el análisis
puede reportar avisos distintos y las dependencias resueltas difieren, y la CI manda.

## Modo estático

La app tiene dos modos. El estático la desconecta de la Universidad de Lima y oculta los datos que
vinieron de ella, y el dinámico se comporta como la 1.2.0. Desde la 2.1.0 el modo lo decide el
backend con la fila `app_setting` de la base, y la app lo lee de `GET /config` al abrirse, al volver a
primer plano, ante las respuestas `PORTAL_DESACTIVADO` o `REGISTRATION_UNAVAILABLE` y cuando la
respuesta del arranque llega tarde. El modo que rige vive en `ModoEstatico.activo`
(`lib/configs/modo_estatico.dart`), y lo fija `InterruptorRemoto`
(`lib/pages/splash/interruptor_remoto.dart`).

Para alternar, en la consola de Neon del proyecto de ULima++ se elige la rama (producción o
`develop`), se abre la tabla `app_setting`, se cambia `static_mode` a `true` (estática) o a `false`
(dinámica) y se guarda. El backend aplica el modo nuevo en unos 10 s, y cada app 2.1.0 lo toma al
abrirse o al volver a primer plano. Con la app abierta, un cambio la lleva al Horario del inicio o a
la bienvenida y toda pantalla se reconstruye con el modo nuevo. Una bienvenida ya abierta no se
vuelve a abrir, sigue en su turno y muestra u oculta «Soy nuevo» al momento, porque
`ModoEstatico.fijar` avanza la señal `ModoEstatico.cambios`, que leen sus Obx y el recibimiento. Un
registro abierto, en cambio, vuelve a E1 al pasar a estática, porque esa versión no tiene registro. El
procedimiento completo y la comprobación con `curl` están en el `docs/devops.md` del backend.

Si la fila de producción queda en `false` por mucho tiempo, conviene poner también
`MODO_ESTATICO=false` en Vercel y redesplegar el backend. Una instancia fría del backend que no puede
leer la base responde con su respaldo, que es esa variable, y mientras siga en `true` una APK 2.1.0
podría volver un rato al modo estático.

Sin respuesta del backend, la app usa el último modo que conoce, guardado en la clave
`modo_estatico_conocido`, y si nunca recibió uno usa el de compilación. `MODO_ESTATICO` de
`--dart-define` queda solo como ese respaldo de fábrica. `build-apk.yml` compila con
`--dart-define=MODO_ESTATICO=true`, así que una APK recién instalada y sin red arranca estática. El
workflow `Build and Release APK` del fork sigue desactivado a propósito, y el APK solo sale del
repositorio de producción (`meltiruiz/ULima_Frontend_IS2`).

En local, el define fija el respaldo de una instalación sin modo guardado, y la respuesta de
`GET /config` manda sobre él.

```bash
flutter run --dart-define=API_BASE_URL=<URL del backend>
flutter run --dart-define=API_BASE_URL=<URL del backend> --dart-define=MODO_ESTATICO=true
```

Las pruebas fijan `ModoEstatico.activo` en cada caso y lo restauran al terminar, y las del interruptor
llaman a `InterruptorRemoto.reiniciar()`, de modo que `flutter test` cubre los dos modos sin ninguna
bandera. La APK 2.0.0 queda estática hasta actualizar, aunque el backend pase a dinámico, y la 1.2.0
no conoce el modo. El orden de publicación sigue siendo el backend primero y la app después, porque
sin `GET /config` la app usa su respaldo.

## Build de depuración contra pruebas

El APK de `build-apk.yml` apunta siempre a producción, porque compila con un
`--dart-define=API_BASE_URL` fijo, y la app no tiene un entorno de pruebas propio. Para probar un cambio
contra el backend de pruebas, que es la rama `develop` del backend desplegada como Vercel Preview con su
propia base de datos, se pasa la URL en una build de depuración.

```bash
flutter run --dart-define=API_BASE_URL=<URL de develop del backend>
```

La URL vigente está en la sección de entornos del `docs/devops.md` del backend
(`jeffangeloss/ULima_Backend_IS2`). Una build `release` sin `API_BASE_URL` falla en la primera petición
a propósito, para que ninguna build apunte a un servidor por omisión.
