---
name: Interruptor remoto del modo estático (front)
description: La app toma el modo estático o dinámico de GET /config al abrirse, al volver a primer plano y ante los códigos del modo estático, con RF-IRM-6 a RF-IRM-13
targets:
  - ../../../lib/services/modo_remoto_service.dart
  - ../../../lib/pages/splash/interruptor_remoto.dart
  - ../../../lib/services/api_client.dart
  - ../../../lib/configs/modo_estatico.dart
  - ../../../lib/pages/splash/carga_del_arranque.dart
  - ../../../lib/main.dart
  - ../../../lib/pages/bienvenida/bienvenida_controller.dart
  - ../../../lib/pages/bienvenida/widgets/compositor.dart
  - ../../../lib/pages/bienvenida/widgets/recibimiento.dart
  - ../../../docs/specs/api-contracts.md
  - ../../../docs/specs/feature-index.md
  - ../../../specs/features/modo-estatico/modo-estatico.spec.md
  - ../../../pubspec.yaml
  - ../../../CHANGELOG.md
  - ../../../docs/devops.md
  - ../../../README.md
---

# Interruptor remoto del modo estático (front)

> El dueño aprueba la spec, con las decisiones D-1 a D-6, el 2026-10-02.

> El dueño aprueba el diseño el 2026-10-02. Un solo cambio en la fila `app_setting` de la base
> gobierna el backend y toda APK 2.1.0 o posterior, sin compilar ni redesplegar. El diseño y la
> evidencia por archivo están en el repo privado del proyecto
> (`docs/specs/2026-10-02-interruptor-remoto-design.md` y `-mapa.md`). Esta spec cubre la app, con
> RF-IRM-6 a RF-IRM-13, y el backend tiene la suya, con RF-IRM-1 a RF-IRM-5. Enmienda RF-EST-7,
> RF-EST-9, RF-EST-10 y la decisión sobre `api_client.dart` de la spec `modo-estatico`. Las
> decisiones D-1 a D-6 no están en el diseño y llevan su propia aprobación, que anota el encabezado.

## Objetivo

La app alterna entre la versión estática y la dinámica según lo que responde `GET /config`, al
abrirse y al volver a primer plano, en los dos sentidos. Sin respuesta usa el último modo que conoce
y, si nunca recibió uno, el de compilación, que en el APK es el estático. Ante un cambio vuelve al
inicio o a la bienvenida, de modo que toda pantalla se reconstruye con el modo nuevo.

## User Stories

- Como dueño del producto, quiero alternar la app entre estática y dinámica con un solo cambio en la
  base, para no compilar ni publicar un APK por cada cambio.
- Como alumno, quiero que la app muestre lo que el backend atiende en ese momento, para no toparme
  con pantallas que solo dan errores.

## Requisitos

### RF-IRM-6. La consulta del modo

`ModoRemotoService.consultar()` pide `GET {API_BASE_URL}/config` con `package:http`, un tope de 5 s
y sin cabeceras propias, y devuelve `true`, `false` o `null`, que es el modo desconocido. Un estado
distinto de 200, un cuerpo que no sea `{"modoEstatico": <bool>}`, el tope o cualquier excepción dan
`null`, y el servicio nunca lanza. Una clave desconocida en el cuerpo no cambia la lectura (decisión
D-5). Su constructor admite inyectar cliente, preferencias, tope y URL base, como
`AvisoVersionService`. No usa `ApiClient`, que no tiene tope, adjunta el token y borra la sesión ante
un 401, y solo toma de él la URL base.

`[@test] ../../../test/interruptor_remoto/modo_remoto_service_test.dart`

### RF-IRM-7. El último modo conocido

La última respuesta conocida se guarda en la clave `modo_estatico_conocido` de SharedPreferences,
con instancia propia como `SplashVarianteService`, así que se lee antes de que exista
`StorageService`. `clearSession` no la borra, un valor que no es booleano cuenta como ninguno y un
fallo de lectura o escritura no lanza.

`[@test] ../../../test/interruptor_remoto/modo_remoto_service_test.dart`

### RF-IRM-8. El modo del arranque

Al abrir la app, `cargarElArranque` lanza en su primera línea la consulta del modo, o se une a la que
esté en curso, y la lectura del modo guardado. Las dos corren en paralelo con Firebase y
`StorageService`, fuera del `try` que produce `FalloAntesDeLosServicios`. Antes de devolver la ruta,
y también cuando la carga falla (decisión D-6), la carga fija `ModoEstatico.activo` con el valor
guardado o, sin él, con el de compilación, y espera la respuesta a lo sumo 1,5 s. Una respuesta a
tiempo se fija y se guarda antes de que exista cualquier pantalla, sin navegar. Un fallo de la
consulta da el modo desconocido y la carga sigue.

