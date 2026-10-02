---
name: Versión estática de ULima++ (front)
description: Interruptor MODO_ESTATICO de la app que la desconecta de la Universidad de Lima y oculta los datos que vinieron de ella, con RF-EST-7 a RF-EST-14
targets:
  - ../../../lib/configs/modo_estatico.dart
  - ../../../lib/main.dart
  - ../../../lib/pages/bienvenida/bienvenida_controller.dart
  - ../../../lib/pages/bienvenida/widgets/compositor.dart
  - ../../../lib/pages/bienvenida/widgets/recibimiento.dart
  - ../../../lib/pages/home/home_controller.dart
  - ../../../lib/pages/home/home_page.dart
  - ../../../lib/pages/perfil/perfil.dart
  - ../../../lib/pages/academic_record/borrar_record_estatico.dart
  - ../../../lib/services/academic_record_service.dart
  - ../../../lib/services/alert_service.dart
  - ../../../lib/pages/splash/carga_del_arranque.dart
  - ../../../lib/pages/calculadora/calculadora_controller.dart
  - ../../../lib/pages/calculadora/calculadora_page.dart
  - ../../../lib/pages/mis_notas/mis_notas_controller.dart
  - ../../../lib/pages/descripcion_cursos/descrip_cursos.dart
  - ../../../lib/pages/horario/horario.dart
  - ../../../lib/pages/teacher/at_risk_students_page.dart
  - ../../../lib/pages/silabo/silabo_viewer_controller.dart
  - ../../../lib/pages/silabo/silabo_viewer_page.dart
  - ../../../.github/workflows/build-apk.yml
  - ../../../pubspec.yaml
  - ../../../CHANGELOG.md
  - ../../../docs/devops.md
  - ../../../README.md
---

# Versión estática de ULima++ (front)

> Estado: diseño aprobado por el dueño el 2026-10-02 con cuatro decisiones explícitas. La versión
> estática reemplaza a la actual mediante un interruptor y no convive con ella, el registro queda
> cerrado, los datos oficiales que vinieron de la ULima se ocultan y el riesgo de asistencia también
> se oculta. El diseño y la evidencia por archivo están en el repo privado del proyecto
> (`docs/specs/2026-10-02-version-estatica-design.md` y `-mapa.md`). Esta spec cubre el front y el
> backend tiene la suya, con RF-EST-1 a RF-EST-6.

## Objetivo

La app no consulta ningún sistema de la Universidad de Lima (miUlima, Aula Virtual ni cactus) y no
muestra funcionalidades que dependan de ellos. El código del portal queda apagado detrás de un
interruptor, no borrado, de modo que el cambio sale por el flujo de versiones existente y se revierte
sin revertir commits. Retirar ese código queda para una versión mayor posterior.

## User Stories

- Como alumno, quiero una app que no me pida la contraseña de miUlima ni el código de mi
  authenticator, para no entregar credenciales de la Universidad a un tercero.
- Como dueño del producto, quiero apagar todo lo que depende de la ULima con una sola constante de
  compilación, para publicarlo con el flujo de versiones y poder revertirlo sin tocar commits.

## Requisitos

### RF-EST-7. Un único punto de lectura

La app lee `MODO_ESTATICO` de `--dart-define`, con `false` por defecto, en `ModoEstatico.activo`
(`lib/configs/modo_estatico.dart`). Ningún otro archivo lee la variable. Las pruebas fijan el valor
en cada caso y lo restauran al terminar.

`[@test] ../../../test/modo_estatico/modo_estatico_test.dart`

> Enmienda de RF-IRM-12 (spec `interruptor-remoto`, 2026-10-02). El valor de `--dart-define` pasa a
> ser el respaldo de fábrica, `ModoEstatico.deCompilacion`. `ModoEstatico.activo` arranca en él y lo
> fija el interruptor remoto con lo que responde `GET /config`. `modo_estatico.dart` sigue siendo el
> único lector de la variable.

### RF-EST-8. La bienvenida solo ofrece iniciar sesión

En modo estático la bienvenida no ofrece «Soy nuevo» ni ningún paso que pida credenciales de
miUlima o SecurID. El recibimiento, el compositor del código y el de la contraseña no traen el botón
ni el enlace, y las acciones `soyNuevo` y `responderAlSaludo(yaUsa: false)` no abren el registro.
Solo queda el inicio de sesión con código, con Google y la recuperación de contraseña.

`[@test] ../../../test/modo_estatico/bienvenida_estatica_test.dart`

### RF-EST-9. Sin importación ni recarga desde la ULima

