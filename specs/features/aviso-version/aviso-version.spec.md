---
name: Aviso de versión nueva
description: Diálogo que avisa en Android de que existe un APK más nuevo y ofrece su descarga, con la versión instalada que incrusta la compilación y el version.json que publica el workflow del APK
targets:
  - ../../../lib/domain/aviso_version/version_semver.dart
  - ../../../lib/models/version_publicada_model.dart
  - ../../../lib/services/aviso_version_service.dart
  - ../../../lib/components/aviso_version/aviso_version_dialog.dart
  - ../../../lib/pages/splash/aviso_version_arranque.dart
  - ../../../lib/main.dart
  - ../../../.github/workflows/build-apk.yml
  - ../../../pubspec.yaml
  - ../../../CHANGELOG.md
  - ../../../docs/devops.md
---

# Aviso de versión nueva del APK

> Estado: diseñada y aprobada por el dueño el 2026-10-02, con dos decisiones explícitas. El aviso
> se puede posponer y nunca bloquea, y la app lee la última versión de un archivo `version.json`
> publicado en el release `latest`, no de la API de GitHub ni del backend.

## Objetivo

Quien usa el APK se entera de que existe una versión más nueva sin buscarla en GitHub. El aviso
aparece una vez por versión, ofrece la descarga y desaparece si la persona elige posponerlo.

## User Stories

- Como alumno con el APK instalado, quiero enterarme de que hay una versión nueva sin buscarla en
  GitHub.
- Como alumno, quiero posponer el aviso y no volver a verlo hasta que salga una versión mayor.

## Requisitos

### RF-AVV-1. Una consulta por arranque

La app consulta
`https://github.com/meltiruiz/ULima_Frontend_IS2/releases/download/latest/version.json` una sola
vez por arranque, después de que la capa de arranque termina, en segundo plano y con un tope de
5 s. La consulta corre solo en Android y solo si la build trae `APP_VERSION`; en web, iOS y builds
de desarrollo no ocurre nada.


### RF-AVV-2. Comparación SemVer

Las versiones se comparan como SemVer `X.Y.Z`, componente por componente y en número, así que
`1.10.0` es mayor que `1.9.0`.

`[@test] ../../../test/aviso_version/version_semver_test.dart`

### RF-AVV-3. El aviso

Si la versión publicada es mayor que la instalada y que la pospuesta, cuando hay una guardada,
aparece un diálogo con el estilo de los diálogos existentes, título «Hay una versión nueva», texto
«ULima++ {publicada} ya está disponible. Tienes la {instalada}.» y los botones «Más tarde» y
«Descargar».

### RF-AVV-4. Más tarde

«Más tarde» guarda la versión publicada en `shared_preferences` con la clave
`aviso_version_pospuesta` y cierra el diálogo. El aviso vuelve solo con una versión mayor.

### RF-AVV-5. Descargar

«Descargar» abre la URL del APK con `url_launcher` en modo aplicación externa y cierra el diálogo,
sin guardar nada, de modo que el aviso reaparece en el siguiente arranque si la persona no
actualizó.

### RF-AVV-6. Fallas en silencio

Sin red, con un tiempo de espera vencido, una respuesta distinta de 200, un JSON mal formado o una
versión inválida, la app no muestra nada ni registra un error visible.

### RF-AVV-7. version.json en cada versión nueva

Cuando `build-apk.yml` crea un release `vX.Y.Z` nuevo, sube al release `latest` un `version.json`
con
`{"version": "X.Y.Z", "build": N, "url": "https://github.com/meltiruiz/ULima_Frontend_IS2/releases/download/vX.Y.Z/ULimaPlus-build-N.apk"}`
(`gh release upload latest version.json --clobber`). Un build sin cambio de versión no toca el
archivo.

### RF-AVV-8. APP_VERSION en la compilación

`build-apk.yml` compila con `--dart-define=APP_VERSION=X.Y.Z`, tomado del mismo paso que ya lee la
versión de `pubspec.yaml`.

## Piezas