`[@test] ../../../test/interruptor_remoto/arranque_remoto_test.dart`
`[@test] ../../../test/modo_estatico/arranque_estatico_test.dart`
`[@test] ../../../test/splash/splash_arranque_test.dart`

### RF-IRM-9. Cuándo se pide el modo

Disparan una consulta nueva la respuesta de la consulta del arranque que llega después de su espera,
cada vuelta a primer plano (`AppLifecycleState.resumed`), con `InterruptorRemoto` como observador
global de `WidgetsBinding`, y toda respuesta de `ApiClient` con código `PORTAL_DESACTIVADO` o
`REGISTRATION_UNAVAILABLE` (decisión D-1). `main()` pone a escuchar el interruptor de la app antes
del arranque. Hay a lo sumo una consulta en curso, y mientras el arranque espera, su consulta cubre
cualquier disparador (decisión D-3).

`[@test] ../../../test/interruptor_remoto/cambio_de_modo_test.dart`
`[@test] ../../../test/interruptor_remoto/disparadores_test.dart`
`[@test] ../../../test/interruptor_remoto/arranque_remoto_test.dart`

### RF-IRM-10. El cambio de modo

Si la respuesta es conocida y difiere de `ModoEstatico.activo`, la app la fija, la guarda y vuelve a
la ruta que daría el arranque (decisión D-4). Con una sesión cuya `postLoginRoute` es `/home`, va a
`/home` en la pestaña Horario (`abrirEnHorario`, RF-SPL-20). Sin sesión, o con la de un alumno sin
especialidad, va a la bienvenida con `offAllToLogin`, como el relevo de la intro (RF-SPL-12) y
`rutaInicialEnWeb`. Si la capa del arranque todavía cubre (`EstadoDeLaCapa.cubre`), espera su retiro.
Una respuesta igual o desconocida no navega. Si `/login` ya es la ruta actual, `offAllToLogin` no
vuelve a navegar y la conversación sigue en su turno, donde «Soy nuevo» aparece o se va al momento.
Con un turno del registro abierto, de N1 a N5 o incierto, el paso a estático la devuelve a E1,
porque la versión estática no tiene registro (RF-EST-8 y decisión D-2). Sin navegador, el modo queda
fijado y la primera pantalla que se construya ya lo lee.

`[@test] ../../../test/interruptor_remoto/cambio_de_modo_test.dart`
`[@test] ../../../test/interruptor_remoto/senal_del_modo_test.dart`
`[@test] ../../../test/interruptor_remoto/bienvenida_al_momento_test.dart`

### RF-IRM-11. El récord y la recarga, siempre registrados

`registrarLosServicios` registra `AcademicRecordService` y `RecargaUlimaService` en los dos modos,
sin peticiones al registrarse, de modo que el paso de estático a normal no deja ningún `Get.find` sin
servicio. En modo estático las pantallas que los usan siguen ocultas y nada les pide datos, así que
el Perfil no pide `GET /academic-record/me` y la calculadora, la ficha del curso y `/mis-notas` no
piden `GET /grades/me/ulima`. Enmienda RF-EST-9 y la excepción RF-REC-5 de RF-EST-10 de la spec
`modo-estatico`, cuyo resto sigue vigente.

`[@test] ../../../test/interruptor_remoto/respaldo_y_servicios_test.dart`
`[@test] ../../../test/modo_estatico/arranque_estatico_test.dart`
`[@test] ../../../test/modo_estatico/borrar_record_estatico_test.dart`
`[@test] ../../../test/modo_estatico/inicio_y_perfil_estaticos_test.dart`
`[@test] ../../../test/modo_estatico/ficha_y_calculadora_estaticas_test.dart`

### RF-IRM-12. `MODO_ESTATICO`, respaldo de fábrica

`modo_estatico.dart` sigue siendo el único lector de `fromEnvironment('MODO_ESTATICO')`, cuyo valor,
`ModoEstatico.deCompilacion`, pasa a ser el respaldo de fábrica y el valor con que arranca
`ModoEstatico.activo`. Enmienda RF-EST-7 de la spec `modo-estatico`. `build-apk.yml` conserva
`--dart-define=MODO_ESTATICO=true` y no cambia.

`[@test] ../../../test/interruptor_remoto/respaldo_y_servicios_test.dart`
`[@test] ../../../test/modo_estatico/modo_estatico_test.dart`
`[@test] ../../../test/modo_estatico/workflow_y_version_test.dart`

### RF-IRM-13. Con el modo fijo, la app de siempre

Con el modo fijo durante la sesión, la app se comporta igual que la 2.0.0 en modo estático y que la
1.2.0 en modo normal, y la suite existente pasa salvo las pruebas que fijan el registro condicional
de servicios o la versión. `pubspec.yaml` pasa a `2.1.0+1` y `CHANGELOG.md` abre con la sección 2.1.0.

