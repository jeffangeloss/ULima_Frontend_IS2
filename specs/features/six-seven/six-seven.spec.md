---
name: Truco del 67 (SIX SEVEN)
description: Guiño al meme «6 7» en el chat de Ulises y en los chats de sección. Un mensaje que es solo un 67 inclina la interfaz del chat de un lado a otro unos 2 segundos y muestra «SIX SEVEN!!!»
targets:
  - ../../../lib/domain/seis_siete/seis_siete.dart
  - ../../../lib/components/seis_siete/tambaleo_seis_siete.dart
  - ../../../lib/pages/chat/chat_seis_siete.dart
  - ../../../lib/pages/chat/chat_page.dart
  - ../../../lib/pages/chatbot/chatbot_controller.dart
  - ../../../lib/pages/chatbot/chatbot_page.dart
  - ../../../test/six_seven/**
  - ../../../test/HU23_jeff/chat_repo_falso.dart
---

# Truco del 67

> Estado: **diseñada el 2026-09-25 a partir de las decisiones del dueño de ese día. Pendiente
> de su aprobación de esta spec escrita antes de implementar.**
> Lo que el dueño decide y lo que la spec propone por defecto van separados en «Decisiones».
> Ninguna propuesta cuenta como aprobada hasta que el dueño la apruebe.
> El truco toca dos features. El chat de Ulises (`specs/features/chatbot/chatbot.spec.md`) y el
> chat de sección (`specs/features/chat/chat.spec.md`) llevan una nota que remite aquí
> («Cambios en otras specs»). El disparador, el tambaleo y la regla de movimiento reducido
> viven una sola vez en esta spec, porque los dos chats los comparten.
> No hay cambios de backend, de contrato, de reglas de Firebase ni de base de datos, y no
> entran dependencias nuevas.
> Las referencias `archivo:línea` apuntan a `main` en `41ff0a6`.
> Esta spec todavía no lleva enlaces `[@test]`, porque ninguna de sus pruebas existe. Cada
> requisito nombra el archivo que lo prueba y la sección «Pruebas» lista sus casos. El
> `[@test]` de cada requisito entra cuando su archivo exista.

## User Stories

| ID | Descripción |
| --- | --- |
| HU-67-01 | Como alumno, quiero que Ulises me conteste «SIX SEVEN!!!» y que el chat se mueva cuando le escribo «67», sin gastar mis preguntas. |
| HU-67-02 | Como integrante de una sección, quiero que el chat se mueva y diga «SIX SEVEN!!!» cuando alguien manda «67» mientras lo tengo abierto. |

## Contexto

Diagnóstico sobre `41ff0a6`.

- Ulises se abre desde su burbuja flotante (`chatbot_bubble.dart:86`), que lleva a `/chatbot`,
  cuya pantalla es `ChatbotPage`. La burbuja no cambia con esta spec.
- En el chat de Ulises, enviar pasa por `_submit` (`chatbot_page.dart:284-289`), que descarta el
  texto vacío y el envío mientras Ulises escribe, y después por `ChatbotController.sendQuestion`
  (`chatbot_controller.dart:92-136`). Hoy toda pregunta agrega la burbuja del alumno, enciende
  «escribiendo…», llama a `POST /chatbot/sessions/:id/ask` (`:109-113`) y al final vuelve a pedir
  la lista de conversaciones (`:135`). El backend cuenta cada `ask` en su límite de 20 preguntas
  por hora (BR-CB-11 de la spec de backend del chatbot).
- El historial de Ulises lo trae `loadMessages`, que reemplaza la lista entera
  (`chatbot_controller.dart:43-57`). La lista va con `reverse: true`
  (`chatbot_page.dart:323-326`), y dos workers la llevan al fondo cada vez que cambia
  (`:254-255`).
- El controller crea su `ChatbotService` sin inyección (`chatbot_controller.dart:8`), así que hoy
  no se puede probar con un servicio falso, y el chatbot no tiene pruebas.
- En el chat de sección, `getMessages` escucha `onValue` de los últimos 80 mensajes
  (`chat_repository.dart:95-116`). Cada evento trae la lista completa, no solo lo nuevo. El
  primer evento es el historial y cada evento siguiente repite lo ya visto más lo que llega o
  cambia.
- `ChatPage` crea ese stream dentro de `build` (`chat_page.dart:379-380`). Cada reconstrucción de
  la página le da al `StreamBuilder` un stream nuevo, así que cancela la suscripción anterior,
  vuelve a mostrar el indicador de carga (`:382-384`) y recibe otra vez el historial como primer
  evento.
- Los dos chats usan el `Scaffold` con el cuerpo que se achica cuando se abre el teclado, y su
  fondo es `MaterialTheme.pageBg` (`chatbot_page.dart:23` y `chat_page.dart:320`).
- La app detecta el movimiento reducido solo con `MediaQuery.disableAnimations`, por ejemplo en
  `chatbot_page.dart:272` y `:597`. En el Flutter del proyecto (3.47.2) esa marca corresponde a
  «Quitar animaciones» de Android. El «Reducir movimiento» de iOS llega aparte, en
  `AccessibilityFeatures.reduceMotion`, según la documentación de
  `MediaQueryData.disableAnimations`.
- Con «Quitar animaciones» activo, Flutter acorta al 5 % la duración de todo
  `AnimationController` con `AnimationBehavior.normal`
  (`packages/flutter/lib/src/animation/animation_controller.dart:651` del SDK).

## Requisitos

### RF-67-1. Qué mensaje es un 67

Una función pura, `esSeisSiete(String texto)`, decide si un texto es un 67. Vive en
`lib/domain/seis_siete/seis_siete.dart`, sin imports de Flutter ni de GetX, como el resto de
`lib/domain`. Los dos chats la usan y ningún otro archivo repite la regla.

El texto se normaliza en tres pasos y el resultado se compara con una lista cerrada.

1. Se quitan del principio y del final todos los espacios en blanco y todos los signos «!» y
   «¡», en cualquier orden y cantidad. Cuenta como espacio en blanco lo que reconoce `\s` en
   Dart, que incluye el espacio, la tabulación, el salto de línea y el espacio duro.
2. El texto pasa a minúsculas.
3. Cada tramo interno de espacios en blanco se reduce a un solo espacio.

El texto es un 67 solo si el resultado es exactamente `67`, `6 7`, `6-7`, `six seven` o
`six-seven`. Todo el mensaje tiene que ser el 67, así que un 67 dentro de una frase no cuenta. El
guion es solo el guion ASCII (`-`).

- **Disparan.** «67», «6 7», «6-7», «six seven», «six-seven», «SIX SEVEN», «Six-Seven»,
  «sIx sEvEn», «  67  », «67» con un salto de línea al final, «67!!!», «¡67!», «¡¡ 6 7 !!»,
  «!six seven!», «6   7» y «six», una tabulación y «seven».
- **No disparan.** «667», «1967», «676», «6767», «67 soles», «tengo 67 de nota», «el 67», «6.7»,
  «6,7», «6/7», «67%», «67?», «6 - 7», «6–7» (con raya corta), «6!7», «sixseven», «six 7»,
  «6 seven», «seis siete», «67 🙌», «"67"», «(67)», el texto vacío, «   » y «!!!».

Prueba por escribir `test/six_seven/seis_siete_test.dart`.

### RF-67-2. El tambaleo

Un solo widget, `TambaleoSeisSiete` (`lib/components/seis_siete/tambaleo_seis_siete.dart`),
envuelve la interfaz del chat y la inclina de un lado a otro, como el gesto de las manos del meme.

- **Qué se inclina.** La lista de mensajes y la barra de escritura, juntas y como una sola
  pieza. En el chat de Ulises es la columna de `_ChatArea` (`chatbot_page.dart:306-362`) y en el
  chat de sección, la columna de mensajes y barra (`chat_page.dart:364-374`). No se inclinan el
  AppBar, la barra de estado, el teclado del sistema ni, en el chat de Ulises en pantalla ancha,
  la lista de conversaciones de la izquierda.
- **Movimiento.** Es una rotación en el plano alrededor del centro del área inclinada. El ángulo
  en el instante t, con t entre 0 y T, es θ(t) = −A · sen(2π · n · t / T), con A = 3° (0,05236
  rad), n = 4 ciclos completos y T = 2000 ms. El `AnimationController` avanza lineal de 0 a 1 y
  el seno es la curva, así que el giro frena suave en cada extremo y pasa más rápido por el
  centro. El primer vaivén va hacia la izquierda, en sentido antihorario, que en Flutter es un
  ángulo negativo. Cada ciclo dura 500 ms, la velocidad pico ronda los 38° por segundo y el
  tambaleo termina justo en 0°, sin salto.
- **Cuánto se nota.** En un iPhone SE sin teclado, el área inclinada mide unos 375 × 591 pt, y
  con 3° sus esquinas se corren unos 16 pt de lado y 9 pt de alto. Con el teclado abierto mide
  unos 375 × 331 pt, y las esquinas se corren unos 9 pt de lado y 10 pt de alto.
- **La curva como función.** El ángulo sale de una función pura, `anguloSeisSiete(double
  progreso)`, en el archivo de RF-67-1. Recibe el avance entre 0 y 1 y devuelve radianes, y fuera
  de ese rango devuelve 0. A, n y T viven como constantes en ese mismo archivo.
- **Recorte y fondo.** El área inclinada va dentro de un `ClipRect` de su mismo tamaño, así que
  nada se pinta sobre el AppBar ni sobre la lista de conversaciones. Las esquinas que quedan al
  descubierto muestran el fondo del `Scaffold`, `MaterialTheme.pageBg`, en claro y en oscuro.
- **Disparo.** El widget recibe un contador de disparos, un entero que solo sube. Al montarse toma
  el valor que trae como punto de partida y no se mueve. Cada vez que se reconstruye con un valor
  mayor pide un tambaleo (RF-67-3), y reconstruirlo con el mismo valor no hace nada. Así, abrir el
  chat o reconstruirlo nunca lo dispara, y el contador solo lo sube quien detecta un 67 nuevo
  (RF-67-5 y RF-67-6).
- **Árbol estable.** El envoltorio está siempre en el árbol y en reposo pinta su hijo sin girar.
  Empezar o terminar un tambaleo no desmonta, no vuelve a montar y no reconstruye la lista, el
  `StreamBuilder`, el campo de texto ni ningún otro descendiente. El hijo va dentro de un
  `RepaintBoundary`, para que cada cuadro del tambaleo solo vuelva a componer la capa girada y no
  repinte los mensajes.
- **Teclado y foco.** El giro es solo de pintura y no cambia el layout, los `viewInsets`, el foco
  ni el texto del campo. Si el teclado está abierto, sigue abierto y quieto, porque es del sistema
  y no se dibuja dentro de la app. Si está cerrado, sigue cerrado. Ningún paso del truco llama a
  `unfocus` ni pide el foco.
- **Scroll.** El tambaleo no cambia la posición del scroll, no reemplaza su controlador y no corta
  un arrastre ni un desplazamiento en curso. Durante el tambaleo, los toques y los arrastres
  llegan a lo que se ve inclinado, como en cualquier `Transform`.
- **Al salir.** Si el usuario sale del chat en medio del tambaleo, la animación se descarta con el
  widget, sin errores ni animaciones pendientes.
- **Duración.** Con 2000 ms queda por debajo de los 5 s del criterio 2.2.2 de WCAG, que pide una
  forma de pausar las animaciones más largas.

Prueba por escribir `test/six_seven/tambaleo_seis_siete_test.dart`, y la curva en
`test/six_seven/seis_siete_test.dart`.

### RF-67-3. Varios 67 seguidos

- Hay un solo tambaleo a la vez. Un disparo que llega mientras dura otro no lo reinicia, no lo
  alarga, no se encola y no suma otro rótulo.
- Cuando el tambaleo termina, el siguiente 67 dispara uno nuevo, sin espera adicional.
- Un evento del chat de sección que trae varios 67 nuevos dispara un solo tambaleo.
- En el chat de Ulises, cada 67 que el alumno envía recibe su propia burbuja «SIX SEVEN!!!»
  (RF-67-5), aunque su tambaleo se ignore por llegar durante otro.
- Con movimiento reducido la ventana de «uno a la vez» dura lo mismo, 2000 ms, aunque no haya
  giro (RF-67-4).

Prueba por escribir `test/six_seven/tambaleo_seis_siete_test.dart`.

### RF-67-4. Movimiento reducido

- Si el teléfono pide menos movimiento, el truco no inclina nada y solo muestra el texto. Cuenta
  como pedido cualquiera de las dos marcas, `MediaQuery.disableAnimationsOf(context)`, que es
  «Quitar animaciones» en Android, o
  `View.of(context).platformDispatcher.accessibilityFeatures.reduceMotion`, que es «Reducir
  movimiento» en iOS.
- Las marcas se leen en el momento del disparo. Cambiar el ajuste en medio de un tambaleo no lo
  corta.
- Con movimiento reducido, en el chat de Ulises solo aparecen las dos burbujas (RF-67-5), con la
  entrada sin animación que la pantalla ya tiene (`chatbot_page.dart:597`). En el chat de sección,
  el rótulo aparece de golpe, sin fundido ni escala, y desaparece de golpe a los 2000 ms
  (RF-67-7).
- Los 2000 ms no se acortan con «Quitar animaciones». Como Flutter acorta al 5 % los
  `AnimationController` con `AnimationBehavior.normal`, el truco mide su duración con
  `AnimationBehavior.preserve` o con un `Timer`, nunca con un controller normal.

Prueba por escribir `test/six_seven/tambaleo_seis_siete_test.dart`.

### RF-67-5. En el chat de Ulises

- **Dónde se decide.** `ChatbotController.sendQuestion` revisa la pregunta con `esSeisSiete`
  antes que cualquier otro paso, con las mismas condiciones de hoy, que son una conversación
  activa y un texto no vacío (`chatbot_controller.dart:93-94`). El envío sigue pasando por
  `_submit`, que no deja enviar mientras Ulises escribe, así que el botón y la tecla de enviar del
  teclado siguen el mismo camino.
- **Qué pasa.** Si la pregunta es un 67, el controller agrega a `messages`, en este orden y en el
  mismo instante, la burbuja del alumno con el texto tal como lo envía, ya recortado por
  `_submit`, y la de Ulises con «SIX SEVEN!!!», con `role` igual a `assistant`. Las dos llevan un
  id local que empieza con `local-`, distinto de cualquier id del backend. Después sube su
  contador de disparos, un `RxInt` que lee el `TambaleoSeisSiete` que envuelve `_ChatArea`.
- **Qué no pasa.** No enciende «escribiendo…», no lee las notas locales, no llama a
  `POST /chatbot/sessions/:id/ask` ni a ningún otro endpoint, tampoco al refresco de la lista de
  conversaciones (`chatbot_controller.dart:135`), y no muestra avisos. Como el backend no recibe
  nada, Cohere tampoco, el 67 no cuenta en el límite de 20 preguntas por hora (BR-CB-11 del
  backend) y la conversación no cambia de título ni de fecha.
- **Historial.** Las dos burbujas viven solo en la memoria de la pantalla. Desaparecen cuando la
  conversación se vuelve a cargar del backend, al cambiar de conversación o al volver a abrir el
  chat, porque `loadMessages` reemplaza la lista (`chatbot_controller.dart:51`). Ulises tampoco
  las recuerda en sus respuestas siguientes, porque su contexto sale del historial del backend.
- **Scroll.** Las dos burbujas nuevas llevan la lista al fondo con los workers de siempre
  (`chatbot_page.dart:254-255`), y el tambaleo corre al mismo tiempo sin cambiar ese
  desplazamiento.
- **Abrir el chat no dispara.** En el chat de Ulises el truco nace solo del envío. Un historial
  que trae un «67» anterior a este truco no inclina nada. Reconstruir o volver a montar
  `_ChatArea`, por ejemplo al pasar de la lista de conversaciones al chat en un teléfono, tampoco,
  porque el envoltorio toma el contador actual como punto de partida (RF-67-2).
- **Un texto que no es un 67.** Sigue el camino de hoy sin cambios, también «67 soles» o «tengo
  67 de nota».
- **Inyección para pruebas.** `ChatbotController` acepta un `ChatbotService` opcional en su
  constructor, como `ChatPage` acepta su repositorio (`chat_page.dart:30-31`). Sin él usa el
  servicio real, así que `ChatbotPage` y la app no cambian. Las pruebas registran el controller
  con un servicio falso antes de montar la página, porque el `Get.put` de `ChatbotPage`
  (`chatbot_page.dart:18`) conserva la instancia ya registrada.

Prueba por escribir `test/six_seven/chatbot_seis_siete_test.dart`.

### RF-67-6. En los chats de sección

- **El mensaje se envía normal.** Un 67 sale por `_sendMessage` (`chat_page.dart:107-125`) como
  cualquier texto, con su cuerpo recortado tal como se escribe, y todos los miembros lo ven. Nada
  del truco pasa por el backend ni por las reglas de Firebase.
- **Un solo stream por página.** `ChatPage` crea el stream de mensajes una sola vez, cuando la
  sesión queda lista, y lo guarda en su estado. El `StreamBuilder` recibe esa misma instancia en
  cada `build`, en lugar de pedir un stream nuevo en cada construcción (`chat_page.dart:380`).
  Así una reconstrucción de la página, por el truco o por cualquier otra causa, no vuelve a
  suscribirse, no muestra el indicador de carga y no reemplaza la lista ni su scroll.
- **Qué es nuevo.** Un detector, `DetectorSeisSiete` (`lib/pages/chat/chat_seis_siete.dart`),
  guarda los ids que la página ya tiene vistos y no depende de Flutter. La primera lista que
  llega después de abrir el chat es el historial, así que solo marca sus ids como vistos y nunca
  dispara, aunque traiga uno o varios 67. En cada lista siguiente, un mensaje es nuevo si su id no
  figura en ninguna lista anterior de esta página. La lista dispara si al menos uno de los nuevos
  no está borrado, no es un carnet y su cuerpo cumple `esSeisSiete`. Todos los ids nuevos quedan
  como vistos, disparen o no.
- **Dónde se revisa.** Cada lista se revisa una sola vez, cuando llega del stream, y nunca dentro
  de `build`. Si dispara, la página sube un contador propio, un `ValueNotifier<int>`, y un
  `ValueListenableBuilder` pasa ese valor al envoltorio sin reconstruir el resto de la página.
- **Quién lo ve.** Quien envía el 67 lo ve porque Firebase entrega el mensaje propio al stream
  apenas se escribe, y quien tiene el chat abierto, cuando el mensaje le llega en vivo. Quien abre
  el chat después solo ve el mensaje en el historial, sin tambaleo ni rótulo. Rige para todos los
  roles de la sección, también el docente.
- **Lo que no dispara.** Un mensaje ya visto que vuelve en otro evento, como cuando se borra otro
  mensaje y el stream repite la lista. Una lápida nueva, aunque su cuerpo sea un 67. Un carnet.
  Los mensajes de la primera lista.
- **Segundo plano.** Si la app no está en primer plano cuando llega el 67, es decir si
  `WidgetsBinding.instance.lifecycleState` vale `paused`, `hidden` o `detached`, la página revisa
  la lista igual, para que sus ids queden vistos, pero no sube el contador. Así el tambaleo no
  espera a que la app vuelva para correr sobre un mensaje viejo. Con el estado nulo o `inactive`,
  el disparo sigue normal.
- **Reconexión.** Los mensajes que llegan después de un corte de red cuentan como nuevos, porque su
  id no figura en ninguna lista anterior de la página, y pueden disparar un tambaleo al
  reconectar. La spec no agrega una ventana de frescura por la hora del mensaje, porque la hora
  del teléfono puede estar corrida respecto de la del servidor.
- **Envío fallido.** Firebase entrega el mensaje propio antes de que el servidor lo confirme, así
  que el tambaleo de quien envía puede correr aunque después el envío falle y aparezca «No se pudo
  enviar el mensaje». Queda así a propósito, porque esperar la confirmación retrasa el truco en
  cada envío.

Pruebas por escribir `test/six_seven/detector_seis_siete_test.dart` y
`test/six_seven/chat_seccion_seis_siete_test.dart`.

### RF-67-7. El rótulo «SIX SEVEN!!!» en los chats de sección

Ulises no participa en los chats de sección, así que ahí «SIX SEVEN!!!» sale como un rótulo
pasajero sobre el chat y no como mensaje.

- **Qué es.** Un texto de la pantalla que no se guarda, no se envía, no entra en la lista de
  mensajes y que nadie más recibe.
- **Dónde.** Va centrado sobre el área de los mensajes, encima del área inclinada y fuera de
  ella, así que no se inclina y se lee quieto. Lo pinta el mismo `TambaleoSeisSiete`, con un
  parámetro que lo enciende solo en el chat de sección.
- **Aspecto.** Es una píldora con fondo `MaterialTheme.cardBg`, borde de 2 px en
  `MaterialTheme.iconoNaranja`, radio de 16 px, relleno de 20 px a los lados y 12 px arriba y
  abajo, y una sombra suave. El texto va en `textPrimary`, de 28 px, con `FontWeight.w900` y en
  una línea. Sobre `cardBg` da 17,85:1 en claro y 14,22:1 en oscuro, las cifras de RF-CHAT-8, así
  que cumple el 4,5:1 que ese requisito pide para todo texto de `ChatPage`. El borde naranja es
  decoración y no lleva texto.
- **Ancho.** El rótulo nunca pasa del ancho del área menos 16 px por lado. Con letra grande del
  sistema, el texto se achica para caber (`FittedBox` con `BoxFit.scaleDown`) y no se parte ni se
  desborda.
- **Tiempo.** Aparece con el tambaleo y dura lo mismo, 2000 ms. Entra con un fundido y una escala
  de 0,8 a 1 en 150 ms (`Curves.easeOutBack`) y sale con un fundido de 250 ms que termina a los
  2000 ms. Con movimiento reducido aparece y desaparece de golpe (RF-67-4).
- **Toques.** No bloquea nada, porque va dentro de un `IgnorePointer`. Los toques, el scroll y el
  campo de texto siguen funcionando debajo.
- **Lectores de pantalla.** Es una región viva (`Semantics` con `liveRegion: true`) con la
  etiqueta «SIX SEVEN!!!», para que TalkBack lo anuncie.
- En el chat de Ulises no hay rótulo, porque ahí el texto es la burbuja de Ulises (RF-67-5).

Pruebas por escribir `test/six_seven/tambaleo_seis_siete_test.dart` y
`test/six_seven/chat_seccion_seis_siete_test.dart`.

## Flujo de datos

```
Chat de Ulises
  _submit -> ChatbotController.sendQuestion(texto)
    esSeisSiete(texto)
      sí -> messages += burbuja del alumno + burbuja de Ulises «SIX SEVEN!!!»
            -> disparosSeisSiete++ -> fin, sin backend
      no -> camino de hoy (ask, «escribiendo…», refresco de conversaciones)
  Obx(disparosSeisSiete) -> TambaleoSeisSiete(_ChatArea)

Chat de sección
  getMessages, una vez por página -> cada lista -> DetectorSeisSiete.revisar(lista)
    primera lista -> base, sin disparo
    id nuevo, no borrado, no carnet, esSeisSiete, app en primer plano -> contador++
  ValueListenableBuilder(contador) -> TambaleoSeisSiete(mensajes + barra, con rótulo)
```

## Textos nuevos

«SIX SEVEN!!!», en la burbuja de Ulises (RF-67-5) y en el rótulo de los chats de sección
(RF-67-7). No hay otros.

## Contrato que se consume

Ninguno nuevo. El chat de Ulises deja de llamar a `POST /chatbot/sessions/:id/ask` solo cuando el
mensaje es un 67. El chat de sección envía y escucha igual que hoy («Contrato que se consume» de
`specs/features/chat/chat.spec.md`). No cambian el backend, `docs/specs/api-contracts.md`,
`database.rules.json` ni la base de datos.

## Cambios en otras specs

- `specs/features/chatbot/chatbot.spec.md` suma una nota de ajuste y, en «Input de pregunta», la
  excepción del 67, que remite a RF-67-5.
- `specs/features/chat/chat.spec.md` suma una nota de ajuste y, en RF-CHAT-2, el stream creado una
  sola vez por página, que remite a RF-67-6.
- `docs/specs/feature-index.md` suma la fila de esta spec.

## Qué NO entra

- Sonido, vibración, confeti o cualquier efecto aparte del tambaleo y del texto.
- El truco en otras pantallas, como anuncios, notas, la bandeja de chats o las vistas del docente
  fuera del chat.
- Guardar el 67 del chat de Ulises en el backend o contarlo en alguna estadística.
- Un aviso o una notificación del 67 para quien no tiene el chat abierto.
- Un enfriamiento entre tambaleos más allá de «uno a la vez» (RF-67-3).
- Variantes fuera de la lista de RF-67-1, como «seis siete», «6 - 7» o un 67 con emoji, salvo que
  el dueño las sume (D1).
- Llevar la lectura de «Reducir movimiento» de iOS al resto de las animaciones de la app, que hoy
  solo miran `disableAnimations`, como la entrada de las burbujas de Ulises y el latido de su
  burbuja flotante. Queda anotado en «Contexto» para un cambio aparte.

## Decisiones

### Lo que decide el dueño el 2026-09-25

| # | Decisión | Dónde queda |
| --- | --- | --- |
| 1 | El truco se inspira en el de Google al buscar «67» o «six seven», que inclina la página de un lado a otro unos segundos, como el gesto de las manos del meme «6 7» | RF-67-2 |
| 2 | Vive en el chat de Ulises y en los chats de las secciones de los cursos | RF-67-5 y RF-67-6 |
| 3 | Si alguien pone «67», toda la interfaz del chat se mueve hacia los lados como el gesto de las manos, y Ulises escribe «SIX SEVEN!!!» | RF-67-2, RF-67-5 y RF-67-7 |

### Propuestas por defecto que esperan su aprobación

El mismo día el dueño deja cuatro propuestas por defecto para que la spec las ponga a la vista.
La spec las adopta tal cual, y ninguna cuenta como aprobada hasta que el dueño la apruebe.

| # | Propuesta | Dónde queda |
| --- | --- | --- |
| P1 | Disparan «67», «6 7», «6-7», «six seven» y «six-seven», sin distinguir mayúsculas y con espacios o signos de exclamación alrededor | RF-67-1 |
| P2 | En el chat de Ulises, el 67 no llama al backend ni a Cohere, no gasta el límite de preguntas y no se guarda en el historial, y las burbujas del alumno y de Ulises son locales | RF-67-5 |
| P3 | En los chats de sección, el mensaje se envía normal y los demás lo ven. El tambaleo se ve en el teléfono de quien lo envía y en el de quien tiene el chat abierto cuando llega en vivo, no al abrir el historial, y «SIX SEVEN!!!» sale como rótulo pasajero sobre el chat | RF-67-6 y RF-67-7 |
| P4 | El tambaleo dura unos 2 segundos, y con reducir movimiento no hay tambaleo y solo sale el texto | RF-67-2 y RF-67-4 |

### Puntos que fija esta spec por su cuenta

Ninguno de estos puntos está en lo que decide o propone el dueño. La spec los fija con un valor
por defecto, y el dueño los confirma o los cambia al aprobarla.

| # | Punto | Valor por defecto | Alternativa | Dónde queda |
| --- | --- | --- | --- | --- |
| D1 | Variantes del disparador | La lista cerrada de P1. Varios espacios seguidos cuentan como uno, y «¡» cuenta como signo de exclamación | Sumar «seis siete», «6 - 7», «6–7», «sixseven» o un 67 con emoji | RF-67-1 |
| D2 | Amplitud | ±3° | ±2°, más sutil, o ±5°, más marcado | RF-67-2 |
| D3 | Ciclos, curva y sentido | 4 ciclos de seno en 2000 ms, de 500 ms cada uno, con el primero hacia la izquierda | 3 ciclos más lentos, o una envolvente que crece y se apaga | RF-67-2 |
| D4 | Qué se inclina | La lista de mensajes y la barra de escritura juntas, alrededor de su centro, con el AppBar, el teclado y la lista de conversaciones quietos | Barra fija con solo la lista de mensajes inclinada, o toda la pantalla con el AppBar | RF-67-2 |
| D5 | Varios 67 seguidos | Uno a la vez, sin reinicio, sin cola y sin enfriamiento. En el chat de Ulises, cada 67 recibe su burbuja | Reiniciar el tambaleo con cada 67, o un enfriamiento de unos segundos en los chats de sección | RF-67-3 |
| D6 | Qué cuenta como movimiento reducido | «Quitar animaciones» de Android y «Reducir movimiento» de iOS | Solo `disableAnimations`, como el resto de la app, que en iOS no ve el ajuste | RF-67-4 |
| D7 | Momento de la burbuja de Ulises | El mismo instante que la del alumno | Una pausa corta con «escribiendo…» antes de la burbuja | RF-67-5 |
| D8 | Vida de las burbujas locales | Desaparecen al recargar la conversación, y Ulises no las recuerda | Guardarlas en el historial, que pide un cambio del backend | RF-67-5 |
| D9 | Roles en los chats de sección | Todos, también el docente | Sin truco para el docente | RF-67-6 |
| D10 | Segundo plano y reconexión | Un 67 que llega con la app en segundo plano no dispara, y los que llegan al reconectar sí | Una ventana de frescura por la hora del mensaje | RF-67-6 |
| D11 | Envío fallido | El tambaleo de quien envía corre con el eco local de Firebase, aunque el envío falle después | Esperar la confirmación del servidor, con el retraso de la red | RF-67-6 |
| D12 | Rótulo | Píldora centrada que no se inclina, en `cardBg` con borde naranja y texto de 28 px, durante 2000 ms | Rótulo arriba, bajo el AppBar, o con la cara de Ulises | RF-67-7 |
| D13 | Stream del chat de sección | `ChatPage` lo crea una vez y lo guarda. Cambia cómo se cumple RF-CHAT-2, sin cambiar lo que se ve | Dejarlo como hoy, con el detector a salvo pero con la lista que se recarga en cada reconstrucción de la página | RF-67-6 |
| D14 | Pruebas | La carpeta `test/six_seven/` y un `ChatbotService` inyectable en `ChatbotController` | Otra carpeta, o un binding de GetX para el chatbot | RF-67-5 y «Pruebas» |

## Pruebas

Todas por escribir. Los datos son inventados, y un alumno de prueba usa el código `20230001`,
como en `test/HU23_jeff/chat_repo_falso.dart`, porque el repo es público.

### `test/six_seven/seis_siete_test.dart` (unitaria, RF-67-1 y RF-67-2)

- `esSeisSiete` da verdadero con cada caso de «Disparan» de RF-67-1 y falso con cada caso de «No
  disparan».
- `anguloSeisSiete` da 0 en 0, en 0,125, en 0,5 y en 1. Da −3° en 0,0625 y +3° en 0,1875, con una
  tolerancia de 1e-9 rad. En 1001 puntos entre 0 y 1 nunca pasa de 3° en valor absoluto, y fuera
  del rango da 0.

### `test/six_seven/detector_seis_siete_test.dart` (unitaria, RF-67-6)

- Una primera lista con dos 67 no dispara.
- Una segunda lista con un 67 de id nuevo dispara, y la misma lista repetida ya no.
- Una lápida nueva con cuerpo «67» no dispara, y un carnet nuevo tampoco.
- Un mensaje nuevo con «67 soles» no dispara.
- Una lista con dos 67 nuevos da un solo verdadero.
- Una primera lista vacía también es la base, y un 67 que llega después dispara.
- Una lista que repite los ids vistos sin el más viejo, como cuando un mensaje sale de la ventana
  de 80, no dispara.

### `test/six_seven/tambaleo_seis_siete_test.dart` (de widget, RF-67-2, RF-67-3, RF-67-4 y RF-67-7)

- Montado con el contador en 5 no gira ni muestra el rótulo, y reconstruido con 5 tampoco.
- Con el contador en 6, a los 125 ms el área gira −3°, a los 1000 ms vuelve a 0° y a los
  2000 ms queda sin giro y sin animaciones pendientes.
- Subir a 7 a los 500 ms no reinicia el tambaleo, que termina igual a los 2000 ms, y subir a 8
  después de terminar dispara otro.
- Un hijo con estado no se vuelve a montar ni pierde su estado al empezar ni al terminar el
  tambaleo.
- El área inclinada está dentro de un `ClipRect` y su hijo dentro de un `RepaintBoundary`.
- Con `disableAnimations` en el `MediaQuery` no hay giro en ningún momento, y con `reduceMotion`
  en las funciones de accesibilidad de prueba
  (`tester.platformDispatcher.accessibilityFeaturesTestValue`) tampoco.
- Con el rótulo encendido, «SIX SEVEN!!!» se ve sin girar durante el tambaleo y ya no está a los
  2000 ms. Un botón que queda debajo del rótulo recibe el toque.
- Con movimiento reducido y el rótulo encendido, el rótulo aparece sin giro, sigue a los 1900 ms
  y desaparece a los 2000 ms, también con `disableAnimations` activo en las funciones de
  accesibilidad de prueba, que acorta los controllers normales.
- Con el texto del sistema al doble, el rótulo cabe en 375 de ancho sin desborde.
- El rótulo tiene la semántica de región viva con la etiqueta «SIX SEVEN!!!».
- Quitar el widget del árbol a los 500 ms no deja errores ni animaciones pendientes.

### `test/six_seven/chatbot_seis_siete_test.dart` (de widget, RF-67-5)

Monta `ChatbotPage` con un servicio falso que devuelve una conversación y cuenta sus llamadas.

- Enviar «67» muestra la burbuja del alumno «67» y la de Ulises «SIX SEVEN!!!», no llama a
  `ask`, no vuelve a llamar a `listSessions` después de la carga, no muestra «escribiendo…» ni
  avisos, e inclina el área del chat y no el AppBar.
- Enviar «¡Six-Seven!» con la tecla del teclado hace lo mismo.
- Enviar «tengo 67 de nota» llama a `ask` una vez y no inclina nada.
- Una conversación cuyo historial trae «67» no inclina nada al abrirse.
- Dos «67» seguidos dan dos pares de burbujas y un solo tambaleo.
- Con el campo enfocado y el teclado visible, enviar «67» con el botón deja el foco en el campo y
  el teclado visible durante y después del tambaleo.
- Volver a cargar la conversación quita las dos burbujas locales.
- Con movimiento reducido aparecen las dos burbujas y no hay giro.

### `test/six_seven/chat_seccion_seis_siete_test.dart` (de widget, RF-67-6 y RF-67-7)

Monta `ChatPage` con `ChatRepoFalso` y le empuja listas en vivo.

- Un historial con «67» no inclina ni muestra el rótulo.
- Un «67» ajeno que llega en vivo inclina el chat y muestra «SIX SEVEN!!!», y a los 2000 ms no
  queda ninguno de los dos.
- Enviar «67» lo entrega al repositorio como mensaje normal, y cuando el stream lo trae como
  propio, el chat se inclina.
- Una lápida nueva con cuerpo «67», un carnet nuevo y un «tengo 67 de nota» nuevo no disparan.
- Reconstruir `ChatPage` desde su padre no vuelve a llamar a `getMessages`, no muestra el
  indicador de carga y no dispara.
- Dos 67 nuevos en un mismo evento dan un tambaleo, y otro 67 durante ese tambaleo no lo
  reinicia.
- Después de que termina el desplazamiento al último mensaje, la posición del scroll y su
  `ScrollPosition` son los mismos antes y después del tambaleo.
- Con el campo enfocado, el foco y el teclado siguen igual después del tambaleo.
- Con movimiento reducido aparece el rótulo sin giro.
- Con la app en `paused`, un 67 en vivo no dispara, y al volver a `resumed` no aparece nada.

### Apoyo que cambia

`test/HU23_jeff/chat_repo_falso.dart` suma dos cosas opcionales, un `StreamController` para
empujar listas en vivo y un contador de llamadas a `getMessages`. Sin el `StreamController` sigue
devolviendo `Stream.value(messages)`, así que ninguna prueba existente cambia.

## Verificación

- `dart format` sobre los archivos Dart que cambien.
- `flutter analyze --no-pub`, sin avisos nuevos.
- `flutter test --no-pub`, con la suite completa, porque el cambio toca `chat_page.dart` y el
  controller del chatbot.
- Una revisión manual en un iPhone SE, en claro y en oscuro, del chat de Ulises y de un chat de
  sección, con el teclado abierto y cerrado y con «Reducir movimiento» encendido y apagado. En el
  chat de sección, con dos teléfonos en la misma sección, para ver el 67 en vivo en los dos. En un
  Android, la misma revisión con «Quitar animaciones».