En modo estático desaparecen la importación del portal (`/portal-sync`, `_PortalSyncBanner` del
inicio y `_CargarDesdeMiUlimaCard` del Perfil) y la recarga de notas y asistencia (componentes de
`recarga_ulima` y sus botones). Ningún servicio de esas funciones se registra ni hace peticiones:
`registrarLosServicios` no registra `AcademicRecordService` ni `RecargaUlimaService`, y
`HomeController` no crea `PortalSyncService` ni pide `/portal-sync/status`.

`[@test] ../../../test/modo_estatico/arranque_estatico_test.dart`
`[@test] ../../../test/modo_estatico/inicio_y_perfil_estaticos_test.dart`

> Enmienda de RF-IRM-11 (spec `interruptor-remoto`, 2026-10-02). `registrarLosServicios` registra
> `AcademicRecordService` y `RecargaUlimaService` en los dos modos, sin peticiones al registrarse, de
> modo que el paso de estático a normal no deja ningún `Get.find` sin servicio. El resto de la regla
> sigue vigente.

### RF-EST-10. Los datos oficiales de la ULima no se muestran

En modo estático se ocultan los datos oficiales que vinieron de la ULima. Son el récord (`/mi-record`
y `RecordProfileCard`), las notas de la ULima (`/mis-notas` y las filas oficiales de la calculadora,
que queda en modo simulado), el bloque de asistencia de la ficha del curso (`PieAsistencia` y la
fecha de última lectura) y el riesgo de asistencia en toda pantalla donde aparezca, que son el botón
con su contador en la ficha de sección del docente, `AtRiskStudentsPage` y las alertas «Alerta de
inasistencias - <curso>» que el backend creó con la asistencia leída de miUlima. Ninguna petición a
`/attendance-risk/*`.

`AlertService.fetchAlerts` descarta en modo estático las alertas cuyo título empieza por «Alerta de
inasistencias - », de modo que ni la campana, ni el contador de sin leer, ni `/alertas` las muestran,
aunque el servidor las siga guardando. Las demás alertas (promedio, alta carga) siguen como siempre.

**Excepción a la ocultación, RF-REC-5.** La copia del récord que el alumno importó de miUlima sigue
guardada en el servidor, así que el Perfil del alumno trae, en modo estático, el botón «Borrar mi
récord de ULima++». Pide confirmación, llama a `DELETE /academic-record/me` sin mostrar el récord ni
volver a pedirlo (`GET /academic-record/me` no se llama y `AcademicRecordService` no se registra) y avisa
«Tu récord se borró de ULima++.», o «No se pudo borrar tu récord. Inténtalo de nuevo.» si el servidor
falla. El docente no lo ve. Con el modo apagado el Perfil no lo trae, porque el botón de siempre vive
en `/mi-record`.

`[@test] ../../../test/modo_estatico/inicio_y_perfil_estaticos_test.dart`
`[@test] ../../../test/modo_estatico/ficha_y_calculadora_estaticas_test.dart`
`[@test] ../../../test/modo_estatico/riesgo_de_asistencia_estatico_test.dart`
`[@test] ../../../test/modo_estatico/alertas_estaticas_test.dart`
`[@test] ../../../test/modo_estatico/borrar_record_estatico_test.dart`

> Enmienda de RF-IRM-11 (spec `interruptor-remoto`, 2026-10-02). El arranque registra
> `AcademicRecordService` en los dos modos, así que deja de valer que no se registra, como dice la
> excepción RF-REC-5. El borrado del Perfil sigue sin mostrar el récord y sin pedir
> `GET /academic-record/me`, y la calculadora, la ficha del curso y `/mis-notas` siguen sin pedir
> `GET /grades/me/ulima` con `RecargaUlimaService` registrado.

### RF-EST-11. Las rutas ocultas llevan al inicio

En modo estático una navegación a una ruta oculta (`/portal-sync`, `/mi-record`, `/mis-notas`) lleva
al inicio (`/home`) mediante `OcultaEnModoEstatico`. Las pantallas del riesgo de asistencia no tienen
ruta con nombre, así que su entrada es el botón de la ficha de sección, que RF-EST-10 oculta, y
`AtRiskStudentsPage` regresa al inicio si se construye de todos modos.

`[@test] ../../../test/modo_estatico/modo_estatico_test.dart`
`[@test] ../../../test/modo_estatico/riesgo_de_asistencia_estatico_test.dart`

### RF-EST-12. El visor de sílabos solo abre Drive

En modo estático el visor de sílabos abre solo enlaces de Drive. Ante una URL que no es de Drive
muestra «Sílabo no disponible», sin los botones «Reintentar» ni «Abrir en Drive», y `abrirEnDrive` no
abre el navegador con la URL cruda.

`[@test] ../../../test/modo_estatico/silabo_estatico_test.dart`

### RF-EST-13. Con el modo apagado, la app es la 1.2.0

