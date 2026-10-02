# DevOps del front de ULima++

Este documento explica cómo se ramifica, se integra y se publica la app Flutter de ULima++. Cubre las
ramas, la publicación de una versión, el hotfix, la integración continua, la versión de Flutter y la
forma de apuntar una build de depuración al entorno de pruebas del backend. Todo lo que hace falta para
repetir esos pasos queda en este repo, en `.github/workflows/`, `pubspec.yaml` y `CHANGELOG.md`.

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
estado de producción al 2026-10-01 (APK build 77, commit `2058957`). Una versión nueva sube PATCH para
una corrección, MINOR para una función compatible y MAJOR para un cambio incompatible.

La versión vive en `pubspec.yaml` como `version: X.Y.Z+1`. El sufijo `+1` no se toca, porque
`build-apk.yml` fija el número de build con `--build-number`. En cada push a `main` de meltiruiz, el
workflow lee `X.Y.Z` de `pubspec.yaml` y compila con `--build-name=X.Y.Z` y con el número de ejecución
como `--build-number`. Después actualiza el release `latest` como antes y, si el release `vX.Y.Z` no
existe, lo crea con el APK adjunto y sin marcarlo como el último. Un push a `main` que no sube `version`
actualiza solo `latest`, porque `vX.Y.Z` ya existe.

Para publicar una versión nueva se siguen estos pasos.

1. Crear la rama de versión desde `develop` actualizado.

   ```bash
   git switch develop
   git pull origin develop
   git switch -c chore/version-X.Y.Z
   ```

2. Subir `version` en `pubspec.yaml` a `X.Y.Z+1` y agregar al `CHANGELOG.md` la sección
   `## [X.Y.Z] - AAAA-MM-DD`, que describe lo que cambia desde la versión anterior.
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
   el archivo `ULimaPlus-build-<n>.apk` adjunto.
6. Igualar `main` y `develop` del fork con meltiruiz.

   ```bash
   git fetch upstream
   git push origin upstream/main:main
   git push origin upstream/main:develop
   ```

   El segundo push es un fast-forward mientras `develop` no tenga commits que `main` no tiene. Si ya
   los tiene, el push se rechaza y no se fuerza. Entonces `main` entra a `develop` por un merge dentro
   de un PR `chore/sync-main`.

## Hotfix

Un hotfix corrige un defecto de producción sin esperar lo que hay en `develop`. Sale de `main`, que en
el fork es igual a `upstream/main`.

1. Crear la rama desde `upstream/main`.

   ```bash
   git fetch upstream
   git switch -c hotfix/<descripcion> upstream/main
   ```

2. Corregir el defecto, subir el PATCH de `version` en `pubspec.yaml` (de `1.1.0+1` a `1.1.1+1`, por
   ejemplo) y agregar su sección al `CHANGELOG.md`.
3. Subir la rama con `git push origin hotfix/<descripcion>` y abrir el PR
   `jeffangeloss:hotfix/<descripcion>` hacia `meltiruiz:main`, titulado «Versión X.Y.Z» con el PATCH
   nuevo. Se fusiona con merge commit.
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
la misma. Un Flutter local de otra versión da resultados orientativos, porque el análisis puede
reportar avisos distintos, y la CI manda.

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
a propósito, así que ninguna build sale hacia un servidor que nadie eligió.