| Pieza | Archivo | Responsabilidad |
|---|---|---|
| comparador de versiones | `lib/domain/aviso_version/version_semver.dart` | función pura que ordena dos `X.Y.Z` y rechaza las cadenas inválidas |
| versión publicada | `lib/models/version_publicada_model.dart` | lee y valida el contenido de `version.json` |
| servicio del aviso | `lib/services/aviso_version_service.dart` | descarga `version.json` con un cliente `http` inyectable y decide si corresponde avisar a partir de la versión instalada y la pospuesta |
| diálogo | `lib/components/aviso_version/aviso_version_dialog.dart` | presenta el aviso y resuelve los dos botones |
| enganche en el arranque | `lib/pages/splash/aviso_version_arranque.dart`, `lib/main.dart` | lanza la consulta una vez, sin esperar su resultado para mostrar la app |
| `build-apk.yml` | `.github/workflows/build-apk.yml` | publica `version.json` e incrusta `APP_VERSION` |

## Decisiones de implementación

Estas decisiones completan los requisitos sin cambiarlos.

- El enganche escucha `EstadoDeLaCapa.cubre`, la misma señal con la que `HomePage` espera el retiro
  de la capa (RF-SPL-20). La consulta empieza la primera vez que la capa pasa de cubrir la pantalla
  a no cubrirla, y no vuelve a empezar cuando el paso al horario de la bienvenida la usa de nuevo.
  `main()` crea el enganche solo en la rama móvil, después de `runApp`, así que web no lo monta.
- El enganche no registra nada cuando `APP_VERSION` viene vacía ni cuando la plataforma no es
  Android. Un APK de desarrollo y un iPhone nunca piden `version.json`.
- `version.json` es válido cuando `version` es una cadena `X.Y.Z`, `build` es un entero no
  negativo y `url` es una URL `https` absoluta con servidor. Con cualquier otro valor se aplica
  RF-AVV-6.
- El servicio no distingue por tipo de falla. Cualquier excepción de red, de lectura o de
  `shared_preferences` termina en «no avisar».
- Cerrar el diálogo con un toque fuera de él o con el botón atrás no guarda nada ni abre nada,
  como los demás diálogos de la app. El aviso vuelve en el siguiente arranque.
- La fuente de `version.json` se puede cambiar solo al construir el servicio, para las pruebas. La
  app no ofrece ningún ajuste para eso.

## Pruebas

Las pruebas viven en `test/aviso_version/`. Cubren el comparador (mayor, menor, igual, `1.10.0`
contra `1.9.0` e inválidas), el servicio con `http` simulado (respuesta correcta, 404, JSON roto,
versión inválida y tiempo vencido), la decisión (sin versión instalada, publicada igual o menor,
pospuesta igual o mayor), el diálogo (los dos botones, la clave guardada y la URL abierta por una
función simulada) y el enganche (una sola consulta, después de la capa, sin consulta con la
versión instalada vacía).

## Entrega

El trabajo sigue el flujo de `docs/devops.md`. La rama `feat/aviso-version` sale de `develop` del
fork y vuelve por PR con la CI en verde. La versión sube a 1.2.0 en `pubspec.yaml` y en
`CHANGELOG.md`, y el PR `jeffangeloss:develop` a `meltiruiz:main` se fusiona solo con el visto
bueno del dueño. Tras el merge, el APK 1.2.0 trae el aviso y `version.json` anuncia la 1.2.0.

## Límites

Quien tiene la 1.1.0 no recibe el aviso, porque su APK no trae el código, y tiene que instalar la
1.2.0 a mano una vez. Desde la 1.2.0 el aviso cubre todas las versiones siguientes. Las versiones
obligatorias, el aviso en iOS y la descarga dentro de la app quedan fuera de alcance.

## Verificación

- `flutter analyze --no-fatal-infos` sin avisos nuevos.
- `flutter test` completo.
- Revisión manual en un teléfono Android, después de que exista `version.json` en el release
  `latest`. Al terminar la intro aparece el diálogo con la versión publicada.

  ```bash
  flutter run --dart-define=APP_VERSION=1.0.0 --dart-define=API_BASE_URL=<URL del backend>
  ```
