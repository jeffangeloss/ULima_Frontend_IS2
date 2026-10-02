# Registro de cambios

Este archivo reúne los cambios relevantes de la app ULima++. Su formato sigue
[Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/) y las versiones siguen
[SemVer](https://semver.org/lang/es/). Cada versión lleva un tag `vX.Y.Z` en
`meltiruiz/ULima_Frontend_IS2`, el repositorio de producción. El flujo de ramas y la forma de
publicar una versión están en [`docs/devops.md`](docs/devops.md).

## [2.0.0] - 2026-10-02

La versión estática. La app deja de consultar a la Universidad de Lima y oculta lo que dependía de ella.
Es una versión mayor porque retira funcionalidades.

### Añadido

- Interruptor `MODO_ESTATICO`, leído de `--dart-define` en `lib/configs/modo_estatico.dart` y apagado por
  defecto. El código del portal sigue en el repositorio, apagado detrás de él, y retirarlo queda para una
  versión posterior.
- Spec `modo-estatico` con RF-EST-7 a RF-EST-14 y pruebas de los dos modos en `test/modo_estatico/`.

### Cambiado

- `build-apk.yml` compila con `--dart-define=MODO_ESTATICO=true`.
- En modo estático la bienvenida solo ofrece iniciar sesión, sin «Soy nuevo» ni pasos que pidan la
  contraseña de miUlima o el código SecurID.
- En modo estático no hay importación del portal (`/portal-sync`, el banner del inicio y la tarjeta del
  Perfil) ni recarga de notas y asistencia, y el arranque no registra `RecargaUlimaService` ni
  `AcademicRecordService`.
- En modo estático se ocultan los datos oficiales de la ULima. Son el récord, las notas de la ULima, las
  filas oficiales de la calculadora, que queda simulada, el bloque de asistencia de la ficha del curso y
  el riesgo de asistencia, también el de las alertas «Alerta de inasistencias - <curso>», que no llegan
  a la campana ni al buzón. `/portal-sync`, `/mi-record` y `/mis-notas` llevan al inicio.
- En modo estático el Perfil del alumno trae «Borrar mi récord de ULima++», para que pueda borrar la
  copia del récord que sigue guardada en el servidor (RF-REC-5) sin mostrar el récord.
- En modo estático el visor de sílabos abre solo enlaces de Drive. Ante otra URL dice «Sílabo no
  disponible» y no abre el navegador.
- `pubspec.yaml` pasa a `version: 2.0.0+1`.

## [1.2.0] - 2026-10-02

### Añadido

- Aviso de versión nueva. Cuando termina la intro del arranque, la app de Android consulta
  `version.json` en el release `latest`, en segundo plano y con un tope de 5 s. Si la versión
  publicada es mayor que la instalada, un diálogo dice «Hay una versión nueva» y ofrece
  «Descargar», que abre el APK nuevo, y «Más tarde», que guarda esa versión para que el aviso
  vuelva solo con una mayor. Sin red, con una respuesta inválida, en web, en iOS y en builds de
  desarrollo no pasa nada. La 1.1.0 no trae este código, así que quien la tiene instala la 1.2.0 a
  mano una vez.
- `build-apk.yml` publica `version.json` en el release `latest` cada vez que crea el release de una
  versión nueva. El archivo lleva la versión, el número de build y la dirección del APK, y un push a
  `main` sin cambio de versión no lo toca.

### Cambiado

- `pubspec.yaml` pasa a `version: 1.2.0+1`.
- El APK conoce su versión instalada. `build-apk.yml` compila con `--dart-define=APP_VERSION=X.Y.Z`,
  tomado del paso que ya lee la versión de `pubspec.yaml`, y la app lo compara con la versión
  publicada.
- `docs/devops.md` explica `version.json` y `APP_VERSION`.

## [1.1.0] - 2026-10-02

### Añadido

- Integración continua en `.github/workflows/ci.yml`. El job `pruebas` corre `flutter pub get`,
  `flutter analyze --no-fatal-infos` y `flutter test` con Flutter 3.44.2 en cada pull request (PR) a
  `develop` o a `main` y en cada push a `develop`.
- Rama `develop` del fork como rama de integración. Las ramas de trabajo salen de ella y vuelven por
  PR, y cada versión llega a `main` de meltiruiz con un PR de versión desde `jeffangeloss:develop`.
- Release por versión. Después de publicar el release `latest`, `build-apk.yml` crea el release
  `vX.Y.Z` con el instalador de Android (APK) adjunto si todavía no existe y solo cuando corre sobre
  `main`, sin marcarlo como el último y sin tocar `latest`.
- `docs/devops.md`, con las ramas, la publicación de una versión, el hotfix, la integración continua, la
  versión de Flutter y la forma de apuntar una build de depuración al entorno de pruebas del backend.

### Cambiado

- `pubspec.yaml` pasa a `version: 1.1.0+1`.
- El APK declara su versión y su número de build. `build-apk.yml` lee la versión de `pubspec.yaml` y
  compila con `--build-name` igual a esa versión (`1.1.0`) y `--build-number` igual al número de
  ejecución del workflow, que es el mismo que lleva el archivo `ULimaPlus-build-<n>.apk`.
- El job `build-android` de `build-apk.yml` corre solo en `meltiruiz/ULima_Frontend_IS2`. El fork no
  compila ni publica APK aunque active el workflow.
- `README.md` describe los dos workflows, la versión `1.1.0` y el número de build que fija la
  integración continua, y ya no dice que esta no prueba nada.

## [1.0.0] - 2026-10-01

Estado de producción al 2026-10-01 (commit `2058957`), que corresponde al APK build 77. El tag `v1.0.0`
le pone nombre a lo que ya corría, porque `pubspec.yaml` ya declaraba `1.0.0+1`. Los números de PR de
esta sección son de `meltiruiz/ULima_Frontend_IS2`.

### Añadido

- App Flutter con GetX sobre el backend de ULima++, con APK de Android firmado y publicado en el
  release `latest`. El alumno tiene la malla curricular con prerrequisitos y simulación de avance, la
  calculadora de notas personales, las notas oficiales en solo lectura y el horario semanal con
  evaluaciones y carga académica. También tiene las asesorías con confirmación de asistencia, los
  anuncios de sección, el buzón de alertas, los contactos del salón, el chat de sección en vivo, el
  carnet de networking, el visor de sílabo y ULimaBot, un asistente que responde en lenguaje natural.
  Los docentes y jefes de práctica entran con las mismas credenciales y reciben su propia barra de
  navegación. Esta descripción sale del `README.md`.
- Registro de cuenta contra miUlima, con acceso desde el login (meltiruiz/ULima_Frontend_IS2#174).
- Récord académico. El Perfil muestra una tarjeta con el PPA, la ubicación relativa y los créditos, y
  una pantalla propia lista los cursos ciclo por ciclo. El alumno puede borrar su copia y acepta un
  consentimiento antes de entregar su contraseña de miUlima (#176).
- Bloques de horario propios. Un formulario pide nombre, color, días, horas y fechas, un aviso señala
  los cruces, las vistas de día y de semana pintan los bloques y una hoja de cinco acciones se abre al
  tocar uno. La lista «Mis bloques» permite editar o borrar los bloques guardados (#177 y #178).
- Chats de curso. La pestaña «Chats» de la barra inferior del alumno reúne una bandeja por curso, la
  ficha de cada curso trae el botón «Chat del curso», y cada participante borra sus propios mensajes
  (#179).
- Truco del 67 en el chat de Ulises y en los chats de sección. La pantalla se inclina unos 2 segundos y
  aparece «SIX SEVEN!!!», salvo con «Quitar animaciones» o «Reducir movimiento» (#180).
- Test de especialidad conversando con Ulises. Son 14 preguntas con hasta dos desempates, y la
  recomendación entre las cuatro especialidades oficiales trae su porcentaje, su motivo y sus
  electivos. El alumno puede saltarlo y rehacerlo desde el Perfil (#181).
- Recarga de notas parciales y asistencia desde la ULima, con el botón «Actualizar desde la ULima» en
  `/mis-notas` y junto a la asistencia de cada curso. La app no guarda las credenciales, y las notas
  de la ULima entran al promedio de la calculadora como filas marcadas (#182).
- Splash animado con tres intros del logo al azar y bienvenida con Ulises, donde el login, el registro
  y el test de especialidad forman una sola conversación hasta el Horario (#183).

### Corregido

- Malla. Un electivo aparece en cada diploma de especialidad al que pertenece, y no solo en el
  primero (#175).
- Un bloque de horario sin ningún día real dentro de sus fechas ya no se guarda (#178).
- El teclado ya no tapa la pregunta de Ulises en la bienvenida (#184).

[2.0.0]: https://github.com/meltiruiz/ULima_Frontend_IS2/compare/v1.2.0...v2.0.0
[1.2.0]: https://github.com/meltiruiz/ULima_Frontend_IS2/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/meltiruiz/ULima_Frontend_IS2/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/meltiruiz/ULima_Frontend_IS2/releases/tag/v1.0.0