Con `MODO_ESTATICO=false` la app se comporta igual que la 1.2.0 y la suite existente pasa sin cambios
de expectativa. Cada prueba nueva corre también con el modo apagado y comprueba que lo oculto en
modo estático sigue visible. El aviso de versión (`aviso_version_arranque.dart`) funciona en ambos
modos y su suite no cambia.

`[@test] ../../../test/modo_estatico/modo_estatico_test.dart`
`[@test] ../../../test/modo_estatico/inicio_y_perfil_estaticos_test.dart`
`[@test] ../../../test/aviso_version/aviso_version_arranque_test.dart`

### RF-EST-14. El APK se compila en modo estático

`build-apk.yml` compila con `--dart-define=MODO_ESTATICO=true`, sin cambiar nada más del comando. La
versión pasa a 2.0.0 en `pubspec.yaml` (`2.0.0+1`) y en `CHANGELOG.md`. Este cambio llega a meltiruiz
con la versión 2.0.0 y el workflow sigue desactivado en el fork.

`[@test] ../../../test/modo_estatico/workflow_y_version_test.dart`

## Piezas

| Pieza | Archivo | Responsabilidad |
|---|---|---|
| interruptor | `lib/configs/modo_estatico.dart` | `ModoEstatico.activo`, la lista de rutas ocultas y `OcultaEnModoEstatico` |
| rutas | `lib/main.dart` | pone el middleware a `/portal-sync`, `/mi-record` y `/mis-notas` |
| arranque | `lib/pages/splash/carga_del_arranque.dart` | registra el récord y la recarga en los dos modos, sin peticiones (RF-IRM-11) |
| bienvenida | `lib/pages/bienvenida/**` | sin «Soy nuevo» y sin entrada al registro |
| inicio y Perfil | `lib/pages/home/**`, `lib/pages/perfil/perfil.dart` | sin banner, sin tarjeta de miUlima y sin tarjeta del récord |
| notas | `lib/pages/calculadora/**`, `lib/pages/mis_notas/mis_notas_controller.dart` | calculadora simulada y `/mis-notas` sin servicio |
| ficha del curso | `lib/pages/descripcion_cursos/descrip_cursos.dart` | sin bloque de asistencia |
| riesgo de asistencia | `lib/pages/horario/horario.dart`, `lib/pages/teacher/at_risk_students_page.dart`, `lib/services/alert_service.dart` | sin botón, sin petición, sin pantalla y sin sus alertas |
| borrado del récord | `lib/pages/academic_record/borrar_record_estatico.dart`, `lib/pages/perfil/perfil.dart` | «Borrar mi récord de ULima++» en el Perfil, sin mostrar el récord |
| sílabos | `lib/pages/silabo/**` | solo Drive y «Sílabo no disponible» |
| compilación | `.github/workflows/build-apk.yml` | `--dart-define=MODO_ESTATICO=true` |

## Decisiones de implementación

- El código del portal no se borra. Las pantallas, los servicios y los modelos de la importación, del
  registro, del récord y de la recarga siguen en `lib/` y solo dejan de montarse o de registrarse.
- Con el modo apagado, cada rama nueva queda en el camino de siempre, así que la suite existente no
  cambia de expectativa.
- `registro_service.dart` y `api_client.dart` no cambian: el registro deja de ser alcanzable desde la
  interfaz y la exención 401 de `/auth/register` sigue sirviendo a las pruebas del modo apagado.
  Enmienda de la decisión D-1 de la spec `interruptor-remoto` (2026-10-02). `api_client.dart` gana el
  oyente estático `ApiClient.alResponderConCodigo`, que no cambia lo que devuelve ni lo que lanza.
- El aviso de versión no depende del modo. `AvisoVersionArranque` se programa igual en `main()` y la
  ruta del splash no se toca, de modo que el arreglo del ticker en `dispose` del splash queda intacto.

## Pruebas

Las pruebas nuevas viven en `test/modo_estatico/` y fijan `ModoEstatico.activo` en cada caso. Cubren
el interruptor y las rutas, la bienvenida, el arranque y sus servicios, el inicio y el Perfil, la
ficha del curso y la calculadora, el riesgo de asistencia, el visor de sílabos y el workflow con la
versión. Cada una incluye el caso con el modo apagado.

## Entrega

La rama `feat/modo-estatico` sale de `develop` del fork y vuelve por PR con la CI en verde. El PR
«Versión 2.0.0» hacia `meltiruiz` se abre aparte y solo se fusiona con el visto bueno del dueño.

## Verificación

- `flutter analyze --no-fatal-infos` sin avisos nuevos.
- `flutter test` completo.
- Correr la app en cada modo.

  ```bash
  flutter run --dart-define=API_BASE_URL=<URL del backend>
  flutter run --dart-define=API_BASE_URL=<URL del backend> --dart-define=MODO_ESTATICO=true
  ```