`[@test] ../../../test/modo_estatico/modo_estatico_test.dart`
`[@test] ../../../test/modo_estatico/bienvenida_estatica_test.dart`
`[@test] ../../../test/modo_estatico/inicio_y_perfil_estaticos_test.dart`
`[@test] ../../../test/modo_estatico/ficha_y_calculadora_estaticas_test.dart`
`[@test] ../../../test/modo_estatico/riesgo_de_asistencia_estatico_test.dart`
`[@test] ../../../test/modo_estatico/alertas_estaticas_test.dart`
`[@test] ../../../test/modo_estatico/borrar_record_estatico_test.dart`
`[@test] ../../../test/modo_estatico/silabo_estatico_test.dart`
`[@test] ../../../test/modo_estatico/workflow_y_version_test.dart`

## Piezas

| Pieza | Archivo | Responsabilidad |
|---|---|---|
| consulta y modo guardado | `lib/services/modo_remoto_service.dart` | `GET /config` con tope y la clave `modo_estatico_conocido` |
| interruptor | `lib/pages/splash/interruptor_remoto.dart` | arranque, disparadores, una consulta en curso y vuelta al inicio |
| respaldo | `lib/configs/modo_estatico.dart` | `ModoEstatico.deCompilacion`, `ModoEstatico.activo` y la señal `ModoEstatico.cambios`, que avanza `ModoEstatico.fijar` |
| arranque | `lib/pages/splash/carga_del_arranque.dart` | consulta en la primera línea, espera de 1,5 s en el `finally` y servicios siempre registrados |
| códigos | `lib/services/api_client.dart` | `ApiClient.alResponderConCodigo`, sin cambiar el contrato |
| enganche | `lib/main.dart` | `InterruptorRemoto.actual.escuchar()` antes del arranque |
| bienvenida | `lib/pages/bienvenida/bienvenida_controller.dart`, `widgets/compositor.dart` y `widgets/recibimiento.dart` | «Soy nuevo» al momento, con `ModoEstatico.activoObservado` en los Obx y una suscripción a `ModoEstatico.cambios` en el recibimiento, y la vuelta a E1 de un registro abierto al pasar a estático, con un `ever` del controlador sobre la misma señal |

## Decisiones de implementación

Las seis decisiones D-1 a D-6 no están en el diseño aprobado y llevan su propia aprobación del
dueño, que anota el encabezado de la spec.

- **D-1. El aviso de los códigos.** `ApiClient` gana un oyente estático,
  `ApiClient.alResponderConCodigo`, que recibe el código de cada respuesta de error con cuerpo
  `{"error": {...}}` sin cambiar lo que devuelve ni lo que lanza. `main()` instala ahí el
  interruptor, que filtra `PORTAL_DESACTIVADO` y `REGISTRATION_UNAVAILABLE`. Enmienda la decisión de
  la spec `modo-estatico` según la cual `api_client.dart` no cambia. La alternativa es atrapar los dos
  códigos en cada servicio que los recibe, con más archivos tocados.
- **D-2. La bienvenida abierta muestra u oculta «Soy nuevo» al momento.** Sin sesión, o con la de
  un alumno sin especialidad, la ruta del arranque es la bienvenida, y si `/login` ya es la ruta
  actual, `offAllToLogin` no vuelve a navegar, porque una segunda `/login` en la pila deja la página
  con un `LoginController` desechado (`session_navigation.dart`). La conversación sigue en su turno,
  con lo escrito en sus campos, y «Soy nuevo» aparece o se va en ese momento. El interruptor fija
  cada respuesta con `ModoEstatico.fijar`, que avanza la señal observable `ModoEstatico.cambios` solo
  si el modo cambia, y la leen los cuatro sitios que deciden «Soy nuevo». Los Obx de E1 y de E2 la
  leen con `ModoEstatico.activoObservado`, y las respuestas rápidas de «si no cabe» llevan un Obx
  propio que la lee igual, porque `compositorDelTurno` corre dentro de un `LayoutBuilder`, fuera del
  alcance del Obx de la página, y GetX solo reconstruye un Obx por lo que lee durante su builder. El
  recibimiento se suscribe a la señal en su estado, porque con todo quieto su reloj calla y nada más
  lo reconstruye. El toque ya respeta el modo, porque `soyNuevo()` y `responderAlSaludo` leen
  `ModoEstatico.activo` al tocarse. La excepción es un turno del registro, de N1 a N5 o incierto,
  que en estático no sigue, porque lleva a pedir la contraseña de miUlima o el código del
  Authenticator (RF-EST-8). `BienvenidaController` también escucha la señal y, si el modo pasa a
  estático con uno de esos turnos abierto, o si un envío termina en uno con la app ya estática,
  cierra el registro y vuelve a E1 como con «Ya tengo cuenta», sin respuesta del alumno. Las demás
  lecturas del modo no cambian, porque la vuelta al inicio reconstruye sus pantallas, y las pruebas
  siguen fijando `ModoEstatico.activo` directamente.
