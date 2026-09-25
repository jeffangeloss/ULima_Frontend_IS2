---
name: Test de especialidad
description: Test de especialidad que conduce Ulises como paso central del asistente del alumno nuevo, con duelos, escalas, desempates, el resultado con su motivo, la elección de la principal y de los intereses, el último resultado en el Perfil, modo oscuro, contraste WCAG, accesibilidad y el caso del id de especialidad antiguo
targets:
  - ../../../lib/pages/specialty_test/**
  - ../../../lib/services/specialty_test_service.dart
  - ../../../lib/models/specialty_test_models.dart
  - ../../../lib/pages/setup_carrera/setup_carrera_page.dart
  - ../../../lib/pages/setup_carrera/setup_carrera_controller.dart
  - ../../../lib/pages/setup_carrera/setup_carrera_binding.dart
  - ../../../lib/pages/perfil/perfil.dart
  - ../../../lib/services/auth_service.dart
  - ../../../lib/configs/themes.dart
  - ../../../lib/main.dart
  - ../../../pubspec.yaml
  - ../../../assets/specialty_test/tasks/**
  - ../../../test/HU36_jeff/**
---

# Test de especialidad

> Estado: **PROPUESTA del 2026-09-25, pendiente de la aprobación explícita del dueño.** Recoge
> las decisiones 1 a 7 del dueño de ese día (ver «Decisiones del dueño»). Lo que esas decisiones
> no fijan va en «Decisiones abiertas» con la opción que la spec adopta por defecto, y nada de
> esa lista se da por aprobado. Los puntos en que el contrato del backend no alcanza para lo que
> pide la maqueta van ahí mismo como hallazgos, sin campos inventados.
> La contraparte de backend es
> `ULima_Backend_IS2/specs/features/specialty-test/specialty-test.spec.md` (RS-BE-37 a RS-BE-47,
> rama `feat/test-especialidad`, commit `5d8b82b`), también propuesta y sin aprobar. Esta spec
> consume sus tres rutas nuevas y `PUT /academic-profile/me/specialties` con la enmienda
> BR-AP-07 y BR-AP-08 de esa rama.
> Enmienda la spec de frontend `specs/features/academic-profile/academic-profile.spec.md` en el
> asistente y en el Perfil (ver «Cambios en otras specs»). Hasta la aprobación rige el texto sin
> enmendar.
> Todos los `[@test]` apuntan a pruebas que se crean con la implementación y hoy no existen, así
> que cada uno lleva la marca *(pendiente)*, como en la spec del backend (decisión abierta 21).
> Los ejemplos usan datos inventados.

## El problema

El asistente del alumno nuevo (`/setup-carrera`) tiene tres pasos, que son la carrera, una
decisión con tres opciones y una lista de especialidades con «Principal» y «Me interesa». Nada
ayuda a decidir, y la lista sale del catálogo de `GET /academic-profile/specialties`, que hoy
trae también las especialidades antiguas (la app las filtra en el cliente con
`is_active == true`, `setup_carrera_controller.dart:26-28`). Las capturas del asistente actual
(`capturas/01` a `capturas/08`, en claro y en oscuro) muestran además tres huecos.

- **Sin modo oscuro.** Cada par de capturas `_claro` y `_oscuro` es idéntico byte a byte, porque
  `setup_carrera_page.dart` pinta con 40 `Color(0x…)` fijos, empezando por el fondo `#F7F7F8`
  (`:21`).
- **Sin estados de catálogo.** Sin catálogo, el paso de carrera muestra la tarjeta sin nombre
  (captura 07) y la selección queda en blanco (captura 08), sin aviso ni forma de reintentar.
- **Botón cortado.** «Finalizar configuración» no cabe en su botón (capturas 04 y 06), que además
  lleva texto blanco sobre `#FF6600`, con 2,94:1.

El test resuelve lo primero. Ulises, el cuervo del chatbot, conversa con el alumno y le muestra
tareas reales de cada especialidad en 14 preguntas, a veces una o dos más para desempatar. El
backend calcula el resultado con la fórmula del contenido, Cohere redacta el motivo y la app
muestra el resultado, deja elegir la principal y marcar intereses, y guarda en el Perfil el
acceso para rehacerlo.

## User Stories

- Como alumno nuevo, quiero que un test corto me recomiende una especialidad y me diga por qué,
  para elegir con algo más que el nombre del diploma.
- Como alumno nuevo, quiero saltar el test y elegir por mi cuenta si ya sé lo que quiero.
- Como alumno, quiero elegir la recomendada como principal y marcar otras como interés desde el
  mismo resultado.
- Como alumno, quiero rehacer el test desde mi Perfil y ver ahí mi último resultado.
- Como alumno que usa lector de pantalla, texto grande o menos movimiento, quiero hacer el test
  igual que los demás.

## Decisiones del dueño (2026-09-25, vinculantes)

Salen de `decisiones.md`, el registro del dueño.

| # | Decisión | Requisitos |
| --- | --- | --- |
| 1 | El test es el paso central de `/setup-carrera`, con la opción «Saltar y elegir por mi cuenta», y se puede rehacer desde el Perfil. | RF-TEST-1, RF-TEST-3, RF-TEST-10 |
| 2 | El puntaje es transparente y lo calcula el backend. Cohere solo redacta el motivo y, si falla o tarda, el resultado sale con el motivo de las plantillas. | RF-TEST-7, RF-TEST-8 |
| 3 | El contenido está aprobado y va versionado. | RF-TEST-2, RF-TEST-4 |
| 4 | Diseño «Conversación con Ulises», con la misma imagen del chatbot (`assets/images/ulises_chatbot.png`), según la maqueta `ulises-v2.html` de cinco pantallas. Las tarjetas del duelo son grises y se encienden en el color de su especialidad al tocarlas. El resultado va sin scroll, en claro y en oscuro, con la número uno, su porcentaje, el motivo, sus electivos, las otras tres con un corazón y los botones «Elegir como principal», «Decidir después» y «Rehacer el test». Modo oscuro obligatorio. | RF-TEST-3 a RF-TEST-9, RF-TEST-12 |
| 5 | Se guarda solo el último resultado por alumno, con el ranking, la fecha y la versión, para mostrarlo en el Perfil. Las respuestas una por una no se guardan. | RF-TEST-2, RF-TEST-10 |
| 6 | Solo se muestran y se eligen los cuatro diplomas oficiales, con el filtro en el backend. `getEspecialidadName()` devolvería una cadena vacía para un id antiguo en caché, y esta spec lo cubre. | RF-TEST-14 |
| 7 | La validación del contenido está hecha. | RF-TEST-2 |

## Requisitos

### RF-TEST-1 · El asistente con el test como paso central

El asistente pasa de tres pasos a este recorrido.

1. **Carrera.** Igual que hoy, con la carrera fija y «Continuar». Si el catálogo de carreras no
   cargó, la tarjeta muestra «No pudimos cargar tu carrera.» y «Reintentar», que llama a
   `AuthService.reloadCatalogs()` (RF-TEST-14). «Continuar» sigue activo, porque la carrera sale
   del usuario (`careerId`) y el catálogo solo pone su nombre.
2. **Test.** «Continuar» abre la ruta nueva `/test-especialidad` con el argumento
   `origen: asistente`, sobre el asistente, que queda debajo en la pila. La ruta muestra la
   bienvenida (RF-TEST-3), las preguntas (RF-TEST-4 a RF-TEST-7) y el resultado (RF-TEST-8 y
   RF-TEST-9).
   - «Saltar y elegir por mi cuenta» cierra la ruta y el asistente pasa a la selección manual.
   - Un `404 SPECIALTY_TEST_NOT_AVAILABLE` al pedir el contenido hace lo mismo, sin aviso, porque
     el test no existe para esa carrera (RS-BE-38).
   - «Elegir como principal» y «Decidir después» guardan con `PUT` y terminan el asistente con
     `Get.offAllNamed('/home')` (RF-TEST-9).
   - El atrás del sistema en la bienvenida, o el botón de pausa (RF-TEST-4), cierra la ruta y
     deja al alumno en el paso de carrera. Con «Continuar» vuelve a la bienvenida.
3. **Selección manual.** Es el paso «Selección» de hoy (`_SeleccionStep`,
   `setup_carrera_page.dart:365-435`), con las mismas reglas de principal e interés y los
   botones «Saltar por ahora» y «Finalizar configuración». Muestra solo las especialidades
   oficiales (RF-TEST-14). Si el catálogo de especialidades llega vacío por un fallo, muestra
   «No pudimos cargar las especialidades.» y «Reintentar» en lugar de la lista en blanco. El
   atrás del sistema vuelve al paso de carrera.

Sale el paso «Decisión» (`_DecisionStep` y `_DecisionCard`, `setup_carrera_page.dart:219-363`)
con sus tres opciones, y con él `SpecialtyDecision`, `decision`, `chooseSi`, `chooseNoSe` y
`chooseExplorar` (`setup_carrera_controller.dart:7`, `:11` y `:47-59`). «Todavía no estoy
seguro» queda cubierto por «Decidir después» y por «Saltar por ahora», y «Quiero explorar
primero» por el propio test. `SetupStep` queda con `carrera` y `seleccion`.

- **Destino tras el login.** `postLoginRoute` (`post_login_route.dart:11-14`) no cambia. Un
  alumno con `setupComplete == false` sigue entrando a `/setup-carrera`, y un docente nunca ve
  el asistente ni el test.
- **Bindings.** `/setup-carrera` pasa a tener binding por ruta (`SetupCarreraBinding`), en lugar
  del `Get.put` dentro de `build` (`setup_carrera_page.dart:17`), como pide la regla del repo que
  recuerda `main.dart`. `/test-especialidad` tiene el suyo (`SpecialtyTestBinding`), con
  `lazyPut` sin `fenix`, para que el controlador muera al cerrar la ruta.
- **Precarga.** Al abrir el paso de carrera, el controlador pide el contenido del test en segundo
  plano (RF-TEST-2), para que la bienvenida no espere. Un fallo de esa precarga no se muestra en
  el paso de carrera; la bienvenida lo vuelve a pedir.
- **Modo oscuro.** Los pasos de carrera y de selección manual dejan sus 40 `Color(0x…)` fijos y
  pasan a los tokens de `MaterialTheme` (RF-TEST-12), como hizo el chat (RF-CHAT-8). Los textos de
  esos pasos no cambian.
- **Botón inferior.** `_BottomButton` (`setup_carrera_page.dart:766`) pasa al estilo del botón
  principal del test, a lo ancho, con 52 px de alto y texto en tinta sobre naranja (RF-TEST-12),
  así que «Finalizar configuración» cabe entero.
- **Cabecera.** `_WizardHeader` (`setup_carrera_page.dart:47`) sigue en los pasos de carrera y
  de selección manual y no aparece dentro de la ruta del test. Toma `headerColor`
  (`themes.dart:21-26`), con su texto en tinta `#1A0E05` sobre el naranja en claro (6,45:1) y en
  blanco sobre `#1E1E24` en oscuro (16,58:1) (decisión abierta 14). Su saludo «Hola, <nombre>»
  no cambia.
- **Orientación.** Vertical, como toda ruta fuera de Horario (BR-SHELL-F-00 de app-shell).

`[@test] ../../../test/HU36_jeff/setup_carrera_flujo_test.dart` *(pendiente)*

### RF-TEST-2 · Capa de datos del test

- **Service.** `SpecialtyTestService`, un `GetxService` permanente que `main.dart` registra junto
  a `TimeBlocksService` (`main.dart:81`), es el único que llama a `/specialty-test/**`. Ningún
  widget ni controlador lee JSON ni llama a `ApiClient`.
- **Operaciones.** `fetchContent()` pide `GET /specialty-test/content`, `evaluate()` manda
  `POST /specialty-test/me/evaluate`, `loadLastResult()` pide `GET /specialty-test/me/result` y
  `clear()` vacía todo.
- **Plazos.** `ApiClient` no impone plazo (`api_client.dart:140`), así que el service pone el
  suyo, como `TimeBlocksService` y `AcademicRecordService`. Son 15 s para el contenido y para el
  último resultado, y 20 s para la evaluación, que incluye hasta 5 s de Cohere y el arranque en
  frío del servidor (decisión abierta 17).
- **Guarda por dueño.** El estado queda atado al código del alumno, igual que en
  `TimeBlocksService`. Una respuesta que llega para otro alumno, o después de un `clear()`, se
  descarta. `AuthService.logout()` llama a `clear()` con la misma guarda `Get.isRegistered` que
  usa con el récord y los bloques (`auth_service.dart:398-402`).
- **Contenido.** Cada inicio del test, en la bienvenida, pide el contenido otra vez, para no
  arrancar con una versión vieja. La copia queda en memoria durante la sesión, porque la tarjeta
  del Perfil usa sus colores y sus íconos (RF-TEST-10). Nunca se guarda en disco.
- **Respuestas.** Viven solo en la memoria del service mientras el test está en curso o en
  pausa (RF-TEST-4). No se guardan en disco ni viajan a otro lado que no sea el cuerpo de la
  evaluación (decisión 5). Se borran al terminar, al «Empezar de nuevo», al saltar el test y al
  cerrar sesión.
- **Cuerpo de la evaluación.** Es exactamente `{ "version", "answers", "tiebreakAnswers" }`, con
  la versión del contenido con que se respondió, las respuestas por id de pregunta y los
  desempates en orden (RS-BE-39). Nunca lleva datos del alumno.
- **Modelos.** `specialty_test_models.dart` tiene el contenido (versión, especialidades con
  electivos, líneas de Ulises, opciones y preguntas), el paso de la evaluación (desempate o
  resultado) y el último resultado. Sus `fromJson` conservan los `null`, como
  `tiebreakOutcome`, y no inventan ceros ni textos.
- **Contenido utilizable.** Antes de usar el contenido, el modelo comprueba lo que la app
  necesita para no pintar un test roto. Cada pregunta es `duel`, con `top` y `bottom`, o
  `scale`, con `task`; cada tarea trae id, texto y una clave que está entre las especialidades;
  y cada especialidad trae `specialtyId`, nombre y sus dos colores. Si algo falla, la bienvenida
  muestra el mismo estado que sin conexión (RF-TEST-11) y el registro dice solo que el contenido
  no es válido, sin datos. La app no fija el número de preguntas ni la versión, así que la
  `2026-09-25.2` o la `2026-09-25.3` le dan lo mismo.
- **Errores.** El service traduce cada fallo a un tipo propio con estos casos.
  - `notAvailable`, por `404 SPECIALTY_TEST_NOT_AVAILABLE`.
  - `versionOutdated`, por `409 SPECIALTY_TEST_VERSION_OUTDATED`, con `details.currentVersion`.
  - `invalidAnswers`, por `400 SPECIALTY_TEST_INVALID_ANSWERS`.
  - `tiebreakMismatch`, por `400 SPECIALTY_TEST_TIEBREAK_MISMATCH`, con `details.expected`.
  - `rateLimited`, por `429 RATE_LIMITED`, con el mensaje del servidor y
    `details.retryAfterMinutes`.
  - `offline`, por un plazo vencido o un fallo de red sin respuesta (`TimeoutException` y
    `http.ClientException`, que en Android e iOS envuelve a `SocketException`).
  - `server`, por cualquier otro `ApiException`, con su mensaje.
- **Último resultado.** `loadLastResult()` deja uno de cinco estados, que son cargando, sin
  test, con resultado, error y no disponible. Tras una evaluación que termina en resultado, el
  service marca el último resultado como viejo, y la tarjeta del Perfil lo vuelve a pedir al
  montarse, porque solo `GET /specialty-test/me/result` trae `isCurrentVersion` (RS-BE-45).

`[@test] ../../../test/HU36_jeff/specialty_test_service_test.dart` *(pendiente)*
`[@test] ../../../test/HU36_jeff/specialty_test_models_test.dart` *(pendiente)*

### RF-TEST-3 · La bienvenida

Es la pantalla 1 de la maqueta.

- **Héroe.** Ocupa 284 px de alto con la escala de texto en 1,0, con esquinas inferiores de
  36 px y un degradado radial de naranjas (`#FFA35E`, `#FF7A1A`, `#FF6600` y `#E25A00`). Lleva
  arriba a la izquierda la pastilla «Test de especialidad» con el ícono de brújula
  (`LucideIcons.compass`), en tinta `#1A0E05` sobre blanco al 85 %. Al centro va Ulises, a
  136 px, recortado en círculo como en el chatbot (`chatbot_page.dart:716-734`) y con un aro
  blanco de 5 px. Alrededor flotan cuatro orbes blancos de 42 px con el ícono de cada
  especialidad en su color claro, sin nombres. El héroe es igual en los dos temas (decisión
  abierta 13).
- **Ulises.** Debajo del héroe, el rótulo «Ulises» y una burbuja por cada línea de
  `ulises.welcome`, en orden. La primera va sin avatar y las demás con el avatar de 28 px, como
  en la maqueta. La app no agrega el nombre del alumno, porque las líneas del contenido no lo
  traen y el nombre llega como «APELLIDOS NOMBRES» (`user_model.dart:54-66`). El «Hola,
  Valeria» de la maqueta es ilustrativo (decisión abierta 8).
- **Pastillas.** «3 a 4 min», con el ícono de reloj, y «Rehazlo en Perfil», con
  `LucideIcons.rotateCcw`. La segunda sale solo con `origen: asistente`.
- **Botones.** «Empezar el test», principal, con flecha, y «Saltar y elegir por mi cuenta»,
  secundario. Con `origen: perfil`, el secundario es «Ahora no» y cierra la ruta. El
  `startButton` del contenido («Vamos») no se usa, porque la decisión 4 nombra el botón «Empezar
  el test» (decisión abierta 7).
- **Test en pausa.** Si hay respuestas en memoria para la misma versión (RF-TEST-4), el botón
  principal dice «Seguir el test» y vuelve a la pregunta en que quedó, y aparece un segundo
  botón secundario, «Empezar de nuevo», que borra las respuestas y abre la pregunta 1.
- **Cargando.** Mientras llega el contenido, el héroe se ve completo, las burbujas son dos
  bloques de `SkeletonPulse` y el botón principal está desactivado. El secundario sigue activo.
- **Error.** Las burbujas dejan su lugar a «No pudimos cargar el test.» y a «Reintentar». El
  secundario sigue activo, así que un fallo nunca atrapa al alumno en el asistente.
- **No disponible.** Con `origen: asistente`, la ruta se cierra y el asistente pasa a la
  selección manual (RF-TEST-1). Con `origen: perfil`, un aviso muestra el mensaje del servidor
  («El test de especialidad no está disponible para tu carrera.») y la ruta se cierra.
- **Espacio.** Si las líneas de bienvenida no caben, el cuerpo desplaza y los botones quedan
  fijos abajo.

`[@test] ../../../test/HU36_jeff/specialty_test_bienvenida_test.dart` *(pendiente)*

### RF-TEST-4 · La conversación con Ulises

Rige para el duelo, la escala, el desempate y la espera.

- **Barra.** Mide 52 px. A la izquierda, «Pregunta anterior» (`LucideIcons.chevronLeft`). Al
  centro, Ulises a 38 px con un punto verde decorativo, el nombre «Ulises» y debajo «Pregunta N
  de T», donde T es el número de preguntas del contenido (14 hoy), o «Desempate 1» y «Desempate
  2». A la derecha, «Pausar el test y seguir luego» (`LucideIcons.pause`).
- **Plumas.** Una por pregunta, bajo la barra. Van llenas en `testFeatherOn` las respondidas,
  la actual llena y con un brillo suave, y el resto en `testFeatherOff`. En los desempates y en
  la espera van todas llenas. Siempre van en naranja y nunca en el color de una especialidad,
  para que no lleven la cuenta a la vista.
- **Burbuja de Ulises.** En pantalla queda solo el último turno de Ulises, con su avatar de
  28 px. La app elige sus líneas con estas reglas y no escribe ninguna propia.
  - Antes de la pregunta 1 va `duelHelp`.
  - Antes de la pregunta N, con N mayor que 1, va la reacción a la respuesta N − 1. Si N − 1 es
    un duelo, es su `reaction`; si el duelo no la trae, es una línea de `reactions.pick`,
    `reactions.both` o `reactions.none` según la respuesta, la de índice (N − 1) módulo el largo
    de la lista. Si N − 1 es una escala, es su `blockClose`; si no lo trae, es una línea de
    `reactions.scale` con la misma regla de índice.
  - Antes de la primera escala del contenido va además una segunda burbuja con `scaleHelp`.
  - Antes de un desempate va la `ulisesLine` que manda el servidor (RF-TEST-7).
  - Ninguna línea nombra especialidades, porque así está escrito el contenido y el servidor.
- **Sello de bloque.** Junto a un `blockClose` cae el sello «Cierra el bloque k de B», donde k
  es el orden de esa pregunta entre las que traen `blockClose` y B es cuántas lo traen (4 hoy).
  El contrato no manda el campo `block` del contenido, y esta cuenta da el mismo número.
- **Historial plegado.** Desde la pregunta 2, arriba del turno de Ulises, una pastilla dice «N
  respuestas anteriores», o «1 respuesta anterior». Al tocarla se despliega, dentro del mismo
  espacio que desplaza, la lista de lo respondido, con el número de la pregunta y la respuesta.
  La respuesta es el texto de la tarea elegida, «Me gustan las dos», «Ninguna me llama» o, en
  una escala, «<etiqueta> · <tarea>». Los desempates van como «Desempate 1» y «Desempate 2».
  La lista va sin colores de especialidad y solo se lee. Otro toque la pliega.
- **Atrás.** «Pregunta anterior» y el atrás del sistema llevan al paso previo. Desde la
  pregunta 1 van a la bienvenida, desde el desempate 1 a la última pregunta, desde el desempate
  2 al desempate 1 y desde la espera al paso que la lanzó, y la respuesta que llegue después se
  descarta. La respuesta previa aparece marcada. Cambiar la respuesta de cualquier pregunta
  borra todos los desempates, y cambiar el desempate 1 borra el 2, porque el servidor decide
  cuáles tocan. Responder de nuevo, aunque sea lo mismo, vuelve a evaluar.
- **Pausa.** Cierra la ruta y deja las respuestas en la memoria del service (RF-TEST-2). En el
  asistente, el alumno queda en el paso de carrera; en el Perfil, vuelve a su tarjeta, que
  ofrece seguir (RF-TEST-10). Cerrar la app o la sesión pierde el avance (decisión abierta 9).
  Al volver, si la versión del contenido cambió, la app descarta el avance y muestra «El test se
  actualizó. Vuelve a empezarlo.», el mismo texto del `409` del servidor.
- **Transiciones.** La reacción y la pregunta siguiente entran juntas en 180 ms, sin puntos de
  «escribiendo», y el par anterior se encoge dentro de la pastilla del historial.

`[@test] ../../../test/HU36_jeff/specialty_test_conversacion_test.dart` *(pendiente)*
`[@test] ../../../test/HU36_jeff/specialty_test_logic_test.dart` *(pendiente)*

### RF-TEST-5 · El duelo

Es la pantalla 2 de la maqueta.

- **Encabezado.** El rótulo «Esto o aquello», en mayúsculas de 11 px y en `testAccentText`, y
  debajo el `prompt` de la pregunta, en 17,5 px y negrita.
- **Tarjetas.** Dos, apiladas, con la tarea `top` arriba y la `bottom` abajo. Cada una mide al
  menos 104 px de alto y lleva a la izquierda la ilustración de 80 px y a la derecha el texto de
  la tarea en 14 px y negrita. Entre las dos va una moneda con «o», decorativa.
- **Neutras hasta el toque.** Antes del toque, las dos tarjetas son iguales, con el fondo
  `cardBg`, el borde `testLine` y la ilustración en `testIllustrationInk`. Ni la tarjeta, ni la
  ilustración, ni Ulises dejan ver de qué especialidad es cada tarea (decisión 4). La guía de
  ilustración del contenido, que pide el estilo neutro hasta el resultado, queda superada por la
  decisión 4, igual que en RS-BE-38.
- **Al tocar.** En 150 ms la tarjeta se enciende con el color de su especialidad, `color.light` o
  `color.dark` según el tema. El borde pasa a 1,5 px en ese color, el fondo a ese color al 12 %
  sobre `cardBg`, aparece un halo de 4 px al 20 % y la ilustración toma el color. Arriba a la
  derecha cae una insignia de 28 px en el color, con el visto en el color de la página, y suena
  `HapticFeedback.selectionClick`. La otra tarjeta se apaga, con la ilustración al 50 % y el
  texto en `testInk2` y peso 600.
- **Las dos o ninguna.** Debajo van dos botones de 48 px en dos columnas, con las etiquetas de
  `duelOptions` para `both` y `none`. «Me gustan las dos» enciende las dos tarjetas y «Ninguna
  me llama» apaga las dos.
- **Avance.** A los 350 ms del toque, la pregunta avanza sola y la pluma se llena. En esos 350 ms
  otro toque no hace nada. Con un lector de pantalla activo (`MediaQuery.accessibleNavigation`)
  no hay avance solo, y tras elegir aparece el botón «Siguiente» (RF-TEST-13, decisión abierta
  18).
- **Ilustraciones.** Cada tarea tiene su ilustración, un SVG por id de tarea en
  `assets/specialty_test/tasks/<id>.svg` (por ejemplo `q01.top.svg` o `tb-si-vj-1.bottom.svg`),
  dibujado con `currentColor` en las piezas que se tiñen. La app lo pinta con `SvgPicture` de
  `flutter_svg` y un `SvgTheme` cuyo `currentColor` es `testIllustrationInk` antes del toque y el
  color de la especialidad después. Si una tarea no tiene SVG, por ejemplo en una versión nueva
  del contenido, las dos tarjetas muestran la misma baldosa neutra con `LucideIcons.sparkles`,
  que no delata nada. La descripción `illustration` del contenido no se muestra; sirve para
  dibujar (decisión abierta 2).
- **Desempate.** Usa esta misma pantalla, con el rótulo «Desempate» y las dos tareas que manda
  el servidor.

`[@test] ../../../test/HU36_jeff/specialty_test_preguntas_test.dart` *(pendiente)*

### RF-TEST-6 · La escala de gusto

Es la pantalla 3 de la maqueta.

- **Tarjeta.** Arriba una franja de 92 px con la ilustración de la tarea centrada (la misma regla
  de RF-TEST-5), y debajo el rótulo «Escala de gusto», el texto de la tarea en 15 px y negrita,
  y el `prompt` de la pregunta en 12,5 px y `testMuted`. La escala nunca se enciende con el color
  de su especialidad, porque no es un duelo y ese color la delataría.
- **Opciones.** Las cuatro de `scaleOptions`, en una fila de cuatro, de 64 px de alto como
  mínimo, con su etiqueta y encima un emoji decorativo, 😴, 🙂, 😃 y 🤩, en ese orden. Con la
  escala de texto por encima de 1,3 o con menos de 340 px de ancho, van en una grilla de dos por
  dos.
- **Al elegir.** La opción crece un 8 % y pasa a naranja, con el fondo `testAccentSoft`, el
  borde `testAccent` y la etiqueta en `testAccentDeep`, y suena
  `HapticFeedback.selectionClick`. El avance sigue la regla de RF-TEST-5.
- **Fin de bloque.** Si la escala trae `blockClose`, al avanzar cae el sello de bloque con
  `HapticFeedback.lightImpact`, junto a la burbuja de Ulises (RF-TEST-4).

`[@test] ../../../test/HU36_jeff/specialty_test_preguntas_test.dart` *(pendiente)*

### RF-TEST-7 · Evaluación, espera y desempates

- **Cuándo evalúa.** Al responder la última pregunta, la app llama a `evaluate()` con todas las
  respuestas y `tiebreakAnswers` vacío. Tras responder un desempate, vuelve a llamar con las
  mismas respuestas y los desempates en orden. El servidor no guarda nada entre una llamada y
  otra (RS-BE-39), así que un reintento manda el mismo cuerpo.
- **La espera.** Se queda en la conversación, con la barra y las plumas llenas. Si la última
  pregunta trae `blockClose`, va primero esa burbuja con su sello. Después va una burbuja con
  `ulises.loading` («Dame un toque que junto tus respuestas.»), que es el texto de espera, y un
  indicador de progreso pequeño en `testAccent`. Con menos movimiento, el indicador no gira y la
  burbuja sola dice que se espera (RF-TEST-13). La espera cubre también la redacción del motivo
  por Cohere, de hasta 5 s en el servidor.
- **Desempate.** Si llega `status: "tiebreak"`, la app muestra el desempate como un duelo
  (RF-TEST-5), con la `ulisesLine` del servidor en la burbuja y «Desempate 1» o «Desempate 2»,
  según `order`, en la barra.
- **Resultado.** Si llega `status: "result"`, la app abre el resultado (RF-TEST-8), borra las
  respuestas de la memoria y marca el último resultado como viejo (RF-TEST-2).
- **Una sola a la vez.** Mientras la evaluación está en vuelo, las tarjetas, las opciones y los
  botones no responden, y nunca salen dos evaluaciones juntas.
- **La app no calcula.** La app no calcula afinidades, no decide si toca un desempate ni ordena
  el ranking. Muestra lo que llega (decisión 2).

`[@test] ../../../test/HU36_jeff/specialty_test_evaluacion_test.dart` *(pendiente)*

### RF-TEST-8 · El resultado

Son las pantallas 4 y 5 de la maqueta. De arriba abajo, van estas piezas.

1. **Entrada.** Confeti decorativo, una sola vez, y `HapticFeedback.heavyImpact`.
2. **Ulises.** Su avatar de 34 px y una burbuja con `ulises.intro` y, si no es `null`,
   `ulises.tiebreakOutcome`, separados por un espacio. `headline` no se pinta, porque la tarjeta
   dice lo mismo, y es la etiqueta accesible de la tarjeta (RF-TEST-13). `closing` y `retake` no
   se pintan (decisión abierta 6).
3. **Tarjeta de la número uno.**
   - En claro, el fondo es un degradado del `color.light` de la ganadora a ese mismo color un
     20 % más oscuro, con el texto en blanco salvo el de la pastilla. En oscuro, el fondo es el
     `color.dark` al 18 % sobre `cardBg`, con un borde de 1 px en ese color al 35 %, el texto en
     `textPrimary` y el título en `color.dark`.
   - Arriba, «Tu n.º 1» con el ícono de la especialidad en una baldosa de 22 px, y a la derecha la
     pastilla «75 % afinidad», en tinta `#1A0E05` sobre un degradado de `#FFD166` a `#FFB020`.
   - El título es el `name` de la ganadora en 20,5 px y negrita, en hasta dos líneas y sin
     puntos suspensivos, porque «Tecnologías de la Información» no cabe en una.
   - Un medidor de 6 px con la afinidad, decorativo, porque el número ya está en la pastilla.
   - El motivo, `reason`, en 12,5 px. Si `reasonSource` es `"ai"`, lo encabeza la insignia «IA»;
     con `"templates"` va sin insignia. Con la escala de texto en 1,0, el motivo se corta en
     cuatro líneas y «Leer más» lo despliega dentro de la tarjeta, con «Leer menos» para
     volver, porque los motivos del contenido miden de 190 a 549 caracteres y el de la maqueta
     104 (decisión abierta 5).
   - Al entrar, la tarjeta gira una vez en 600 ms y la afinidad cuenta desde 0 hasta su valor en
     600 ms.
4. **Electivos.** Una fila con el ícono de libro en una baldosa del color de la ganadora, el
   título «N electivos», donde N es el número de electivos de la ganadora en el contenido, y
   debajo los dos primeros `shortName` unidos por « · », cortados con puntos suspensivos. «Ver»
   abre una hoja con el título «Electivos de <nombre>», el `tagline` y una fila por electivo con
   el `shortName` en negrita, «<código> · N créditos» y el `prerequisite` tal cual, en
   `testMuted`.
5. **Las demás.** El rótulo «También te puede interesar» y, a la derecha, un corazón pequeño con
   «guárdala», como en la maqueta. Debajo, una fila por cada especialidad desde el puesto 2, con
   el ícono en una baldosa de su color y el número del puesto encima, el nombre en 12,5 px y
   negrita, la afinidad «65 %» en su color y negrita, una barra de 4 px decorativa y el corazón
   de 48 px (RF-TEST-9). Si esa especialidad es la principal actual del alumno, en lugar del
   corazón va una estrella con «Tu principal», sin acción.
6. **Botones.** «Elegir como principal», principal y a lo ancho, y debajo, en dos columnas,
   «Decidir después» y «Rehacer el test», con `LucideIcons.rotateCcw`.

- **Empate.** Con `tie: true`, el rótulo de la tarjeta es «Empate» y lleva los dos nombres, uno
  por línea, con una sola pastilla de afinidad, porque es la misma. El color de la tarjeta es el
  de la primera del ranking. La fila de electivos dice «Electivos de las dos» y su hoja trae una
  sección por especialidad. Las filas de abajo empiezan en el puesto 3.
- **Sin scroll.** A 375 × 667, el iPhone SE, con la escala de texto en 1,0 y el motivo cortado,
  todo cabe sin desplazar, en claro y en oscuro. Con más escala de texto o con el motivo
  desplegado, desplaza la parte del medio y los botones quedan fijos abajo.
- **Lo que no entra de la maqueta.** La línea de cada fila que explica el puesto («Perdió en el
  desempate», «Le diste "Un poco"», «Ganó 1 de 5 duelos») no entra, porque el contrato no la
  manda y calcularla en la app repetiría reglas del backend (decisión abierta 3). El nombre corto
  de «Elegir Software como principal» y de «7 electivos de Software» tampoco, porque el contrato
  no trae nombres cortos de especialidad, y el botón dice «Elegir como principal», como la
  decisión 4 (decisión abierta 4).
- **Atrás del sistema.** En el asistente no hace nada, porque los tres botones deciden. En el
  Perfil hace lo mismo que «Decidir después» (decisión abierta 12).

`[@test] ../../../test/HU36_jeff/specialty_test_resultado_test.dart` *(pendiente)*

### RF-TEST-9 · Elegir como principal, corazones y Decidir después

`PUT /academic-profile/me/specialties` reemplaza la selección entera (BR-AP-04), así que la app
siempre manda la principal y los intereses completos, con `AuthService.completeSetup`
(`auth_service.dart:330-376`), que ya pone al día el usuario y las preferencias. Los ids que
manda son solo los cuatro `specialtyId` del ranking, que el servidor resolvió entre las
especialidades activas, y la principal nunca viaja también como interés (RF-TEST-14).

- **Elegir como principal.** Manda como principal el `specialtyId` de la ganadora y como
  intereses los corazones marcados, sin la ganadora. Con empate, el botón abre una hoja «¿Cuál
  eliges como principal?» con las dos ganadoras y «Cancelar» (decisión abierta 11). Si la
  ganadora ya es la principal, el botón se desactiva y dice «Ya es tu principal». Al guardar,
  en el asistente termina con `Get.offAllNamed('/home')`, y en el Perfil cierra la ruta y
  muestra el aviso de siempre, «Especialidades actualizadas» y «Tu selección se guardó
  correctamente.» (`perfil.dart:939-942`).
- **Corazón.** Marca o desmarca como interés la especialidad de su fila y guarda enseguida, con
  la principal actual sin cambios. El corazón cambia al tocarlo y, si el guardado falla, vuelve
  a su estado y un aviso lo dice (RF-TEST-11). Nunca hay dos guardados en vuelo; los toques
  seguidos se juntan y se manda el último estado. Al abrir el resultado, los corazones marcados
  son los de las especialidades que ya son interés del alumno. En el asistente, el primer
  guardado marca además la configuración como completa (BR-AP-04), así que si el alumno cierra
  la app después de un corazón, la próxima vez entra a `/home` (decisión abierta 10).
- **Decidir después.** En el asistente, manda la selección actual, con la principal como está y
  los corazones marcados, para marcar la configuración como completa, y termina con
  `Get.offAllNamed('/home')`. En el Perfil cierra la ruta sin guardar nada, porque los
  corazones ya se guardaron. El último resultado ya quedó guardado en el servidor aunque el
  alumno no elija nada (RS-BE-44).
- **Rehacer el test.** Vuelve a la pregunta 1 con el mismo contenido y sin respuestas, sin pasar
  por la bienvenida. Los corazones ya guardados se quedan. El resultado guardado cambia solo
  cuando el test nuevo termina (RS-BE-44).

`[@test] ../../../test/HU36_jeff/specialty_test_eleccion_test.dart` *(pendiente)*

### RF-TEST-10 · El último resultado en el Perfil y «Rehacer el test»

El Perfil suma la tarjeta `SpecialtyTestProfileCard` en «Configuración académica», debajo de
«Especialización» (`perfil.dart:310-337`). Como las demás tarjetas académicas, solo la ve un
alumno (`perfil.dart:44-51`). La maqueta no tiene esta tarjeta, así que su diseño lo fija esta
spec con las piezas del resultado (decisión abierta 16).

- **Cargando.** Un `SkeletonPulse`, como la tarjeta del récord.
- **Sin test.** Ulises a 28 px, el título «Test de especialidad», «Todavía no hiciste el test.» y
  el botón «Hacer el test».
- **Con resultado.** El título «Test de especialidad» y «Hecho el dd/mm/aaaa», con la fecha de
  `completedAt` en hora de Lima (UTC−5, sin horario de verano, con una función propia como la
  del chat). Debajo, la número uno, o las dos del empate, con el ícono en su baldosa, el nombre y
  la afinidad, y las demás en filas compactas con su afinidad y su barra. Si
  `isCurrentVersion` es `false`, una línea dice «El test cambió desde que lo hiciste.». Al final,
  el botón «Rehacer el test». No hay motivo, porque no se guarda (RS-BE-44).
- **En pausa.** Si hay un test a medias en memoria, la tarjeta dice «Tienes un test a medias, N
  de T.» y su botón es «Seguir el test», con o sin un resultado anterior debajo.
- **Error.** «No se pudo cargar tu último test.» y «Reintentar».
- **No disponible.** Con `404 SPECIALTY_TEST_NOT_AVAILABLE`, la tarjeta no aparece.
- **Colores.** Salen de la copia del contenido de la sesión (RF-TEST-2). Si todavía no hay
  copia, la tarjeta la pide junto con el último resultado. Si el contenido no carga, los nombres y
  las afinidades salen del resultado igual, y los íconos y las barras van en los colores neutros
  (`iconoNaranja` y `testMuted`).
- **Botones.** «Hacer el test», «Rehacer el test» y «Seguir el test» abren `/test-especialidad`
  con `origen: perfil`, que empieza en la bienvenida (RF-TEST-3). Al volver de un test
  terminado, la tarjeta pide el último resultado otra vez.

`[@test] ../../../test/HU36_jeff/specialty_test_perfil_test.dart` *(pendiente)*

### RF-TEST-11 · Errores y sin conexión

Entre pregunta y pregunta el test no usa la red, así que una caída de conexión solo se nota al
cargar, al evaluar y al guardar. Los textos de error van en `textPrimary` sobre `cardBg`, con el
ícono en `iconoNaranja`, y «Reintentar» va como botón secundario en `testAccentText`. Los avisos
pasajeros van en `cardBg` con borde `borderColor` y texto en `textPrimary`, como en el chat
(RF-CHAT-8).

| Momento | Caso | Qué ve el alumno |
| --- | --- | --- |
| Bienvenida | Sin conexión, plazo vencido o contenido no válido | «No pudimos cargar el test.» y «Reintentar». El botón secundario sigue activo |
| Bienvenida | `404 SPECIALTY_TEST_NOT_AVAILABLE` | En el asistente, la selección manual sin aviso. En el Perfil, el mensaje del servidor y el cierre de la ruta |
| Preguntas | Sin conexión | Nada. El test sigue |
| Espera | Sin conexión o plazo vencido | En lugar de la burbuja de espera, «No pudimos conectarnos. Revisa tu conexión e inténtalo de nuevo.» y «Reintentar», con las respuestas intactas y «Pregunta anterior» disponible |
| Espera | `409 SPECIALTY_TEST_VERSION_OUTDATED` o `400 SPECIALTY_TEST_INVALID_ANSWERS` | Un diálogo con el mensaje del servidor y «Empezar de nuevo», que pide el contenido otra vez y abre la pregunta 1 |
| Espera | `400 SPECIALTY_TEST_TIEBREAK_MISMATCH` | La app descarta sus desempates y repite una sola vez con `tiebreakAnswers` vacío, y sigue con lo que responda el servidor. Si vuelve a fallar, el estado de error de la espera |
| Espera | `429 RATE_LIMITED` | El mensaje del servidor tal cual, que dice los minutos, y «Reintentar». Las respuestas se conservan |
| Espera | `413`, `500` u otro error con mensaje | El mensaje del servidor y «Reintentar» |
| Espera | Cohere falla o tarda | Nada. Llega `reasonSource: "templates"` y el motivo va sin la insignia «IA» |
| Resultado | El `PUT` falla | Un aviso con el mensaje del servidor o, sin mensaje, «No se pudo guardar. Revisa tu conexión e inténtalo de nuevo.». El corazón vuelve a su estado y el resultado sigue en pantalla |
| Perfil | El último resultado falla | «No se pudo cargar tu último test.» y «Reintentar» |
| Cualquiera | `401` | `ApiClient` cierra la sesión y lleva al login, como en toda la app (`api_client.dart:143-161`) |
| Cualquiera | `403` | No ocurre, porque la app nunca abre el test para un docente |

`[@test] ../../../test/HU36_jeff/specialty_test_errores_test.dart` *(pendiente)*

### RF-TEST-12 · Modo oscuro y contraste

- **Tema.** El test, el asistente entero y la tarjeta del Perfil siguen
  `Theme.of(context).brightness`, que sale del tema del sistema (`main.dart:116`). Los widgets
  nuevos no llevan hex sueltos. Sus colores son tokens de `MaterialTheme` o los colores de las
  especialidades que manda el contenido.
- **Tokens nuevos.** Salen de la paleta de la maqueta, que ya llega al contraste pedido, y viven
  en `themes.dart` como los del chat. Se reusan `pageBg`, `cardBg`, `textPrimary`, `headerColor`,
  `borderColor`, `iconoNaranja` y `errorBg`.

| Token | Claro | Oscuro | Uso |
| --- | --- | --- | --- |
| `testInk2` | `#334155` | `#CFCFDB` | Texto de la tarjeta apagada y de las opciones |
| `testMuted` | `#556070` | `#A5A5B5` | Texto secundario del test y de la tarjeta del Perfil |
| `testLine` | `#E2E8F0` | `#30303A` | Bordes de tarjetas y botones |
| `testChipBg` | `#EEF2F7` | `#24242C` | Pastilla del historial |
| `testAccent` | `#FF6600` | `#FF8C42` | Fondo del botón principal y de la opción elegida |
| `testAccentHi` | `#FF7F24` | `#FF9D5C` | Tope del degradado del botón principal |
| `testAccentInk` | `#1A0E05` | `#16161C` | Texto sobre `testAccent` |
| `testAccentText` | `#B84A00` | `#FF9A57` | Rótulos, botones secundarios y «Reintentar» |
| `testAccentDeep` | `#7A3300` | `#FFC49A` | Texto sobre `testAccentSoft` |
| `testAccentSoft` | `#FFF1E6` | `#3A2A22` | Pastillas, sello y opción elegida |
| `testHeartOff` | `#64748B` | `#9A9AAC` | Corazón sin marcar |
| `testTrack` | `#E8EDF3` | `#2C2C36` | Pista de las barras |
| `testFeatherOn` | `#D45500` | `#FF8C42` | Plumas llenas |
| `testFeatherOff` | `#CBD5E1` | `#3A3A46` | Plumas vacías |
| `testIllustrationBg` | `#F1F5F9` | `#25252D` | Fondo de la ilustración |
| `testIllustrationInk` | `#64748B` | `#8A8A9C` | Ilustración neutra |

  La pluma llena de la maqueta es `#FF6600`, que sobre `#F8FAFC` da 2,81:1 y no llega al 3:1 de
  un ícono, así que en claro va en `#D45500`, con 3,94:1 (decisión abierta 15).

- **Colores de las especialidades.** Son los del contenido, `color.light` y `color.dark`, que
  manda el servidor, y no los de la maqueta (`#5B4BDB`, `#0B7A71`, `#2563EB` y `#C0267E`), que
  eran ilustrativos (decisión abierta 1). Con la versión `2026-09-25.2` dan estos contrastes.

| Clave | Claro | Sobre `#FFFFFF` y `#F8FAFC` | Blanco sobre el color | Tinta sobre la tarjeta encendida | Oscuro | Sobre `#1E1E24` y `#16161C` | Tinta y color sobre la tarjeta del resultado |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `sw` | `#1E3A8A` | 10,36:1 y 9,90:1 | 10,36:1 | 14,45:1 | `#A5C0F7` | 9,07:1 y 9,85:1 | 9,57:1 y 6,10:1 |
| `ti` | `#0F7A45` | 5,40:1 y 5,16:1 | 5,40:1 | 15,10:1 | `#7EE8BE` | 11,19:1 y 12,16:1 | 9,12:1 y 7,18:1 |
| `si` | `#9333EA` | 5,38:1 y 5,14:1 | 5,38:1 | 14,97:1 | `#B98AF8` | 6,36:1 y 6,91:1 | 10,48:1 y 4,69:1 |
| `vj` | `#76164A` | 10,58:1 y 10,12:1 | 10,58:1 | 14,31:1 | `#EC7FB3` | 6,52:1 y 7,08:1 | 10,50:1 y 4,81:1 |

  La tarjeta encendida es el color al 12 % sobre `cardBg`, con el texto en `textPrimary`. La
  tarjeta del resultado en oscuro es el color al 18 % sobre `#1E1E24`, con el texto en
  `textPrimary` y el título en el color. En claro, el extremo más oscuro del degradado solo sube
  el contraste del blanco (de 5,38:1 a 7,49:1 en el peor caso, `si`).

- **Guarda en tiempo de ejecución.** El contenido puede cambiar de versión sin otro APK, así que
  la app no confía a ciegas en sus colores. Una función pura calcula el contraste WCAG, y si un
  color servido no llega a 4,5:1 contra el fondo donde va como texto, o a 3:1 donde va como
  ícono, ese texto o ícono va en `textPrimary` y el color queda solo en las piezas decorativas.
  Un hex que no se puede leer cuenta como neutro.
- **Contraste del resto.** Todo texto del test, del asistente y de la tarjeta del Perfil llega a
  4,5:1 contra su fondo en los dos temas, y todo ícono que da información, a 3:1.

| Par | Claro | Oscuro |
| --- | --- | --- |
| Texto principal sobre la página | `#0F172A` sobre `#F8FAFC`, 17,06:1 | `#EDEDF3` sobre `#16161C`, 15,45:1 |
| Texto principal sobre la tarjeta | `#0F172A` sobre `#FFFFFF`, 17,85:1 | `#EDEDF3` sobre `#1E1E24`, 14,22:1 |
| `testInk2` sobre la tarjeta | 10,35:1 | 10,74:1 |
| `testMuted` sobre la página y la tarjeta | 6,09:1 y 6,38:1 | 7,42:1 y 6,83:1 |
| `testAccentText` sobre la página | 5,00:1 | 8,59:1 |
| `testAccentInk` sobre `testAccent` y `testAccentHi` | 6,45:1 y 7,50:1 | 7,79:1 y 8,78:1 |
| `testAccentDeep` sobre `testAccentSoft` | 8,25:1 | 8,87:1 |
| Ícono en `testAccentText` sobre `testAccentSoft` | 4,72:1 | 6,53:1 |
| `testMuted` sobre `testChipBg` | 5,67:1 | 6,34:1 |
| `testFeatherOn` sobre la página | 3,94:1 | 7,79:1 |
| `testHeartOff` sobre la página | 4,55:1 | 6,51:1 |
| Tinta `#1A0E05` sobre el naranja del héroe `#FF6600` | 6,45:1 | 6,45:1 |
| Tinta `#1A0E05` sobre la pastilla `#FFB020` | 10,36:1 | 10,36:1 |

- **Piezas decorativas.** El medidor y las barras de afinidad, el halo, el confeti, el punto
  verde, la moneda «o», los orbes del héroe, las plumas y las ilustraciones no llevan un
  contraste mínimo, porque lo que dicen está también en texto. El medidor dorado sobre la pista
  de la tarjeta, por ejemplo, baja a 1,87:1 con `ti`, y la afinidad se lee en la pastilla.

`[@test] ../../../test/HU36_jeff/specialty_test_contraste_test.dart` *(pendiente)*

### RF-TEST-13 · Accesibilidad

- **Lectores de pantalla.** Con TalkBack y VoiceOver rigen estas etiquetas.
  - Cada tarjeta del duelo es un botón con el texto de su tarea como etiqueta, `duelHelp` como
    pista y el estado `selected` después de elegir. «Me gustan las dos» y «Ninguna me llama»
    son botones con su texto.
  - La escala es un grupo con el `prompt` como etiqueta, y cada opción es un botón con
    `inMutuallyExclusiveGroup`, su etiqueta y el estado `checked`.
  - La burbuja de Ulises es una región viva (`liveRegion`), así que al avanzar se lee la
    reacción, y el `prompt` de la pregunta nueva es un encabezado (`header`).
  - «Pregunta anterior» y «Pausar el test y seguir luego» son las etiquetas de sus botones, y
    el subtítulo de la barra se lee. La pastilla del historial dice «Ver tus N respuestas
    anteriores» u «Ocultar tus respuestas anteriores», con su estado desplegado.
  - La tarjeta del resultado es un solo nodo con `headline` y el motivo. La insignia «IA» se lee
    «Motivo redactado con IA». «Leer más» es un botón.
  - Cada fila del ranking se lee «Puesto N, <nombre>, <afinidad> % de afinidad». El corazón es
    un botón con `toggled`, cuya etiqueta es «Marcar <nombre> como interés» o «Quitar <nombre>
    de tus intereses», como en la maqueta.
  - Quedan fuera del árbol de accesibilidad las imágenes de Ulises, los orbes, el punto verde,
    las plumas, la moneda, los emojis, las ilustraciones, el medidor, las barras y el confeti.
  - Sin avance solo y con el botón «Siguiente», como dice RF-TEST-5, porque un cambio de
    pregunta sin aviso desorienta a quien navega por voz (WCAG 3.2.2).
- **Tamaño de texto.** Todo respeta `MediaQuery.textScaler` hasta el 200 %. Ningún contenedor de
  texto tiene alto fijo, solo alto mínimo. Desde 1,3, la escala va en dos por dos, «Me gustan
  las dos» y «Ninguna me llama» van una debajo de otra y el héroe baja a 200 px. A 375 × 667, con
  1,0, 1,3 y 2,0, ninguna pantalla desborda.
- **Menos movimiento.** Con `MediaQuery.disableAnimationsOf(context)`, no hay vaivén de Ulises ni
  de los orbes, brillo de la pluma, salto de la insignia, giro de la tarjeta, confeti, cuenta de
  la afinidad (sale el valor final) ni crecimiento de la opción, y el indicador de la espera no
  gira. Todas las transiciones pasan a fundidos de 150 ms. La pausa de 350 ms antes de avanzar
  se queda, porque no es movimiento.
- **Blancos táctiles.** Los botones de ícono (atrás, pausa, corazón y «Ver») miden al menos
  48 × 48, y los demás botones, al menos 48 de alto.
- **El color nunca va solo.** La tarjeta elegida lleva además la insignia con el visto, el borde
  más grueso y el estado `selected`. La opción de la escala lleva el borde, el tamaño y
  `checked`, y el corazón marcado va relleno, con `toggled`.
- **Vibración.** Sigue a la maqueta y nunca reemplaza una señal visual ni de texto.

`[@test] ../../../test/HU36_jeff/specialty_test_accesibilidad_test.dart` *(pendiente)*

### RF-TEST-14 · Solo lo oficial en la app y el id antiguo (decisión 6)

Con BR-AP-07, el catálogo de `GET /academic-profile/specialties` trae solo las cuatro
oficiales. Un id antiguo puede seguir en la app por dos caminos. El primero es el usuario en
memoria, porque `/auth/me` y el login siguen leyendo lo guardado sin filtro (decisión abierta 13
del backend). El segundo son las preferencias locales que escribe `saveSetup`
(`storage_service.dart:128-156`), aunque ningún código lee esas claves para pintar
(`savedSetupFor` no tiene quien lo llame). Hoy, `getEspecialidadName`
(`auth_service.dart:92-95`) devuelve `''` para un id que no está en el catálogo, y el Perfil
pinta un chip vacío (`_PrincipalChip` y `_InteresChip`, `perfil.dart:490-610`). Según la
comprobación en solo lectura del 2026-09-25, ninguna selección activa apunta a una antigua, así
que el caso es de defensa.

- **`getEspecialidadName` no cambia.** Sigue devolviendo `''` para un id desconocido, porque la
  malla depende de eso. `electiveMatchesUserSpecialties` (`malla_service.dart:180-194`) descarta
  los nombres vacíos, así que los electivos de una especialidad antigua dejan de aparecer, que es
  lo que pide la decisión 6. `_PrincipalChip._pendingCount` ya devuelve 0 con un nombre vacío.
- **Consultas nuevas.** `AuthService` suma `isOfficialSpecialty(int id)`, que dice si el id está
  en el catálogo cargado, y `catalogsFailed`, que distingue un catálogo que no cargó de uno que
  cargó vacío, como el de una carrera sin especialidades. Suma también `reloadCatalogs()`, el
  mismo `_loadCatalogs` expuesto para «Reintentar».
- **Selección oficial.** Una función pura recibe la principal, los intereses y los ids oficiales
  y devuelve la principal solo si es oficial y los intereses oficiales sin la principal.
- **Perfil.** Con el catálogo cargado, la tarjeta «Especialización» pinta solo los ids
  oficiales. Si no queda ninguno, dice «Sin especialización seleccionada» en `textSecondary`, en
  lugar del `placeholderText` de hoy (`perfil.dart:440`), que da 2,32:1. Nunca pinta un chip
  vacío. Con el catálogo fallido, dice «No se pudieron cargar tus especialidades.» con
  «Reintentar», y «Editar» no abre la hoja hasta que el catálogo cargue.
- **Nunca se manda un id antiguo.** La hoja de «Editar» (`perfil.dart:875-889`) y la selección
  manual del asistente (`setup_carrera_controller.dart:37-45`) arrancan con la selección
  oficial, así que su `PUT` no lleva un id antiguo, que con BR-AP-07 daría
  `404 SPECIALTY_NOT_FOUND`. Al guardar, el id antiguo sale de la base, que es lo que pide la
  decisión 6. El resultado del test usa como ids oficiales los cuatro `specialtyId` del ranking
  (RF-TEST-9), así que no depende del catálogo.
- **El test no usa `getEspecialidadName`.** El resultado y la tarjeta del Perfil toman el
  `name` y el `specialtyId` que manda el servidor.
- **El filtro del cliente se queda.** La app sigue filtrando `is_active == true`
  (`setup_carrera_controller.dart:26-28` y `perfil.dart:895-897`) como defensa, aunque con
  BR-AP-07 ya no excluye nada.

`[@test] ../../../test/HU36_jeff/perfil_especialidad_antigua_test.dart` *(pendiente)*
`[@test] ../../../test/HU36_jeff/specialty_test_logic_test.dart` *(pendiente)*

## Textos nuevos

Los textos de Ulises, las preguntas, las tareas, las opciones, los nombres, los electivos, el
motivo y los mensajes de error del servidor vienen del backend y la app los muestra tal cual.
Los textos propios de la app son estos.

- **Bienvenida.** «Test de especialidad», «Ulises», «3 a 4 min», «Rehazlo en Perfil», «Empezar el
  test», «Saltar y elegir por mi cuenta», «Ahora no», «Seguir el test», «Empezar de nuevo» y «No
  pudimos cargar el test.».
- **Conversación.** «Pregunta N de T», «Desempate 1», «Desempate 2», «Pregunta anterior»,
  «Pausar el test y seguir luego», «N respuestas anteriores», «1 respuesta anterior», «Ver tus N
  respuestas anteriores», «Ocultar tus respuestas anteriores», «Cierra el bloque k de B», «Esto o
  aquello», «Escala de gusto», «Desempate», «o», «Siguiente» y «El test se actualizó. Vuelve a
  empezarlo.».
- **Espera.** «No pudimos conectarnos. Revisa tu conexión e inténtalo de nuevo.» y «Reintentar».
- **Resultado.** «Tu n.º 1», «Empate», «N % afinidad», «IA», «Motivo redactado con IA», «Leer
  más», «Leer menos», «N electivos», «Electivos de las dos», «Ver», «Electivos de <nombre>»,
  «<código> · N créditos», «También te puede interesar», «guárdala», «Puesto N, <nombre>, N % de
  afinidad», «Marcar <nombre> como interés», «Quitar <nombre> de tus intereses», «Tu principal»,
  «Elegir como principal», «Ya es tu principal», «¿Cuál eliges como principal?», «Cancelar»,
  «Decidir después», «Rehacer el test» y «No se pudo guardar. Revisa tu conexión e inténtalo de
  nuevo.».
- **Perfil.** «Test de especialidad», «Hecho el dd/mm/aaaa», «El test cambió desde que lo
  hiciste.», «Todavía no hiciste el test.», «Hacer el test», «Tienes un test a medias, N de T.»,
  «Seguir el test», «No se pudo cargar tu último test.», «No se pudieron cargar tus
  especialidades.» y «Reintentar».
- **Asistente.** «No pudimos cargar tu carrera.» y «No pudimos cargar las especialidades.».

Salen los textos del paso «Decisión», que son «Especialización», «Opcional. Puedes elegirla
ahora, explorarla o decidirlo luego desde tu perfil.», «Sí, quiero elegir ahora», «Todavía no
estoy seguro», «Quiero explorar primero» y sus subtítulos.

## Pantallas y archivos

### Pantallas

| Pantalla | Estado | Requisito |
| --- | --- | --- |
| Bienvenida del test, con Ulises y «Empezar el test» | Nueva | RF-TEST-3 |
| Pregunta de duelo, de escala y de desempate, con la barra, las plumas y el historial | Nueva | RF-TEST-4 a RF-TEST-6 |
| Espera de la evaluación | Nueva | RF-TEST-7 |
| Resultado, con la hoja de electivos y la hoja del empate | Nueva | RF-TEST-8 y RF-TEST-9 |
| Tarjeta del test en el Perfil | Nueva | RF-TEST-10 |
| Asistente, paso de carrera | Cambia (modo oscuro, estado de catálogo, botón, precarga) | RF-TEST-1 |
| Asistente, paso «Decisión» | Sale | RF-TEST-1 |
| Asistente, selección manual | Cambia (modo oscuro, estado de catálogo, solo oficiales, botón) | RF-TEST-1 y RF-TEST-14 |
| Perfil, tarjeta «Especialización» y su hoja de «Editar» | Cambia (id antiguo y catálogo fallido) | RF-TEST-14 |
| Login, home, malla y chatbot | No cambian | «Qué NO entra» |

### Se crean

| Archivo | Qué tiene |
| --- | --- |
| `lib/pages/specialty_test/specialty_test_page.dart` | La ruta `/test-especialidad`, que cambia entre bienvenida, pregunta, espera y resultado |
| `lib/pages/specialty_test/specialty_test_controller.dart` | El recorrido del test, el atrás, la pausa, los reintentos y los guardados |
| `lib/pages/specialty_test/specialty_test_binding.dart` | El binding por ruta |
| `lib/pages/specialty_test/specialty_test_logic.dart` | Funciones puras de las líneas de Ulises, el sello, el historial, el descarte de desempates, el cuerpo de la evaluación, la selección oficial, los corazones, el contraste, los colores, los íconos y la fecha en Lima |
| `lib/pages/specialty_test/widgets/welcome_view.dart` | La bienvenida (RF-TEST-3) |
| `lib/pages/specialty_test/widgets/question_view.dart` | La barra, las plumas, el historial, el duelo, la escala y el desempate (RF-TEST-4 a RF-TEST-6) |
| `lib/pages/specialty_test/widgets/waiting_view.dart` | La espera y su error (RF-TEST-7 y RF-TEST-11) |
| `lib/pages/specialty_test/widgets/result_view.dart` | El resultado (RF-TEST-8 y RF-TEST-9) |
| `lib/pages/specialty_test/widgets/electives_sheet.dart` | La hoja de electivos |
| `lib/pages/specialty_test/widgets/ulises_bubble.dart` | La burbuja y el avatar de Ulises |
| `lib/pages/specialty_test/widgets/task_illustration.dart` | La ilustración con su color y la baldosa neutra |
| `lib/pages/specialty_test/specialty_test_profile_card.dart` | La tarjeta del Perfil (RF-TEST-10) |
| `lib/pages/setup_carrera/setup_carrera_binding.dart` | El binding por ruta del asistente |
| `lib/services/specialty_test_service.dart` | La capa de datos (RF-TEST-2) |
| `lib/models/specialty_test_models.dart` | Los modelos del contrato |
| `assets/specialty_test/tasks/*.svg` | Las ilustraciones por id de tarea, si el dueño las aprueba (decisión abierta 2) |
| `test/HU36_jeff/*.dart` | Las pruebas de «Pruebas por requisito» |

### Cambian

| Archivo | Qué cambia |
| --- | --- |
| `lib/main.dart` | Registra `SpecialtyTestService` y agrega `/test-especialidad` con su binding y el binding de `/setup-carrera` |
| `lib/pages/setup_carrera/setup_carrera_controller.dart` | Sin el paso «Decisión», con la precarga, la vuelta de la ruta del test y la selección oficial |
| `lib/pages/setup_carrera/setup_carrera_page.dart` | Sin el paso «Decisión», sin `Get.put` en `build`, con tokens en lugar de hex, los estados de catálogo y el botón nuevo |
| `lib/pages/perfil/perfil.dart` | La tarjeta del test en «Configuración académica» y el caso del id antiguo en «Especialización» y en su hoja |
| `lib/services/auth_service.dart` | `isOfficialSpecialty`, `catalogsFailed`, `reloadCatalogs` y `clear()` del test en `logout()` |
| `lib/configs/themes.dart` | Los tokens de RF-TEST-12 |
| `pubspec.yaml` | La carpeta `assets/specialty_test/tasks/`, si el dueño aprueba las ilustraciones |

### No cambian

| Archivo | Por qué |
| --- | --- |
| `lib/services/post_login_route.dart` | El alumno sin configuración sigue entrando a `/setup-carrera` |
| `lib/services/storage_service.dart` | El test no guarda nada en disco y las claves viejas de especialidades no se leen para pintar |
| `lib/services/api_client.dart` | Los plazos van en el service, como en los demás |
| `lib/services/malla_service.dart` | Ya descarta los nombres vacíos (RF-TEST-14) |
| `lib/models/user_model.dart` | La principal y los intereses siguen igual |
| `lib/pages/chatbot/**` | El chatbot no lee el resultado (RS-BE-47) |

## Contrato que se consume

El detalle está en `docs/specs/api-contracts.md` («Specialty Test» y la enmienda de «Academic
Profile») y en la spec del backend. Todas las rutas usan el token del alumno, y ninguna lleva
datos del alumno en el cuerpo.

- `GET /specialty-test/content` devuelve la versión vigente, las cuatro especialidades con su
  `specialtyId`, sus colores, su ícono y sus electivos, las líneas de Ulises del recorrido, las
  opciones y las preguntas, cada tarea con su id, su texto, su descripción de ilustración y la
  clave de su especialidad.
- `POST /specialty-test/me/evaluate` recibe todas las respuestas y devuelve el siguiente
  desempate con la línea de Ulises, o el resultado con el ranking, el empate, el motivo, su
  origen y las líneas de Ulises. El resultado queda guardado como el último del alumno.
- `GET /specialty-test/me/result` devuelve el último resultado, sin motivo y con
  `isCurrentVersion`, o `{ "result": null }`.
- `PUT /academic-profile/me/specialties` sin cambios de forma, con `404 SPECIALTY_NOT_FOUND` para
  una especialidad inactiva y el reemplazo en una sola transacción (BR-AP-07 y BR-AP-08).
- `GET /academic-profile/specialties` trae solo las activas (BR-AP-07). La app lee de cada
  elemento `id`, `carrera_id`, `name`, `description`, `is_active` y `display_order`.

## Pruebas por requisito

Todas se crean con la implementación, en `test/HU36_jeff/`, y hoy no existen. Las pruebas de
widget usan un `ApiClient` falso y datos inventados, con el alumno de prueba 20230001.

| Requisito | Pruebas | Qué fijan |
| --- | --- | --- |
| RF-TEST-1 | `setup_carrera_flujo_test.dart` | Carrera, test y selección manual; sin el paso «Decisión»; «Saltar» y el `404` llevan a la selección manual; el atrás en cada paso; el binding; los estados de catálogo vacío y fallido; el botón nuevo sin corte a 375 de ancho; ningún hex fijo en el asistente en oscuro |
| RF-TEST-2 | `specialty_test_service_test.dart`, `specialty_test_models_test.dart` | Las tres rutas y sus cuerpos; los plazos de 15 y 20 s; la guarda por dueño; `clear()` en `logout()`; el contenido pedido en cada inicio; la traducción de cada error; los `null` conservados; el contenido no válido rechazado |
| RF-TEST-3 | `specialty_test_bienvenida_test.dart` | Las líneas de bienvenida en orden y sin nombre; las pastillas y los botones según el origen; «Seguir el test» y «Empezar de nuevo» con un test en pausa; cargando, error y no disponible |
| RF-TEST-4 | `specialty_test_conversacion_test.dart`, `specialty_test_logic_test.dart` | La regla de cada burbuja, con reacción propia, rotación de `pick`, `both`, `none` y `scale`, `duelHelp` y `scaleHelp`; el sello con k y B contados; el historial; el atrás con el descarte de desempates; la pausa y la versión cambiada |
| RF-TEST-5 y RF-TEST-6 | `specialty_test_preguntas_test.dart` | Tarjetas neutras antes del toque; el encendido con el color del tema; las dos y ninguna; el avance a los 350 ms y los toques ignorados; la ilustración teñida y la baldosa neutra sin SVG; la escala en cuatro y en dos por dos |
| RF-TEST-7 | `specialty_test_evaluacion_test.dart` | La evaluación tras la última pregunta; el texto de espera; uno y dos desempates; el resultado; ninguna evaluación doble; el mismo cuerpo en el reintento |
| RF-TEST-8 | `specialty_test_resultado_test.dart` | Las piezas en orden; `intro` y `tiebreakOutcome`; la insignia «IA» solo con `"ai"`; el motivo cortado y «Leer más»; el empate; sin desplazar a 375 × 667 con 1,0 en claro y en oscuro; la hoja de electivos; «Tu principal» |
| RF-TEST-9 | `specialty_test_eleccion_test.dart` | El cuerpo del `PUT` al elegir, con empate y con la ganadora ya principal; el corazón que guarda, revierte y junta toques; «Decidir después» en el asistente y en el Perfil; «Rehacer el test» |
| RF-TEST-10 | `specialty_test_perfil_test.dart` | Los seis estados de la tarjeta; la fecha en hora de Lima con `TZ=UTC`; «El test cambió desde que lo hiciste.»; los colores neutros sin contenido; la recarga al volver |
| RF-TEST-11 | `specialty_test_errores_test.dart` | Cada fila de la tabla de errores |
| RF-TEST-12 | `specialty_test_contraste_test.dart` | Cada token en los dos temas; los colores del contenido de la tabla; la guarda con un color que no llega y con un hex roto |
| RF-TEST-13 | `specialty_test_accesibilidad_test.dart` | Las etiquetas, estados y regiones vivas; lo excluido del árbol; «Siguiente» con lector de pantalla; sin desborde con 1,0, 1,3 y 2,0; sin animaciones con menos movimiento; los blancos de 48 |
| RF-TEST-14 | `perfil_especialidad_antigua_test.dart`, `specialty_test_logic_test.dart` | El chip vacío que ya no aparece; «Sin especialización seleccionada» con solo ids antiguos; el catálogo fallido con «Reintentar»; la hoja y el asistente que no mandan un id antiguo; `getEspecialidadName` igual; la malla sin cambios |

## Cambios en otras specs

- `specs/features/academic-profile/academic-profile.spec.md`. La enmienda del asistente, que
  queda en carrera, test y selección manual, y del Perfil, con la tarjeta del test y el caso del
  id antiguo. Hasta la aprobación rige el texto sin enmendar.
- `docs/specs/api-contracts.md`. La sección «Specialty Test» con las tres rutas y, en «Academic
  Profile», el filtro del listado, el `404` por especialidad inactiva y los campos que la app
  lee del listado.
- `docs/specs/feature-index.md`. La fila 21 de esta funcionalidad y la enmienda en la fila de
  Academic Profile. La fila 20 la toma el truco del 67 en su rama (`feat/six-seven-fe`, sin
  mergear).

## Qué NO entra

- **Calcular algo del resultado en la app.** Ni afinidades, ni desempates, ni el orden, ni la
  explicación de cada puesto (decisión 2 y decisión abierta 3).
- **Guardar respuestas en disco o en el servidor.** Solo viven en memoria (decisión 5).
- **Borrar el último resultado desde la app.** Rehacer el test lo reemplaza.
- **Elegir la principal desde la tarjeta del Perfil.** Se elige en el resultado o con «Editar»
  (decisión abierta 16).
- **El test para un docente o para otra carrera.** El docente no lo ve y otra carrera recibe el
  `404` del servidor.
- **Cambiar la malla, el login o `/auth/me`.** Siguen como están (RF-TEST-14).
- **El saludo del asistente.** «Hola, <nombre>» toma hoy el `firstName` que sale de partir
  «APELLIDOS NOMBRES» (`user_model.dart:54-66`) y queda para otro cambio.
- **El chatbot.** No lee el resultado (RS-BE-47) y no cambia.
- **El truco del 67.** Tiene su propia spec.
- **Dependencias nuevas.** `flutter_svg` y `lucide_icons_flutter` ya están en `pubspec.yaml`.

## Decisiones abiertas

Cada punto trae la opción que la spec adopta por defecto. Ninguno está aprobado. Los que dicen
«hallazgo» son huecos del contrato del backend frente a la maqueta.

1. **Colores.** La app usa los colores del contenido que manda el servidor (por ejemplo
   `#1E3A8A` y `#A5C0F7` para Software), que llegan al contraste pedido, y no los de la maqueta
   (`#5B4BDB` y `#A69DFF`). Resuelve así la decisión abierta 16 del backend. Si el dueño prefiere
   los de la maqueta, se cambian en el contenido con una versión nueva, sin tocar la app.
2. **Ilustraciones (hallazgo).** La maqueta pide una ilustración por tarea y el contrato manda
   solo su descripción. La spec propone 48 SVG por id de tarea dentro del APK (24 de las
   preguntas y 24 de los desempates), con una baldosa neutra si falta alguno. Queda por decidir
   quién los dibuja y si la primera entrega sale solo con la baldosa. Como el contrato no trae una
   clave o una URL de imagen, una versión del contenido con tareas nuevas muestra la baldosa
   hasta el siguiente APK. La alternativa es que el backend sirva las imágenes.
3. **Explicación de cada puesto (hallazgo).** La maqueta pone bajo cada especialidad «Perdió en
   el desempate», «Le diste "Un poco"» o «Ganó 1 de 5 duelos». El ranking del contrato trae solo
   clave, id, nombre y afinidad. Por defecto la fila muestra solo la afinidad. Para tenerla, el
   backend tendría que mandarla por especialidad, porque calcularla en la app repite reglas del
   servidor y en el Perfil no hay respuestas para calcularla.
4. **Nombre corto (hallazgo).** La maqueta dice «Elegir Software como principal» y «7 electivos
   de Software». El contrato no trae nombres cortos de especialidad, así que el botón dice
   «Elegir como principal», como la decisión 4, y la fila dice «7 electivos».
5. **Motivo largo (hallazgo).** Los motivos de las plantillas miden de 190 a 549 caracteres en
   los ocho ejemplos del contenido, y el de Cohere hasta 500, frente a los 104 de la maqueta. Para
   cumplir «sin scroll», el motivo se corta en cuatro líneas con «Leer más».
6. **Líneas de Ulises en el resultado (hallazgo).** El contrato manda `intro`, `headline`,
   `tiebreakOutcome`, `closing` y `retake`, y la maqueta tiene lugar para una burbuja. La
   burbuja lleva `intro` y `tiebreakOutcome`, `headline` es la etiqueta accesible de la tarjeta,
   y `closing` y `retake` no se muestran. La alternativa es una segunda burbuja con `closing`,
   que obliga a desplazar en el iPhone SE.
7. **«Empezar el test» o «Vamos».** La decisión 4 nombra el botón «Empezar el test» y el
   contenido aprobado trae `startButton: "Vamos"`. La spec usa «Empezar el test».
8. **Textos de la maqueta.** Las líneas de Ulises de la maqueta («¡Craa! Hola, Valeria 👋» o
   «¡Anotado! Va otra 👇»), su enunciado «Primera práctica y te dejan escoger» y sus tareas son
   ilustrativos. Mandan los del contenido, sin el nombre del alumno.
9. **Pausa solo en memoria.** Cerrar la app o la sesión pierde el avance. Guardarlo en disco
   choca con la regla de `AGENTS.md` sobre `shared_preferences` y con la decisión 5, que no
   guarda respuestas.
10. **Corazón que guarda enseguida.** En el asistente, el primer corazón marca la configuración
    como completa. La alternativa, guardar los corazones solo al salir del resultado, pierde lo
    marcado si el alumno cierra la app.
11. **Empate.** «Elegir como principal» abre una hoja con las dos ganadoras.
12. **Atrás en el resultado.** En el asistente no hace nada y en el Perfil equivale a «Decidir
    después».
13. **Héroe de la bienvenida en oscuro.** La maqueta lo muestra solo en claro. La spec lo deja
    naranja en los dos temas, con la tinta a 6,45:1.
14. **Cabecera del asistente.** Pasa a tinta sobre naranja en claro (6,45:1). El header de la app
    sigue en blanco sobre naranja (2,94:1), como decidió el dueño para el chat.
15. **Plumas en claro.** Van en `#D45500` en lugar del `#FF6600` de la maqueta, que da 2,81:1.
16. **Tarjeta del Perfil.** Sin maqueta, la spec la arma con las piezas del resultado y sin
    «Elegir como principal». El backend guarda el `specialtyId` pensando en elegir desde ahí
    (decisión abierta 8 del backend), así que el dueño puede pedir ese botón.
17. **Plazo de la evaluación.** 20 s, por los 5 s de Cohere y el arranque en frío.
18. **Lector de pantalla.** Sin avance solo y con «Siguiente».
19. **Desempate que no coincide.** Un reintento sin desempates y, si falla, el error.
20. **Choque con el backend sobre la escala de TI y `tb-sw-si-2`.** `decisiones.md` dice que
    esas dos tareas se quedan con su texto actual, porque el cotejo con las sumillas desaconseja
    los reemplazos. La spec del backend (decisión abierta 1 y RS-BE-37) todavía propone
    reemplazarlas y fija la primera versión en `2026-09-25.3`. La app no depende de esos textos
    ni de la versión, pero la spec del backend tiene que alinearse antes de su aprobación.
21. **`[@test]` pendientes.** `docs/specs/spec-template.md` pide no enlazar pruebas que no
    existen. Como en la spec del backend, cada enlace lleva *(pendiente)* hasta que la prueba
    exista.

## Verificación

- `dart format` sobre los archivos Dart que se crean o cambian.
- `flutter analyze --no-pub`.
- `flutter test --no-pub` con la suite completa, porque cambian `main.dart`, `auth_service.dart` y
  `perfil.dart`, que usan otras funcionalidades. Incluye `test/HU36_jeff`,
  `test/HU01_jeff/login_navigation_paths_test.dart` y `test/HU19_jeff`.
- `TZ=UTC flutter test --no-pub test/HU36_jeff`, para que la fecha de la tarjeta del Perfil no
  dependa de la zona del equipo.
- La app no se publica antes de que el backend tenga desplegadas las tres rutas y aplicada la
  migración `0014`, porque cada push a `main` publica el APK (`.github/workflows/build-apk.yml`).
- Un recorrido contra el backend desplegado con una cuenta de prueba, que termine una vez sin
  desempate y otra con dos, elija una principal, marque un corazón, rehaga el test desde el
  Perfil y vea ahí el último resultado.
- Una revisión manual en un iPhone SE, en claro y en oscuro, del asistente, las 14 preguntas, un
  desempate, el resultado y la tarjeta del Perfil, repetida con VoiceOver, con el texto más
  grande y con reducir movimiento.