- **D-3. La consulta del arranque cubre a los disparadores.** Desde la primera línea de la carga
  hasta el fin de su espera, `resumed` y los dos códigos no abren otra consulta, aunque la del
  arranque ya haya respondido, porque esa respuesta se fija sin navegar antes de que exista
  cualquier pantalla. Si el arranque se une a la consulta de un disparador antes de que responda, la
  respuesta la fija el arranque, sin navegar. Fuera de esa ventana rige solo la regla de a lo sumo
  una consulta en curso.
- **D-4. La ruta a la que se vuelve.** «La ruta que daría el arranque» se lee como la lee el
  arranque. Si `postLoginRoute` da `/home`, la app va a `/home` en la pestaña Horario. En cualquier
  otro caso, sin sesión o con un alumno sin especialidad, va a la bienvenida con `offAllToLogin`, y
  nunca directo a `/setup-carrera`.
- **D-5. Las claves que la app no conoce.** Un cuerpo con `modoEstatico` booleano y otras claves se
  lee igual, para que el backend pueda sumar campos sin romper a las APK instaladas.
- **D-6. La carga espera el modo también cuando falla.** La espera del modo va en el `finally` de
  `cargarElArranque`, así que un fallo de Firebase, del almacén o de la restauración de la sesión
  deja fijado el modo guardado o el de compilación y libera los disparadores antes de propagarse. Ese
  fallo llega a la capa a lo sumo 1,5 s más tarde, y con `FalloAntesDeLosServicios` la intro sigue en
  su bucle como hoy (RF-SPL-18).
- La respuesta de la consulta del arranque que llega tarde no se aplica por sí misma. La consulta
  nueva que dispara (RF-IRM-9) aplica su respuesta como un cambio (RF-IRM-10), con el backend ya
  despierto.
- El modo que rige sigue en `ModoEstatico.activo`, que las pruebas fijan y restauran como en la
  2.0.0. `InterruptorRemoto` vive fuera de GetX, como el estado de la capa, y las pruebas lo
  reinician con `InterruptorRemoto.reiniciar()`, que también apaga sus dos disparadores.
- `descrip_cursos_controller.dart` lee `RecargaUlimaService.to.recargaHorario` solo después de una
  recarga exitosa (RF-RCG-8), que en modo estático no ocurre, así que el registro en los dos modos no
  le cambia nada.

## Pruebas

Las pruebas nuevas viven en `test/interruptor_remoto/`, sin red y con datos inventados. La consulta
se prueba con 200 en `true` y en `false`, otros estados, cuerpo no JSON, tipo erróneo, tope y
excepción, y el modo guardado con lectura, escritura, `clearSession` y almacén que falla. El arranque
se prueba con valor guardado, con el respaldo de compilación, con respuesta a tiempo, con respuesta
tardía que dispara una consulta nueva y navega, con una consulta que falla sin dejar la intro en
bucle y con una carga que falla antes y después de los servicios. Los disparadores se prueban con
`resumed` y con los dos códigos, hay casos para una sola consulta en curso y para la ventana del
arranque, y el cambio se prueba con y sin sesión, con un alumno sin especialidad, con la capa
cubriendo y sin navegación cuando el modo no cambia. Con la bienvenida abierta, sin navegar, se
prueban los dos sentidos en el recibimiento y en «si no cabe», el paso a normal en E1 y el paso a
estático en E2, con el mismo turno y con un toque que ya sigue el modo nuevo, y el paso a estático
en N1, en incierto y al fin de un envío, que vuelven a E1. Las pruebas existentes del modo estático
que tocan el récord o la recarga corren con los dos servicios registrados, como los deja el arranque.

## Entrega

La rama `feat/interruptor-remoto` sale de `develop` del fork y vuelve por PR con la CI en verde. El PR
«Versión 2.1.0» hacia `meltiruiz` lo abre la tarea de publicación del plan general, después de la
prueba de punta a punta contra el Preview de `develop`, y solo se fusiona con el visto bueno del
dueño, después de que el backend publique `GET /config` en producción con la fila en `true`.

## Verificación

- `flutter analyze --no-fatal-infos` sin avisos nuevos.
- `flutter test` completo.
- Con la app apuntando al Preview de `develop` del backend, pasar a `false` la fila de `develop`,
  volver a primer plano y ver el inicio con el récord y la recarga, y después dejar la fila en `true`.
- Con la bienvenida abierta en el recibimiento o en E1, alternar la fila, volver a primer plano y ver
  que «Soy nuevo» aparece o se va sin salir de la conversación, y con un registro abierto en N1 pasar
  la fila a `true` y ver la vuelta a E1.
