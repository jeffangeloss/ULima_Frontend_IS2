---
name: Bienvenida con Ulises
description: Pantalla sin sesión que reemplaza a la tarjeta del login por una conversación con Ulises, con el logo entero en todo momento, en la que el que vuelve inicia sesión y el nuevo crea su cuenta y hace su test de especialidad sin cortes hasta su horario
targets:
  - ../../../lib/main.dart
  - ../../../lib/pages/bienvenida/**
  - ../../../lib/domain/bienvenida/**
  - ../../../lib/pages/login/**
  - ../../../lib/pages/registro/**
  - ../../../lib/pages/specialty_test/**
  - ../../../lib/pages/password_reset/reset_password_controller.dart
  - ../../../lib/services/session_navigation.dart
  - ../../../lib/services/api_client.dart
  - ../../../lib/components/google_sign_in_button_web.dart
  - ../../../lib/components/chatbot_bubble.dart
  - ../../../lib/components/logo/**
  - ../../../lib/configs/themes.dart
  - ../../../test/bienvenida/**
  - ../../../test/HU01_jeff/**
  - ../../../test/HU33_jeff/**
  - ../../../test/HU34_jeff/registro_consent_test.dart
  - ../../../docs/images/UI/bienvenida/**
  - ../../../README.md
---

# Bienvenida con Ulises

> Estado. **Diseñada el 2026-09-25 y pendiente de la aprobación del dueño antes de implementar.**
> Nada de esta spec está aprobado. «Decisiones» reúne primero los pedidos del dueño y después
> cada punto que confirma o cambia, con la opción que la spec toma por defecto, en dos tablas. La
> primera reúne las que cambian lo que ve el alumno, que decide el dueño, y la segunda las
> técnicas, que propone el equipo.
> El dueño elige el 2026-09-25 la versión combinada de «Ulises te recibe» para el arranque sin
> sesión, cuya maqueta es `docs/images/UI/bienvenida/ulises-te-recibe-combinada.html`. Esta spec
> describe todo lo que pasa después del relevo que fija RF-SPL-21 de
> `specs/features/splash/splash.spec.md`, que también está pendiente de aprobación.
> Enmienda `specs/features/auth/auth.spec.md` y `specs/features/registro/registro.spec.md`, y
> propone una enmienda a `specs/features/specialty-test/specialty-test.spec.md`, que el dueño
> aprueba el 2026-09-25 en la rama `feat/test-especialidad-fe` y que sigue sin implementar
> («Cambios en otras specs»). Las tres enmiendas quedan pendientes de aprobación con esta spec.
> Las referencias `archivo:línea` apuntan a `4e2a0b2`, la punta de `feat/splash-animado` el
> 2026-09-25. Las de la spec del test apuntan a `cabfb43` de `feat/test-especialidad-fe`, y las
> de `google_sign_in_web`, a la versión 0.12.4+4 que fija `pubspec.lock`.
> Los `[@test]` apuntan a pruebas que todavía no existen. Cada uno lleva «(pendiente)» y se
> escribe con la implementación.
> Donde esta spec y la maqueta difieren, manda la spec, y `docs/images/UI/bienvenida/README.md`
> lista las diferencias.

## User Stories

- Como alumno que vuelve, quiero que Ulises me reciba con el logo entero y me deje entrar con mi
  código o con Google, para llegar a mi horario.
- Como alumno nuevo, quiero crear mi cuenta y hacer mi test de especialidad en una sola
  conversación, sin pantallas que se corten, hasta ver mi horario.
- Como docente, quiero entrar con mi usuario o con Google desde la misma pantalla.
- Como persona que usa lector de pantalla, texto grande, teclado o menos movimiento, quiero
  seguir la conversación igual que los demás.
- Como alumno, quiero que la app no deje averiguar qué códigos tienen cuenta.

## Contexto

El diagnóstico sobre `4e2a0b2` es lo que la spec reemplaza o conserva.

- **La pantalla sin sesión.** `/login` muestra hoy una tarjeta de 340 dp sobre `#FF6600` en claro
  y sobre `#262626`, con la tarjeta en `#050505`, en oscuro (`login_page.dart:51-164` y
  `:459-502`). Lleva el ícono de la app en 96 dp (`:79-90`), el campo «Código» con la pista «Tu
  código o usuario» (`:94-106`), «Contraseña» (`:108-131`), «Entrar» (`:282-327`), «¿Olvidaste tu
  contraseña?» (`:329-351`), «¿No tienes cuenta? Créala» (`:353-381`) y el botón de Google
  (`:383-436`).
- **El controlador del login es permanente.** `LoginBinding` registra `LoginController` con
  `permanent: true` para evitar el «tipeo fantasma», y al volver a entrar limpia los campos
  después del cuadro (`login_binding.dart:25-38`). Todo camino que termina la sesión navega a
  `/login` por `offAllToLogin`, que no navega si `/login` ya es la ruta actual
  (`session_navigation.dart:32-39`), y una prueba prohíbe `Get.offAllNamed('/login')` fuera de ese
  archivo (`test/HU02_jeff/session_navigation_guard_test.dart`).
- **Quién llega a `/login`.** El arranque sin sesión (`main.dart:98-100`), el cierre de sesión
  del Perfil y del docente, el 401 del `ApiClient` con el aviso «Sesión expirada»
  (`api_client.dart:143-160`) y el restablecimiento de contraseña, que al terminar cierra la
  sesión y llama a `offAllToLogin` con el aviso «Contraseña actualizada»
  (`reset_password_controller.dart:150-166`). Con la spec del splash, el arranque sin sesión llega
  además con la pose del logo como argumento de ruta (RF-SPL-21).
- **El docente.** Entra con un usuario alfanumérico, así que el campo usa teclado de texto y la
  pista «Tu código o usuario» (`login_page.dart:94-106`).
- **El login con código.** `LoginController.submit` valida que ningún campo esté vacío, llama a
  `AuthService.login` y navega con `postLoginRoute` (`login_controller.dart:61-84`).
  `AuthService.login` solo atrapa `ApiException` (`auth_service.dart:218-250`), así que un fallo
  de red sale crudo, `submit` no llega a apagar `submitting` y el botón «Entrar» queda girando.
- **Google.** En Android y en iOS, el botón propio dice «Google» junto al logo oficial de
  `assets/images/google_logo.svg` (`login_page.dart:401-434`) y llama a `loginWithGoogle`
  (`auth_service.dart:255-268`). En web va el botón oficial de Google Identity Services, que se
  dibuja con `renderButton()` sin configuración (`google_sign_in_button_web.dart:29`), y la cuenta
  llega por `onCurrentUserChanged` (`login_controller.dart:24-47`). `renderButton` acepta un
  `GSIButtonConfiguration` con el tipo, el tema, el tamaño, el texto `continueWith`, la forma, la
  alineación del logo, el ancho mínimo y el idioma, y ningún otro estilo
  (`button_configuration.dart:30-81` y `:88-169` de `google_sign_in_web`). Google no crea
  cuentas, y sus errores tienen mensajes propios (`auth_service.dart:305-317`).
- **El registro.** `/registro` es una sola ruta con seis estados, `datos`, `consentimiento`,
  `verificar`, `enviando`, `listo` e `incierto` (`registro_controller.dart:11`). `RegistroBinding`
  usa `lazyPut` sin `fenix`, para que salir de la ruta borre las cinco credenciales en `onClose`
  (`registro_binding.dart:12-17` y `registro_controller.dart:149-163`). El paso de datos no llama
  al backend (`:165-184`), el consentimiento usa los textos de `PortalConsentView`
  (`portal_consent_view.dart:41-56`), el envío corre hasta 120 s (`registro_service.dart:28` y
  `:36-94`), un `PopScope` impide salir mientras se envía (`registro_page.dart:40-62`) y los
  estados `listo` e `incierto` cierran el recorrido (`:311-369` y `:393-462`). El enlace «Ya
  tengo cuenta» vuelve al login con `Get.back` (`:195-202`).
- **Después del registro.** Una cuenta nueva llega con `setupComplete` en `false` y
  `postLoginRoute` la manda a `/setup-carrera` (`post_login_route.dart:11-14`). La spec del test,
  aprobada en su rama, pone ahí la carrera, el test en la ruta `/test-especialidad` y la
  selección manual (RF-TEST-1). Su contenido exige el token del alumno, porque el servidor
  resuelve cada `specialtyId` con la carrera del alumno (RS-BE-38 de la spec del backend, rama
  `feat/test-especialidad`).
- **Los bindings y los avisos.** `main.dart:124-128` recuerda que un `Get.put` fuera de un
  binding, con un aviso abierto, puede atar el controlador a la ruta del aviso, que GetX borra al
  cerrarlo, y con él sus `TextEditingController`.
- **Ulises.** Su imagen es `assets/images/ulises_chatbot.png`, recortada en círculo. En `/home`,
  `ChatbotBubble` lo pone abajo a la izquierda (`chatbot_bubble.dart:73-75`), solo para el alumno
  (`home_page.dart:112`), y sin latido con reducir movimiento (`chatbot_bubble.dart:43-51`).
- **El nombre.** El backend manda el nombre como «APELLIDOS NOMBRES», y `firstName` no es el
  nombre de pila (`user_model.dart:52-65` y `:115-143`). Por eso la spec del test no agrega el
  nombre del alumno a las líneas de Ulises (su decisión abierta 8).
- **La cabecera.** `AppHeader` mide 50 dp de relleno arriba, la fila de 30 dp y 20 dp abajo, más
  un borde de 2 dp, con «ULIMA++» en 20 sp, cursiva y negrita, en blanco
  (`app_header.dart:57-88`). BR-SHELL-F-04, pendiente de aprobación, le suma la estrella de 26 dp.

## Requisitos

Los tiempos de la maqueta se cuentan en milisegundos y sus medidas en píxeles de una pantalla de
306 × 646. La app las escala a su pantalla en dp, y donde la spec fija una medida propia, manda
la spec.

### RF-BIEN-1. La ruta sin sesión y quién llega a ella

- **La ruta.** La bienvenida ocupa `/login`, que conserva su nombre y todos sus llamadores
  (decisión 32 del splash). La `GetPage` de `/login` pasa a mostrar la bienvenida, y la tarjeta
  de `login_page.dart` sale de la app, también en web (decisión 25).
- **Los controladores.** `LoginBinding` sigue registrando `LoginController` como permanente, con
  sus campos, `submit`, `loginWithGoogle` y la escucha de web, y registra también el controlador
  de la bienvenida como permanente (decisión 19). Al volver a entrar a `/login`, `LoginController`
  limpia sus campos después del cuadro, como hoy (`login_binding.dart:28-34`), y la bienvenida
  empieza su conversación desde cero al montarse, con los argumentos de la ruta nueva, así que su
  primer cuadro nunca muestra la visita anterior. Reiniciar la bienvenida borra la conversación y
  cierra el tramo del registro si quedó abierto (RF-BIEN-9).
- **La navegación queda en la bienvenida.** `LoginController` deja de navegar. Sus tres caminos,
  el código, Google en Android e iOS y Google en web, devuelven a la bienvenida si la sesión quedó
  puesta o el mensaje del error, y la bienvenida decide el turno siguiente (RF-BIEN-6).
- **`/registro` sale.** Salen la ruta, `RegistroPage` y `RegistroBinding` (decisión 23).
  `RegistroController`, sus validadores y `RegistroService` siguen y los usa la bienvenida
  (RF-BIEN-7).
- **El motivo de la llegada.** `offAllToLogin` suma un parámetro opcional `motivo`, que viaja como
  argumento de ruta junto a la pose del splash (RF-SPL-21 y decisión 21). El interceptor del 401
  pasa `expirada` y el restablecimiento de contraseña pasa `restablecida`. El cierre de sesión del
  Perfil y del docente no pasa ningún motivo y no cambia. La prueba que prohíbe navegar a `/login`
  fuera de `session_navigation.dart` sigue igual.

| Llegada | Argumentos | Cómo empieza | Requisito |
| --- | --- | --- | --- |
| Arranque en frío sin sesión | La pose del logo | El recibimiento | RF-BIEN-2 |
| Web, que no tiene intro (decisión 22 del splash) | Ninguno | El recibimiento corto | RF-BIEN-3 |
| Cierre de sesión del Perfil o del docente | Ninguno | El recibimiento corto (decisión 7) | RF-BIEN-3 |
| Un 401 con el aviso «Sesión expirada» | `motivo: expirada` | Directo a «Sí, entrar» (decisión 8) | RF-BIEN-3 |
| Contraseña restablecida | `motivo: restablecida` | Directo a «Sí, entrar» (decisión 8) | RF-BIEN-3 |

- **Las salidas.** La bienvenida sale hacia `/home` por el paso al horario (RF-BIEN-11), hacia
  `/setup-carrera` en el caso de la decisión 10 y hacia `/forgot-password`, que se abre encima con
  `Get.toNamed`, como hoy (decisión 9). Volver de `/forgot-password` deja la conversación como
  estaba.
- **La orientación.** Vertical, como toda ruta fuera de Horario (BR-SHELL-F-00 de app-shell).

`[@test] ../../../test/bienvenida/bienvenida_ruta_test.dart` (pendiente)

### RF-BIEN-2. El recibimiento después del splash

Es lo que ve el alumno sin sesión al abrir la app, entre el relevo del splash y su primera
respuesta. La maqueta lo muestra en las funciones `welcome` y `ulisesLlega`.

- **El primer cuadro.** La bienvenida recibe la pose del logo como argumento de ruta (RF-SPL-21 y
  decisión 33 del splash) y pinta en su primer cuadro `#E77330` de borde a borde y el logo blanco
  en esa pose, con la geometría de RF-SPL-2, en los dos temas. Avisa a la capa del splash cuando
  lo pinta, y la capa se retira sin fundido, así que la pantalla no cambia.
- **Quieto.** Durante 160 ms nada se mueve.
- **El vuelo de Ulises.** Ulises, recortado en círculo, entra desde arriba a la derecha, fuera de
  la pantalla, con 52 dp y una inclinación de −26°. Recorre en 1300 ms, con la curva seno, una
  curva de Bézier cúbica hasta su lugar, que en la maqueta va de (360, −44) a (66, 438) con los
  puntos de control (250, 40) y (−90, 250). Se inclina según su velocidad, hasta 14° a mitad del
  vuelo, se comprime cinco veces como un aleteo, crece hasta 58 dp y deja una estela de puntos
  blancos que se apagan en 560 ms, a lo sumo 30 por vuelo. Su sombra en el suelo crece al
  acercarse.
- **El aterrizaje.** Se posa con un rebote de 480 ms que lo aplasta contra el suelo y lo estira
  antes de asentarse, y suelta seis partículas blancas. Enseguida asiente en 320 ms, con un giro
  de −6° y un 6 % más de escala, mientras aparece su saludo.
- **El fondo.** Mientras Ulises vuela, el fondo pasa en 1100 ms, con la curva seno, de `#E77330`
  al color de la franja, que es `#FF6600` en claro y `#262626` en oscuro (RF-BIEN-14). El logo
  sigue blanco y quieto.
- **Dónde queda cada cosa.** La estrella se queda en su pose, entera y sin nada encima, con un
  margen libre de 12 dp alrededor de su círculo. Ulises aterriza abajo a la izquierda de la
  estrella, con 58 dp y su centro al 21,6 % del ancho y al 67,8 % del alto de la pantalla, como en
  la maqueta. La tarjeta del saludo va a su derecha, desde 19 dp después de su borde hasta 12 dp
  del borde derecho, con su pico hacia Ulises y su borde superior 22 dp arriba del centro de
  Ulises. Los dos botones van abajo, a 22 dp de los lados y 26 dp sobre el borde inferior del
  área segura, con 50 dp de alto y 10 dp entre ellos, «Sí, entrar» arriba y «Soy nuevo» abajo.
- **Si no cabe.** Si Ulises, la tarjeta o los botones entrarían en el margen de la estrella, por
  una pantalla baja o por la escala de texto, la estrella sube lo justo antes de que Ulises
  aterrice, en 300 ms con easeInOutCubic, sin acercarse a menos de 24 dp del área segura de
  arriba. Si aun así no cabe, la estrella baja su radio en el mismo movimiento, hasta 60 dp como
  mínimo. Nada tapa nunca la estrella.
- **El saludo.** La tarjeta entra en 360 ms con un leve rebote, con «¡Craa! Hola, soy Ulises 👋»
  en 12 sp y «¿Ya usas ULima++?» en 17 sp y negrita. 380 ms después entran los botones, en
  400 ms, desde 18 dp más abajo (decisión 2). Hasta que entran, los toques no hacen nada.
- **Los botones.** «Sí, entrar» va relleno y «Soy nuevo» con borde, en 16 sp y negrita, con los
  colores de RF-BIEN-14 (decisión 3). Cada uno se oscurece un 7 % al tocarlo.
- **Al responder.** La tarjeta y los botones se van en 280 ms, el logo sube al sello (RF-BIEN-4)
  y Ulises salta a su avatar en la conversación, que ya trae su primer grupo con el nombre
  «Ulises», las burbujas «¡Craa! Hola, soy Ulises 👋» y «¿Ya usas ULima++?» y la respuesta del
  alumno, «Sí, entrar» o «Soy nuevo» (RF-BIEN-5).
- **El salto de Ulises.** Empieza 120 ms después del toque. Se agacha en 190 ms, salta en 720 ms
  en un arco de unos 120 dp hasta su avatar de 40 dp y se posa con el rebote al 60 %. Al posarse,
  su avatar queda en la conversación y el nombre «Ulises» aparece en 250 ms. 650 ms después
  empieza el primer turno de la rama elegida.
- **Tiempo.** La tarjeta aparece 1,94 s después del relevo y los botones empiezan a entrar a los
  2,32 s, enteros a los 2,72 s. Sumada la entrada del splash, de 1,15 a 1,33 s, los botones
  empiezan a verse de 3,5 a 3,7 s después del primer cuadro de Flutter (decisión 2).

`[@test] ../../../test/bienvenida/bienvenida_recibimiento_test.dart` (pendiente)

### RF-BIEN-3. Llegar sin pose

- **Recibimiento corto.** Sin argumentos, que es la llegada de web y del cierre de sesión
  (decisión 7), el primer cuadro es `#E77330` de borde a borde con el logo completo en su pose de
  reposo, la estrella de R = 90 dp centrada en la pantalla física (RF-SPL-5) y los «++» en su
  lugar (RF-SPL-2). Desde ahí sigue igual que RF-BIEN-2, desde «Quieto». La bienvenida precarga la
  imagen de Ulises al montarse, porque sin pose no la precargó el splash.
- **Directo a «Sí, entrar».** Con `motivo: expirada` o `motivo: restablecida`, la bienvenida
  abre con la franja y el sello ya en su lugar (RF-BIEN-4), el primer grupo de Ulises con
  «¡Craa! Hola, soy Ulises 👋» y el primer turno de «Sí, entrar» (RF-BIEN-6), sin la pregunta ni
  los dos botones grandes (decisión 8). «Soy nuevo» queda en el compositor, como en todo turno de
  esa rama (RF-BIEN-9). Los avisos «Sesión expirada» y «Contraseña actualizada» siguen como hoy.
- En los dos casos, el sello y su logo están enteros desde el primer cuadro.

`[@test] ../../../test/bienvenida/bienvenida_recibimiento_test.dart` (pendiente)

### RF-BIEN-4. El sello, el latido y el pulso

- **La franja.** Mide lo mismo que la cabecera de `/home` (`app_header.dart:57-65`), va de borde
  a borde desde el borde superior de la pantalla, detrás de la barra de estado, y tiene las
  esquinas inferiores redondeadas en 26 dp, en el color de la franja (RF-BIEN-14).
- **El sello.** Es la estrella de BR-SHELL-F-04 y el texto «ULIMA++» de la cabecera, los dos a
  1,22 veces su tamaño, centrados a lo ancho y a la altura de la fila de la cabecera. «ULIMA» usa
  el estilo único de `app_header.dart` (RF-SPL-11), así que sigue la escala de texto del sistema
  como la cabecera, y los «++» son las cruces del logo (RF-SPL-2), inclinadas −12°.
- **La subida.** Empieza 90 ms después de la respuesta y dura 900 ms, con easeInOutCubic. El fondo
  de pantalla completa se recoge hasta la franja y sus esquinas inferiores pasan de 0 a 26 dp. La
  estrella va de su pose a su lugar en el sello, se achica hasta 1,22 × 26 dp de punta a punta y
  gira 45°, que por su simetría de orden ocho se ve igual. Cada «+» sale al 22 % del tiempo, el
  segundo un 6 % después, salta en un arco de 18 dp y cae tras «ULIMA», que se revela de
  izquierda a derecha desde el 55 %.
- **El logo no se pierde.** Desde el relevo del splash hasta el paso al horario, la estrella y
  sus «++» están enteros y a la vista, sin nada encima, también con el teclado abierto, durante
  el envío, en cualquier error y con reducir movimiento. Las únicas salidas que lo dejan de
  mostrar son las pantallas de hoy de «¿Olvidaste tu contraseña?» (decisión 9) y el asistente de
  carrera (decisión 10).
- **El latido.** Con cada respuesta del alumno y al posarse el sello, la estrella late durante
  380 ms. Su escala sube un 13 % en el primer 42 % del latido y un 5 % entre el 48 % y el 92 %,
  cada vez con la forma de medio seno, y un anillo blanco crece de 0,62 a 1,5 veces el radio de
  la estrella, con easeOutCubic, mientras su opacidad baja de 0,55 a 0. Los «++» y «ULIMA» no
  laten.
- **El pulso.** Mientras se envía el registro (RF-BIEN-8), un pulso recorre los ocho rombos en
  sentido horario desde el de arriba, con un período de 1100 ms. La opacidad de cada rombo es
  0,42 + 0,58 × máx(0; 1 − d / 2,4), donde d es la distancia circular, en rombos, entre ese rombo y
  la posición del pulso. La estrella central y los «++» quedan enteros. Con cualquier desenlace
  del envío, los rombos vuelven a la opacidad plena en 200 ms.
- **Semántica.** El sello es un encabezado con la etiqueta «ULIMA++», que el lector anuncia una
  vez. El dibujo queda fuera de la semántica.
- **Sin estrella en la cabecera.** Con la alternativa de la decisión 11 del splash, el sello
  conserva su estrella, y en el paso al horario la estrella se achica hasta la altura del texto y
  se disuelve a su izquierda, como en RF-SPL-11.

`[@test] ../../../test/bienvenida/bienvenida_sello_test.dart` (pendiente)

### RF-BIEN-5. La conversación

- **Las partes.** De arriba abajo van la franja con el sello, la conversación, que desplaza, y el
  compositor, fijo abajo y sobre el teclado. La píldora de estado del registro flota centrada, 8 dp
  bajo la franja (RF-BIEN-8). El fondo de la conversación es `pageBg`.
- **Los grupos de Ulises.** El primer grupo lleva el avatar de 40 dp y el nombre «Ulises» en
  11 sp, negrita y `testMuted`. Los siguientes llevan el avatar de 28 dp, sin nombre, arriba a la
  izquierda de sus burbujas. Cada burbuja va en `cardBg` con borde de 1 dp en `testLine`, radio de
  18 dp, con la esquina superior izquierda de la primera del grupo en 6 dp, relleno de 7 × 12 dp,
  texto de 14 sp en `textPrimary` y un ancho de hasta el 74 % de la columna.
- **Las respuestas del alumno.** Van a la derecha, en `bienvenidaPropia` con el texto en
  `bienvenidaPropiaTinta` y negrita, con radio de 18 dp y la esquina inferior derecha en 6 dp, y
  un ancho de hasta el 72 % de la columna. Un dato secreto se muestra como un candado y un rótulo,
  nunca con su valor (RF-BIEN-9).
- **El ritmo.** Dentro de un turno, cada burbuja de Ulises entra 850 ms después de la anterior y
  el compositor 500 ms después de la última. Cada burbuja entra en 340 ms, subiendo 8 dp y de
  98 % a 100 % de escala con un leve rebote, y la conversación se desplaza en 450 ms hasta el
  final. No hay puntos de «escribiendo», como en el test (RF-TEST-4). Con lector de pantalla, las
  burbujas de un turno entran juntas (RF-BIEN-16).
- **El compositor.** Va en `cardBg`, con un borde superior de 1 dp en `testLine` y un relleno de
  10, 12 y 24 dp más el área segura inferior. Entra en 300 ms, subiendo 8 dp. Mide hasta el 60 % del
  alto disponible sobre el teclado y, si su contenido es más alto, desplaza por dentro. Sus
  piezas son estas.

| Pieza | Cómo es |
| --- | --- |
| Rótulo | 11,5 sp, negrita, en `testInk2`, 5 dp sobre su campo |
| Campo | 48 dp de alto como mínimo, radio de 14 dp, fondo `testChipBg` y texto de 15 sp en `textPrimary`. Con foco, fondo `cardBg` y borde de 2 dp en `bienvenidaFoco`. La pista va en `testMuted` y no en el `#8A94A6` de la maqueta, que da 2,72:1 |
| Ojo de la contraseña | Botón de 48 dp dentro del campo, con el ícono de hoy (`registro_page.dart:107-127`) en `testMuted` |
| Botón de envío | Círculo de 48 dp a la derecha del último campo, con la flecha en `testAccentInk` sobre el degradado de `testAccentHi` a `testAccent`. Inactivo, al 40 %, mientras el campo está vacío |
| Respuestas rápidas | Píldoras de 48 dp de alto, alineadas a la derecha, con borde de 1,5 dp en `testAccent` y texto de 14 sp en negrita y `testAccentText`. La principal va rellena con el degradado y el texto en `testAccentInk` |
| Botón principal | A lo ancho, 48 dp de alto, radio de 15 dp, relleno con el degradado y texto de 15 sp en negrita y `testAccentInk`. Mientras espera, un indicador de 20 dp en su lugar |
| Enlace secundario | Texto de 13 sp en negrita y `testAccentText`, centrado, con 48 dp de alto táctil. «¿Olvidaste tu contraseña?» va en `testMuted`, como en la maqueta |
| Error local | Bajo el campo, 12 sp en `testAccentText` con el ícono `LucideIcons.circleAlert`, como región viva |

- **Al responder.** El compositor se cierra, entra la burbuja del alumno, el sello late y 650 ms
  después empieza el turno siguiente.
- **Los errores de Ulises.** Un error del backend o de la red es una burbuja de Ulises con el
  ícono `LucideIcons.circleAlert` en `testAccentText` a la izquierda del texto (RF-BIEN-12). Un
  error de validación local va bajo el campo y no entra en la conversación.
- **El historial.** Vive solo en la memoria del controlador de la bienvenida, como el texto de las
  burbujas. No se guarda en disco y se borra al reiniciar la bienvenida y al pasar al horario. Es
  de solo lectura, y tocar una burbuja no hace nada.
- **El teclado.** Cuando el compositor trae un campo, el campo toma el foco y el teclado se abre,
  salvo con lector de pantalla (RF-BIEN-16). La conversación se encoge, la franja queda arriba y
  el último mensaje a la vista. La acción «Siguiente» del teclado pasa de «Contraseña» a «Repetir
  contraseña», y «Listo» o Intro envían. Arrastrar la conversación cierra el teclado, como hoy en
  el login (`login_page.dart:30`).

`[@test] ../../../test/bienvenida/bienvenida_conversacion_test.dart` (pendiente)

### RF-BIEN-6. «Sí, entrar»

Es el inicio de sesión dentro de la conversación, con las reglas de BR-AUTH-F-01 a BR-AUTH-F-10
de auth, enmendadas («Cambios en otras specs»).

| Turno | Ulises dice | Compositor | Respuesta del alumno |
| --- | --- | --- | --- |
| E1, código | «¡Qué bueno verte! ¿Cuál es tu código o usuario?» | Rótulo «Código», campo con la pista «Tu código o usuario», teclado de texto y el botón de envío. Debajo, el separador «o», el botón «Continuar con Google» y el enlace «Soy nuevo» | El código o usuario tal como se escribió, recortado |
| E2, contraseña | «Y tu contraseña de ULima++.» | Rótulo «Contraseña», campo con la pista «Tu contraseña» y el ojo, el botón principal «Entrar» y los enlaces «¿Olvidaste tu contraseña?» y «Soy nuevo» | Un candado y «Contraseña lista» |
| E3, despedida | «¡Hola de nuevo! Te llevo a tu horario 🪶» | Ninguno | Ninguna. Sigue el paso al horario (RF-BIEN-11) |

- **Los campos.** Son los `TextEditingController` de `LoginController`, con las pistas de
  autocompletado de hoy, usuario en E1 y contraseña en E2 (`login_page.dart:105` y `:117`). El
  campo de E1 acepta el usuario alfanumérico del docente y no valida dígitos. El botón de envío de
  E1 y «Entrar» quedan inactivos mientras su campo está vacío, así que el mensaje «Ingresa tu
  código y contraseña.» sigue en `LoginController` solo como defensa.
- **Entrar.** «Entrar» llama a `AuthService.login` por `LoginController`. Mientras espera, el
  botón muestra su indicador y el compositor no responde (BR-AUTH-F-08). Si la sesión queda
  puesta, el compositor se cierra, entra la respuesta del alumno, el sello late, Ulises dice la
  despedida y, 900 ms después, empieza el paso al horario.
- **El error del login.** Ulises dice el mensaje de hoy (`auth_service.dart:28-36`) y la
  conversación vuelve a E1, con el código escrito y la contraseña vacía (decisión 6). Ese mensaje
  nunca ofrece crear una cuenta (RF-BIEN-9).
- **Sin conexión.** La bienvenida atrapa el fallo crudo de la red que `AuthService.login` no
  atrapa. Ulises dice «No hay conexión. Revisa tu internet e inténtalo de nuevo.» y E2 sigue
  abierto con la contraseña escrita. El botón deja de girar, lo que corrige el defecto de hoy.
- **Google en Android e iOS.** «Continuar con Google» es el botón propio, con el logo oficial de
  `google_logo.svg` en 20 dp, 48 dp de alto, radio de 12 dp y los colores de la marca de Google
  (RF-BIEN-14), y llama a `loginWithGoogle`. Si la persona cancela el selector, no pasa nada. Si
  la sesión queda puesta, la respuesta del alumno es una burbuja con el logo de Google y
  «Continuar con Google», y sigue E3. Un error se dice como burbuja de Ulises y E1 sigue abierto.
- **Google en web.** Va el botón oficial de GIS en lugar del propio, con el texto `continueWith`,
  el idioma `es`, el tema `outline` en claro y `filledBlack` en oscuro, la forma rectangular, el
  logo a la izquierda y el ancho del compositor hasta 400 px, el máximo de GIS (decisión 25). La
  cuenta sigue llegando por `onCurrentUserChanged`.
- **«¿Olvidaste tu contraseña?».** Abre `/forgot-password` encima de la bienvenida, como hoy
  (decisión 9).
- **«Soy nuevo».** Está en E1 y en E2. Al tocarlo, entra la respuesta «Soy nuevo», los campos del
  login se vacían y empieza el primer turno de RF-BIEN-7. Lo escrito no pasa de una rama a la
  otra, como hoy entre `/login` y `/registro`.
- **Adónde va.** Con la sesión puesta, un docente o un alumno con la configuración completa va al
  paso al horario. Un alumno con la configuración a medias va a `/setup-carrera`, como hoy, con
  un fundido de 300 ms en lugar de E3 (decisión 10). Con la alternativa de la decisión 24 del
  splash, en la que el docente abre en Secciones, la despedida del docente es solo «¡Hola de
  nuevo!».

`[@test] ../../../test/bienvenida/bienvenida_entrar_test.dart` (pendiente)

### RF-BIEN-7. «Soy nuevo», los datos de la cuenta

Es el registro de hoy, con sus reglas BR-REG-F-01 a BR-REG-F-11, repartido en turnos. El orden es
el de BR-REG-F-01, con el consentimiento antes del portal y el código del authenticator al final,
justo antes del botón que envía.

| Turno | Ulises dice | Compositor | Respuesta del alumno |
| --- | --- | --- | --- |
| N1, código | «¡Genial! Tu cuenta se crea aquí mismo.» y «¿Cuál es tu código de alumno?» | Rótulo «Código de alumno», campo con la pista «Tu código de alumno», teclado numérico y el botón de envío. Debajo, el enlace «Ya tengo cuenta» | El código, recortado |
| N2, contraseña de ULima++ | «Ahora elige la contraseña con la que entrarás a ULima++. No es la de miUlima.» | Rótulo «Contraseña», campo con la pista «Al menos 8 caracteres» y el ojo, rótulo «Repetir contraseña», campo con la pista «La misma otra vez» y el botón de envío. Debajo, los enlaces «Volver» y «Ya tengo cuenta» | Un candado y «Contraseña de ULima++ lista» |
| N3, consentimiento | «Para traer tus cursos entro a miUlima una sola vez. Antes, lee esto 👇» y la tarjeta del consentimiento | Las respuestas rápidas «Volver» y «Acepto», la principal, y el enlace «Ya tengo cuenta» | «Acepto» o «Volver» |
| N4, contraseña de miUlima | «Tu contraseña de miUlima, la del portal.» | Rótulo «Contraseña de miUlima», campo con la pista «Tu contraseña del portal», el ojo y el botón de envío. Debajo, «Volver» y «Ya tengo cuenta» | Un candado y «Contraseña de miUlima lista» |
| N5, authenticator | «Último paso. El código de tu authenticator.» | Rótulo «Código del authenticator», el campo de seis casillas de hoy (`PasswordResetOtpField`), la nota «El código de 6 dígitos que cambia cada 30 segundos.» y el botón principal «Crear mi cuenta». Debajo, «Volver» y «Ya tengo cuenta» | Un candado y «Código del authenticator listo» |

- **La tarjeta del consentimiento.** Es una burbuja ancha de Ulises con los textos literales de
  `PortalConsentView`, tomados de sus constantes, que son el título «Antes de entrar a miUlima»,
  la introducción, los cuatro datos importados como lista, la finalidad y «Tu contraseña se usa
  una sola vez y no se guarda.» en negrita (`portal_consent_view.dart:41-56`). Así dice lo mismo
  que la pantalla de Portal Sync (RF-REC-6).
- **La validación.** Cada turno valida lo suyo en local, con los validadores de hoy, antes de
  cerrar el compositor y sin llamar a la red (BR-REG-F-03). N1 usa `validarCodigo`, N2 usa
  `validateNewPassword` y `validatePasswordConfirmation`, N4 usa `validarPortalPassword` y N5 usa
  `validarPasscode`, que acepta de 6 a 8 dígitos. Sus mensajes van bajo el campo.
- **El envío es un botón.** N5 no envía solo al completar las seis casillas, porque SecurID da 8
  dígitos con el PIN delante y cada envío fallido gasta uno de los cinco intentos por hora
  (decisión 5).
- **«Volver».** Reabre el turno anterior con lo que se escribió, como hoy entre pasos
  (BR-REG-F-05). Entra la respuesta «Volver» y Ulises repite la pregunta de ese turno. Aceptado
  una vez, el consentimiento dura lo que dura la rama, así que al volver a avanzar desde N2 se
  pasa directo a N4, como hace hoy `continuar` (`registro_controller.dart:181-183`).
- **«Ya tengo cuenta».** Está en todos los turnos antes del envío. Al tocarlo, entra la respuesta
  «Ya tengo cuenta», el tramo del registro se cierra y borra sus cinco campos (RF-BIEN-9) y
  empieza E1 de RF-BIEN-6.
- **El paso a `verificar`.** Al aceptar en N3 se llama a `aceptarConsentimiento`, y al enviar en
  N5 se llama a `enviar`, con el código recortado y el consentimiento, como hoy.

`[@test] ../../../test/bienvenida/bienvenida_registro_test.dart` (pendiente)

### RF-BIEN-8. El envío del registro y sus desenlaces

- **Mientras se envía.** Se cierra el compositor, entra la respuesta de N5 y Ulises dice «Estoy
  creando tu cuenta y trayendo tu ciclo. Tarda cerca de un minuto.» y «No cierres la app mientras
  tanto.» (decisión 17). La píldora «Creando tu cuenta…», con su indicador, aparece bajo la franja
  y el pulso recorre los rombos del sello (RF-BIEN-4). No hay «Volver» ni «Ya tengo cuenta».
- **El plazo.** Es el de `RegistroService`, 120 s, y su vencimiento no es un fallo (BR-REG-F-08).
- **No se sale.** Un `PopScope` de la bienvenida veta el atrás del sistema mientras se envía y
  muestra el aviso de hoy, «Estamos creando tu cuenta» con «No cierres la app: si sales ahora
  podrías quedarte con una cuenta a medias.» (BR-REG-F-09 y `registro_page.dart:73-78`).
- **Un 201.** Se para el pulso, la píldora pasa a verde con un visto y «Cuenta creada», y Ulises
  dice «¡Craa! Tu cuenta ya está lista.» seguido de la frase del conteo. Con N cursos en el
  resumen, la frase es «Traje tus N cursos del ciclo.», con uno es «Traje tu curso del ciclo.» y
  sin conteo no va. El nombre no se agrega (decisión 4). La píldora se va 900 ms después.
- **Los avisos del 201.** Si la respuesta trae `warnings`, Ulises suma una burbuja con «Algunas
  cosas que notamos» en negrita y cada `message` tal cual en su línea, precedido de «· », como hoy
  en `listo` (`registro_page.dart:339-354`). Un 201 con avisos es un éxito (BR-REG-F-07).
- **Después del 201.** `adoptarSesion` guarda la sesión como hoy, con los catálogos tolerantes a
  fallos, y nada de lo que pase después se convierte en un error (BR-REG-F-10). El tramo del
  registro se cierra y borra sus campos (RF-BIEN-9), y sigue el test (RF-BIEN-10). No hay botón
  «Entrar».
- **Un error del backend.** Ulises dice el mensaje de `RegistroService.mensajeDeError`, con los
  textos de hoy, y el compositor vuelve al turno que corresponde, sin repetir la pregunta. Los
  códigos que hoy vuelven a `datos` (`USER_ALREADY_EXISTS`, `INVALID_REQUEST_BODY` e
  `INVALID_JSON_BODY`) vuelven a N1, y los que vuelven a `verificar`, a N5
  (`registro_controller.dart:265-286`). Todo lo escrito se conserva salvo el código del
  authenticator, que se borra (BR-REG-F-05). Desde N5, «Volver» lleva a N4 con la contraseña de
  miUlima intacta.
- **Sin conexión.** Ulises dice «No hay conexión. Revisa tu internet e inténtalo de nuevo.» y el
  compositor vuelve a N5.
- **Incierto.** Con el plazo vencido, Ulises dice «No pudimos confirmar si tu cuenta se creó.» y
  «Es posible que sí se haya creado. Prueba entrar con el código y la contraseña que acabas de
  elegir.». Con `SIN_TOKEN`, el 201 ya llegó, y dice «Tu cuenta ya está creada.» y «Entra con el
  código y la contraseña que acabas de elegir.», más el mensaje del error si no repite el título
  (`registro_page.dart:405-433`). El compositor trae las respuestas rápidas «Volver a intentar el
  registro» e «Iniciar sesión», la principal (BR-REG-F-11).
- **«Iniciar sesión» desde incierto.** Llama a `intentarIniciarSesion`, con la píldora principal
  en espera y sin segundo toque. Si entra, la cuenta existía y sigue el test (RF-BIEN-10), o el
  paso al horario si la configuración ya está completa. Si no entra, Ulises dice «Seguimos sin
  poder confirmarlo. Puedes volver a intentar el registro: si te dice que ya existe una cuenta
  con ese código, es que sí se creó y puedes recuperar la contraseña desde el login.», o el
  mensaje sin conexión, y el turno sigue igual.
- **«Volver a intentar el registro».** Vuelve a N5 con el código del authenticator borrado y la
  contraseña de miUlima intacta.

`[@test] ../../../test/bienvenida/bienvenida_registro_test.dart` (pendiente)

### RF-BIEN-9. Las credenciales y la enumeración de cuentas

- **Los cinco campos.** El código, la contraseña de ULima++, su repetición, la contraseña de
  miUlima y el código del authenticator viven en los `TextEditingController` de
  `RegistroController` (RS-FE-6). Las dos contraseñas, la repetición y el código del
  authenticator no entran nunca en un `Rx`, en el historial, en un registro ni en el disco, y el
  historial solo guarda sus rótulos, como «Contraseña de ULima++ lista». El código de alumno es
  la excepción, porque su burbuja lo muestra, como en la maqueta. Entra en el historial como texto
  y muere con él (RF-BIEN-5), igual que el código o usuario de E1. Hoy el comentario de
  `registro_controller.dart:100-102` deja fuera de todo `Rx` también el código, y la enmienda del
  registro lo anota.
- **Quién crea y cierra el controlador.** La bienvenida crea `RegistroController` al empezar N1 y
  lo cierra ella misma, sin `Get.put`, porque un aviso abierto, como «Sesión expirada», ataría el
  controlador a la ruta del aviso (`main.dart:124-128`). Cerrarlo borra los cinco campos con
  `clear` antes de `dispose`, como `onClose` (decisión 20).
- **Cuándo se cierra.** Al tocar «Ya tengo cuenta», al pasar al test después de adoptar la
  sesión, al reiniciar la bienvenida y cuando GetX retira `/login`. Las contraseñas de miUlima y
  el código del authenticator se borran además apenas se usan, como hoy
  (`registro_controller.dart:244-246`). La contraseña de ULima++ sigue en memoria solo mientras
  dura `incierto`, para su salida «Iniciar sesión» (BR-REG-F-11).
- **Las dos contraseñas nunca a la vez.** La de ULima++ y la de miUlima van en turnos distintos
  del compositor, con el consentimiento en medio, y el compositor de una se cierra antes de que
  aparezca el de la otra (RS-FE-2).
- **Sin oráculo de cuentas.** «Soy nuevo» está siempre en los turnos de «Sí, entrar», y «Ya
  tengo cuenta» en todos los turnos del registro antes del envío, fijos, como hoy los enlaces del
  login y del registro (RS-FE-3 y BR-REG-F-02). Ningún texto de Ulises ofrece crear una cuenta ni
  cambia según por qué falló un login, también tras «Tu correo no está registrado en el
  sistema.» de Google. Ningún turno anterior al envío consulta al backend por un código, y la
  pregunta «¿Ya usas ULima++?» no depende de nada guardado en el teléfono.
- **La deuda de hoy.** El `409 USER_ALREADY_EXISTS` del backend sigue distinguiendo por sí mismo
  si un código tiene cuenta, como anota la spec del registro en «Deuda conocida». La bienvenida
  no lo agrava ni lo arregla.

`[@test] ../../../test/bienvenida/bienvenida_credenciales_test.dart` (pendiente)

### RF-BIEN-10. El test dentro de la conversación

El alumno nuevo sigue con el test de especialidad sin salir de la conversación, con el mismo
servicio, el mismo contenido y las mismas reglas de la spec del test (RF-TEST-2 y RF-TEST-4 a
RF-TEST-14), dibujados como turnos. Es la enmienda propuesta a esa spec («Cambios en otras
specs»).

- **Cuándo empieza.** Después del 201 y de adoptar la sesión, o después de entrar desde
  `incierto` con la configuración a medias. El contenido exige el token, así que el test no
  empieza mientras se crea la cuenta (decisión 1).
- **T0, la invitación.** Al empezar, la bienvenida pide el contenido una vez con
  `SpecialtyTestService.fetchContent`. Mientras llega, Ulises muestra una burbuja de
  `SkeletonPulse`. Cuando llega, dice «¿Empezamos tu test de especialidad? Son T preguntas
  cortas.», donde T es el número de preguntas del contenido, y el compositor trae «Saltar y elegir
  por mi cuenta» y «Empezar el test», la principal. El paso de carrera no aparece, porque la
  carrera sale del usuario (decisión 11), y tampoco las líneas `welcome` del contenido, porque
  Ulises ya se presentó (decisión 12).
- **Si el contenido no llega.** Sin conexión, con el plazo vencido, con un contenido no válido o
  con otro error, Ulises dice «No pudimos cargar el test.» y el compositor trae «Saltar y elegir
  por mi cuenta» y «Reintentar». Con `404 SPECIALTY_TEST_NOT_AVAILABLE`, la conversación pasa a la
  selección manual sin aviso (RF-TEST-1).
- **Cada pregunta es un turno.** Ulises dice las líneas que manda RF-TEST-4, que son `duelHelp`
  antes de la pregunta 1, la reacción a la respuesta anterior, `scaleHelp` antes de la primera
  escala y el `blockClose` con el sello «Cierra el bloque k de B» junto a su burbuja, y después el
  `prompt` de la pregunta en su propia burbuja. En una escala, esa burbuja lleva primero la tarea
  en negrita y debajo el `prompt`, como en la maqueta.
- **El duelo en el compositor.** Arriba, el rótulo «Esto o aquello · N de T» en 10,5 sp,
  mayúsculas y `testAccentText`. Debajo, las dos tarjetas apiladas con la moneda «o» entre ellas y,
  en dos columnas, «Me gustan las dos» y «Ninguna me llama», con las etiquetas de `duelOptions`,
  una debajo de otra desde la escala de texto 1,3. Las tarjetas son las de la maqueta, de 56 dp de
  alto como mínimo, con la baldosa de 40 dp y el ícono de la tarea en 22 dp (decisión 13), y
  siguen las reglas de RF-TEST-5 para quedar neutras hasta el toque, encenderse en el color de su
  especialidad, llevar la insignia del visto y apagar la otra.
- **La escala en el compositor.** El rótulo «Escala de gusto · N de T» y las cuatro opciones de
  `scaleOptions` con sus emojis, en una fila o en dos por dos según RF-TEST-6. La escala no lleva
  el ícono de la tarea, que en RF-TEST-6 es decorativo.
- **Al elegir.** A los 350 ms, o con «Siguiente» si hay lector de pantalla (RF-TEST-5), el
  compositor se cierra y entra la respuesta del alumno, que es el texto de la tarea elegida, «Me
  gustan las dos», «Ninguna me llama» o, en una escala, el emoji y la etiqueta, como «🤩 Me
  encantaría». El sello late.
- **«Pregunta anterior».** Es un enlace del compositor desde la pregunta 2, en los desempates y en
  la espera. Entra la respuesta «Pregunta anterior» y Ulises repite el paso previo con la
  respuesta previa marcada, con las reglas de RF-TEST-4 sobre los desempates y la evaluación en
  vuelo. Desde la pregunta 1 lleva a T0.
- **La espera.** Ulises dice `ulises.loading` con un indicador de 16 dp en `testAccent` a su
  lado (RF-TEST-7). El compositor queda vacío.
- **El desempate.** Ulises dice la `ulisesLine` del servidor, y el compositor trae el duelo con el
  rótulo «Desempate 1» o «Desempate 2».
- **El resultado.** Entra el confeti una vez con `HapticFeedback.heavyImpact`, y Ulises dice
  `headline` y, si llega, `tiebreakOutcome` (RF-TEST-8). Debajo van, a lo ancho de la columna, la
  tarjeta de la número uno con las piezas de RF-TEST-8 y una segunda tarjeta con los electivos y
  «También te puede interesar», con sus corazones de 48 dp. El compositor trae «Elegir como
  principal», a lo ancho, y debajo, en dos columnas, «Decidir después» y «Rehacer el test». El
  resultado queda en la conversación, que desplaza (decisión 15).
- **Guardar.** Rigen las reglas de RF-TEST-9, con un guardado a la vez, el plazo de 15 s, los
  corazones que guardan enseguida y el primer guardado que completa la configuración. Si «Elegir
  como principal» o «Decidir después» guardan, entra su respuesta, Ulises dice «¡Listo! Te llevo
  a tu horario 🪶» y, 900 ms después, empieza el paso al horario (RF-BIEN-11). Si fallan o vencen,
  Ulises dice el aviso de RF-TEST-11 y el compositor vuelve a responder.
- **«Rehacer el test».** Entra su respuesta y la conversación vuelve a la pregunta 1 con el mismo
  contenido, sin pasar por T0.
- **La selección manual.** Con «Saltar y elegir por mi cuenta» o el `404`, Ulises dice «Elige una
  mención como tu diploma principal.» y el compositor trae la lista oficial con «Principal» y «Me
  interesa» y el botón de hoy, «Saltar por ahora» o «Finalizar configuración», con las reglas de
  RF-TEST-1 y RF-TEST-14. Si el catálogo no carga, dice «No pudimos cargar las especialidades.»
  con «Reintentar». Al guardar sigue la despedida de «Guardar». El atrás del sistema en este turno
  lleva a T0 si el test está disponible.
- **Sin pausa.** No hay botón de pausa ni de salto dentro de las preguntas, porque el alumno nuevo
  no tiene un asistente al que volver (decisión 14). Cerrar la app a mitad deja la configuración a
  medias (RF-BIEN-13).
- **Lo que no aparece.** El héroe de RF-TEST-3 con sus pastillas «3 a 4 min» y «Rehazlo en
  Perfil», la barra de 52 px de RF-TEST-4 con las plumas, el historial plegado y la pausa. El
  contador de preguntas pasa al rótulo del compositor y el historial es la propia conversación.
- **El docente.** Nunca ve el test, igual que en RF-TEST-1.

`[@test] ../../../test/bienvenida/bienvenida_test_especialidad_test.dart` (pendiente)

### RF-BIEN-11. El paso al horario

Cierra la conversación del que vuelve y la del nuevo. La maqueta lo muestra en `toHorario` y
`flyDock`.

- **La navegación.** La bienvenida navega a `/home` con `Get.offAll`, con el `page` y el `binding`
  de su `GetPage`, `routeName: '/home'`, `Transition.noTransition` y el argumento
  `{'pestana': 'horario'}` de RF-SPL-20, igual que la intro del splash (RF-SPL-4). La capa de la
  app que usa la intro dibuja encima la franja, el sello y a Ulises mientras `/home` se monta
  debajo. Antes de navegar, la capa toma una imagen de la conversación y del compositor para
  desvanecerla, y la bienvenida cierra el tramo del registro si sigue abierto y borra el
  historial. La imagen se descarta al retirarse la capa.
- **La franja y el sello.** En 1050 ms, las esquinas de la franja pasan de 26 dp a 0 en el primer
  40 % con easeInOutCubic y su color va al `headerColor` del tema. La conversación y el compositor
  se desvanecen en el primer 35 %. La página de `/home` aparece entre el 22 % y el 55 %, y su
  cuerpo entre el 32 % y el 75 %, subiendo 24 dp. La campana y el resto de la cabecera aparecen
  entre el 70 % y el 100 %. El sello va a la cabecera con easeInOutCubic, la estrella a su lugar
  de 26 dp junto a «ULIMA++» (BR-SHELL-F-04) y los «++» con un salto de 6 dp. En el último 25 %,
  las cruces dibujadas se funden con los glifos del texto, como en RF-SPL-11.
- **Ulises vuela a su burbuja.** Al mismo tiempo, Ulises sale de su último avatar de la
  conversación, se oculta ese avatar y vuela en 1150 ms, con la curva seno, por la derecha y hacia
  arriba en una Bézier que baja a la esquina de `ChatbotBubble`. Crece hasta 1,6 veces en el
  primer 45 % y se achica hasta 56 dp, con un aleteo que se apaga al final y una inclinación de
  hasta 12°. Se posa en 420 ms con un aplastamiento, y en ese cuadro aparece la burbuja real, con
  su latido (decisión 16).
- **Dónde aterriza.** En el lugar inicial de `ChatbotBubble`, que la burbuja informa una vez que
  se dibuja, como la cabecera informa su estrella (RF-SPL-11). La burbuja queda oculta hasta que
  Ulises aterriza.
- **El docente.** No tiene burbuja en `/home` (`home_page.dart:112`), así que Ulises se desvanece
  con la conversación en el primer 35 %.
- **El último cuadro.** La capa muestra lo mismo que la página de debajo, y al retirarse la
  pantalla no cambia.
- **La orientación.** Mientras la capa cubre la pantalla, la app sigue en vertical, y Horario pide
  sus orientaciones cuando la capa se retira, como con la intro (decisión 26 del splash).
- **Si algo falla.** Si la cabecera o la burbuja no se pueden medir, si la ruta de debajo cambia,
  por ejemplo por un 401 de las peticiones de `/home`, o si la capa de la intro no está montada,
  como puede pasar en web sin intro (decisión 22 del splash), el paso es un fundido de 300 ms.
- **Durante el paso.** Ningún toque llega a la página de debajo ni a la conversación.

`[@test] ../../../test/bienvenida/bienvenida_horario_test.dart` (pendiente)

### RF-BIEN-12. Errores y sin conexión

El recibimiento y los turnos antes de un envío no usan la red, así que una caída solo se nota al
entrar, al enviar el registro, en el test y al guardar. Cada error del backend o de la red es
una burbuja de Ulises (RF-BIEN-5).

| Momento | Caso | Qué ve el alumno |
| --- | --- | --- |
| Recibimiento y turnos sin envío | Sin conexión | Nada |
| E2 | `401 USER_NOT_FOUND` o `INVALID_PASSWORD` | «Código o contraseña incorrectos.» y vuelta a E1 con el código (decisión 6) |
| E2 | `403 NOT_ENROLLED` | «No tienes una matrícula activa.» y vuelta a E1 con el código |
| E2 | Otro error del backend | Su mensaje y vuelta a E1 con el código |
| E2 | Sin conexión | «No hay conexión. Revisa tu internet e inténtalo de nuevo.», con E2 abierto y la contraseña escrita |
| E1, Google | La persona cancela | Nada |
| E1, Google | `403 INVALID_DOMAIN` | «Debes usar tu correo @aloe.ulima.edu.pe o @ulima.edu.pe.» |
| E1, Google | `401 USER_NOT_FOUND` | «Tu correo no está registrado en el sistema.», sin ofrecer crear la cuenta |
| E1, Google | Sin `idToken` u otro fallo | «No se obtuvo información de Google.» o «No se pudo iniciar sesión con Google.» |
| N1 a N5 | Validación local | Los mensajes de hoy bajo el campo |
| Envío | Cada código de la tabla de la spec del registro | Su mensaje y vuelta a N1 o a N5 según esa tabla (RF-BIEN-8) |
| Envío | Sin conexión | «No hay conexión. Revisa tu internet e inténtalo de nuevo.» y vuelta a N5 |
| Envío | 120 s sin respuesta | `incierto` con el plazo vencido |
| Envío | 201 sin token o ilegible | `incierto` con la cuenta confirmada |
| Después del 201 | Los catálogos fallan | Nada, como en BR-REG-F-10 |
| T0 | El contenido no llega | «No pudimos cargar el test.», con «Reintentar» |
| Test | Cada fila de RF-TEST-11 | Su texto como burbuja de Ulises y la misma salida que allí |
| Cualquier turno con sesión | Un 401 | «Tu sesión caducó o iniciaste sesión en otro dispositivo.» y E1 |
| Paso al horario | La cabecera o la burbuja no se miden | El fundido de 300 ms |

- **El 401 con sesión.** Después de adoptar la sesión, `/login` sigue siendo la ruta actual, así que
  el interceptor del 401 borra la sesión y `offAllToLogin` no navega (`api_client.dart:143-160`).
  Tras cada fallo de un turno con sesión, la bienvenida comprueba si el token guardado sigue ahí
  (decisión 22). Si ya no está, hace la misma limpieza local que `AuthService.logout`, sin llamar al
  backend porque no hay token, y Ulises dice «Tu sesión caducó o iniciaste sesión en otro
  dispositivo.», que es el texto del aviso «Sesión expirada», que en `/login` no aparece. Después
  vuelve a E1. Las respuestas del test en memoria se pierden, como al cerrar sesión (RF-TEST-2).

`[@test] ../../../test/bienvenida/bienvenida_errores_test.dart` (pendiente)

### RF-BIEN-13. Volver atrás, segundo plano y cerrar la app a mitad

- **El atrás del sistema.** Hace lo mismo que el enlace secundario del turno.

| Dónde | Qué hace el atrás |
| --- | --- |
| Recibimiento y E1 | Sale de la app, como hoy en `/login` |
| E2 | Vuelve a E1 con el código escrito |
| N1 | «Ya tengo cuenta» |
| N2 a N5 | «Volver» |
| Envío | Nada, con el aviso de BR-REG-F-09 |
| `incierto` | «Volver a intentar el registro» |
| T0 y el resultado | Nada, porque la cuenta ya existe y las respuestas del compositor deciden |
| Preguntas, desempates y espera | «Pregunta anterior», y desde la pregunta 1, T0 |
| Selección manual | T0 si el test está disponible, y nada si no |
| Paso al horario | Nada |

- **Segundo plano.** La conversación queda como está y sus animaciones se pausan. Si el sistema
  corta la petición del registro mientras la app está en segundo plano, el plazo de 120 s lleva a
  `incierto`, como hoy.
- **Cerrar la app a mitad.** Nada de la conversación se guarda, así que el siguiente arranque en
  frío pasa por el splash y decide con la sesión guardada.

| Cuándo se cierra | Qué pasa al abrirla |
| --- | --- |
| En el recibimiento, en «Sí, entrar» o en el registro antes del envío | La bienvenida desde el principio. Las credenciales murieron con el proceso |
| Durante el envío | La bienvenida desde el principio. La cuenta puede existir, y si la persona repite el registro recibe «Ya existe una cuenta con ese código. Inicia sesión o recupera tu contraseña.», que es el riesgo que RS-FE-5 acepta |
| Después del 201, antes de guardar la especialidad | La sesión está guardada con la configuración a medias, así que abre `/setup-carrera` (decisión 10), donde el test empieza de cero (RF-TEST-8) |
| Después del primer corazón o de guardar | La configuración está completa y abre `/home` en Horario |

`[@test] ../../../test/bienvenida/bienvenida_atras_test.dart` (pendiente)

### RF-BIEN-14. Modo oscuro y contraste

- **Tema.** La bienvenida sigue `Theme.of(context).brightness`. Sus widgets no llevan hex sueltos,
  y sus colores son tokens de `MaterialTheme`. Reusa `pageBg`, `cardBg`, `textPrimary`,
  `headerColor` y los tokens del test (RF-TEST-12), que son `testInk2`, `testMuted`, `testLine`,
  `testChipBg`, `testAccent`, `testAccentHi`, `testAccentInk`, `testAccentText` y
  `testAccentSoft` (decisión 24).
- **Tokens nuevos.** Salen de la paleta de la maqueta, salvo donde la tabla dice otra cosa.

| Token | Claro | Oscuro | Uso |
| --- | --- | --- | --- |
| `bienvenidaFranja` | `#FF6600` | `#262626` | La franja del sello y el fondo del recibimiento después del relevo |
| `bienvenidaPropia` | `#FFE7D4` | `#3A2A22` | Fondo de las respuestas del alumno |
| `bienvenidaPropiaTinta` | `#6B2D00` | `#FFC49A` | Texto de las respuestas del alumno |
| `bienvenidaSaludo` | `#FFFFFF` | `#33333B` | Tarjeta del saludo del recibimiento |
| `bienvenidaSaludoTinta` | `#1A0E05` | `#F5F5F7` | «¿Ya usas ULima++?» |
| `bienvenidaSaludoSub` | `#7A3300` | `#FFC49A` | «¡Craa! Hola, soy Ulises 👋» en la tarjeta |
| `bienvenidaEntrarFondo` | `#FFFFFF` | `#FF8C42` | Botón «Sí, entrar» |
| `bienvenidaEntrarTinta` | `#1A0E05` | `#16161C` | Texto de «Sí, entrar» |
| `bienvenidaNuevoFondo` | `#B84A00` | transparente | Botón «Soy nuevo», con la decisión 3 (la maqueta usa blanco al 14 %) |
| `bienvenidaNuevoBorde` | `#FFFFFF` | `#5A5A66` | Borde de 1,5 dp de «Soy nuevo» |
| `bienvenidaNuevoTinta` | `#FFFFFF` | `#EDEDF3` | Texto de «Soy nuevo» |
| `bienvenidaPildora` | `#0F172A` | `#33333B` | Píldora «Creando tu cuenta…» |
| `bienvenidaPildoraLista` | `#15803D` | `#15803D` | Píldora «Cuenta creada» |
| `bienvenidaGoogleFondo` | `#FFFFFF` | `#131314` | Botón «Continuar con Google», colores de la marca de Google |
| `bienvenidaGoogleBorde` | `#747775` | `#8E918F` | Borde de 1 dp del botón de Google |
| `bienvenidaGoogleTinta` | `#1F1F1F` | `#E3E3E3` | Texto del botón de Google |
| `bienvenidaFoco` | `#D45500` | `#FF8C42` | Borde del campo con foco y anillo de foco del teclado (la maqueta usa `#FF6600`, que da 2,94:1) |

- **Contraste.** Todo texto llega a 4,5:1 contra su fondo en los dos temas y todo ícono que da
  información, o borde de foco, a 3:1, con las dos excepciones de la tabla.

| Par | Claro | Oscuro |
| --- | --- | --- |
| Texto de las burbujas sobre `cardBg` | 17,85:1 | 14,22:1 |
| Nombre «Ulises» en `testMuted` sobre `pageBg` | 6,09:1 | 7,42:1 |
| Respuesta del alumno | 8,81:1 | 8,87:1 |
| «¿Ya usas ULima++?» sobre la tarjeta | 18,94:1 | 11,50:1 |
| «¡Craa! Hola, soy Ulises 👋» sobre la tarjeta | 9,13:1 | 8,12:1 |
| «Sí, entrar» | 18,94:1 | 7,79:1 |
| «Soy nuevo» sobre su fondo | 5,23:1 | 12,98:1 sobre `#262626` |
| Pista del campo en `testMuted` sobre `testChipBg` | 5,67:1 | 6,34:1 |
| Enlaces en `testAccentText` sobre `cardBg` | 5,23:1 | 7,91:1 |
| Texto sobre las píldoras y botones rellenos con `testAccent` | 6,45:1 | 7,79:1 |
| Píldora «Creando tu cuenta…» y «Cuenta creada», en blanco | 17,85:1 y 5,02:1 | 12,52:1 y 5,02:1 |
| Botón de Google | 16,48:1, borde 4,53:1 | 14,47:1, borde 5,21:1 sobre `cardBg` |
| Borde de foco sobre `cardBg` | 4,12:1 | 7,17:1 |
| «ULIMA++» y el sello en blanco sobre la franja | 2,94:1, riesgo conocido | 15,13:1 |
| Logo blanco sobre `#E77330` en el primer cuadro | 3,05:1, decorativo | 3,05:1, decorativo |

- **Las excepciones.** El blanco sobre `#FF6600` del sello es el mismo de la cabecera de toda la
  app, un riesgo conocido que el dueño acepta el 2026-09-25 para la cabecera del asistente
  (decisión 9 de la spec del test). El logo del primer cuadro es un dibujo sin texto.
- **El recibimiento en oscuro.** Después del relevo, el fondo pasa de `#E77330` a `#262626`, el
  logo sigue blanco y la tarjeta y los botones toman sus tokens oscuros. La conversación usa
  `#16161C` de fondo y `#1E1E24` en las burbujas y el compositor.
- **El test.** Dentro de la conversación rigen los colores y la guarda de contraste de RF-TEST-12.

`[@test] ../../../test/bienvenida/bienvenida_contraste_test.dart` (pendiente)

### RF-BIEN-15. Reducir movimiento

Con `MediaQuery.disableAnimationsOf(context)` en `true`, nada se mueve, gira ni cambia de escala.

- **El recibimiento.** Ulises no vuela. Aparece en su lugar con un fundido de 160 ms, 120 ms
  después del relevo, sin sombra, estela ni partículas. El fondo cambia en 150 ms. La tarjeta y los
  botones aparecen con fundidos de 180 ms, sin desplazamiento.
- **La subida al sello.** El fondo y el logo se desvanecen en 220 ms, el logo aparece en el sello
  en otros 220 ms, y Ulises pasa a su avatar con un fundido de 140 ms.
- **El sello.** No late. Durante el envío no hay pulso, y la píldora con «Creando tu cuenta…»
  dice sola que se espera, con su indicador quieto.
- **La conversación.** Las burbujas y el compositor entran con un fundido de 200 ms, sin subir, y
  la conversación salta al final sin desplazarse. El cursor del campo no parpadea.
- **El ritmo se queda.** Las pausas entre burbujas no son movimiento, así que siguen.
- **El test.** Rige RF-TEST-13, sin confeti, giro ni crecimiento.
- **El paso al horario.** La conversación y el sello se desvanecen en 220 ms mientras aparece
  `/home`, el sello aparece en la cabecera en 200 ms y la burbuja de Ulises aparece en su lugar,
  sin latido.

`[@test] ../../../test/bienvenida/bienvenida_movimiento_test.dart` (pendiente)

### RF-BIEN-16. Accesibilidad

- **La estructura.** El sello es un encabezado, «ULIMA++». La conversación es una lista en orden.
  Cada grupo de Ulises se lee como «Ulises» seguido de sus burbujas, y cada respuesta del alumno
  como «Tú, <texto>». Los candados, los emojis de las respuestas, la imagen de Ulises, sus vuelos,
  la estela, las partículas y el anillo del latido quedan fuera de la semántica.
- **El recibimiento.** Mientras la capa del splash está encima, el lector solo ve su etiqueta
  «ULIMA++, cargando» (RF-SPL-15). Con un lector de pantalla activo
  (`MediaQuery.accessibleNavigation`), la tarjeta y los botones aparecen con el relevo, sin
  esperar el aterrizaje, y el foco del lector pasa a la tarjeta, que se lee «¡Craa! Hola, soy
  Ulises. ¿Ya usas ULima++?», y después a los dos botones.
- **Cada turno.** Con lector de pantalla, las burbujas de un turno entran juntas, y el foco del
  lector pasa a la primera burbuja nueva de Ulises. El orden de lectura sigue por las burbujas y
  termina en el compositor. El campo no toma el foco del teclado solo, y el lector anuncia su
  rótulo y su pista al llegar a él.
- **Regiones vivas.** La píldora del registro y el error local bajo un campo son regiones vivas,
  así que se anuncian «Creando tu cuenta…», «Cuenta creada» y cada error. Las burbujas de Ulises no
  lo son, porque el foco ya las lee, y así nada se anuncia dos veces.
- **Los controles.** Los dos botones del recibimiento, las respuestas rápidas, el botón principal
  y los enlaces son botones con su texto. El botón de envío se lee «Enviar», y el ojo, «Mostrar
  contraseña» u «Ocultar contraseña», con su estado. La tarjeta del consentimiento se lee entera
  en su orden. En el test rigen las etiquetas de RF-TEST-13.
- **Blancos táctiles.** Todo control mide al menos 48 dp de alto, y los de ícono, 48 × 48.
- **El teclado físico y la web.** El orden de foco va del campo al botón de envío y después a los
  enlaces. Intro envía. El foco del teclado se ve con el anillo de 2 dp en `bienvenidaFoco`.
- **Tamaño de texto.** Todo respeta `MediaQuery.textScaler` hasta el 200 %. Ningún contenedor de
  texto tiene alto fijo. Las burbujas crecen, el compositor desplaza por dentro cuando pasa del
  60 % del alto y el recibimiento aplica su regla «Si no cabe» (RF-BIEN-2). A 375 × 667, con 1,0,
  1,3 y 2,0, nada desborda.
- **Sin límite de tiempo.** Ningún turno vence, salvo la vigencia propia del código del
  authenticator, que no depende de la app. Las pausas del ritmo no quitan tiempo para responder.
- **El color nunca va solo.** Los errores llevan su ícono y su texto, y la respuesta elegida en el
  test lleva los estados de RF-TEST-13.

`[@test] ../../../test/bienvenida/bienvenida_accesibilidad_test.dart` (pendiente)

### RF-BIEN-17. Barra de estado, orientación y pantallas anchas

- **La barra de estado.** La bienvenida declara íconos claros en los dos temas con un
  `AnnotatedRegion<SystemUiOverlayStyle>` en su raíz, porque arriba siempre hay `#E77330`, la
  franja naranja o la franja `#262626` (RF-SPL-4). La barra de navegación del sistema queda como
  en el resto de la app.
- **La orientación.** Vertical en toda la bienvenida (RF-BIEN-1).
- **Pantallas anchas.** En tabletas y en web, la conversación, el compositor, Ulises, la tarjeta
  del saludo y los botones del recibimiento van en una columna de 600 dp como máximo, centrada.
  La franja va de borde a borde, y la estrella sigue en el centro de la pantalla física
  (RF-SPL-5).

`[@test] ../../../test/bienvenida/bienvenida_barra_estado_test.dart` (pendiente)

### RF-BIEN-18. Rendimiento

- **Sin paquetes nuevos.** La bienvenida usa solo el SDK de Flutter y los paquetes que ya están,
  con `CustomPainter`, `AnimationController`, `Curves` y `TextPainter`.
- **El logo.** El sello y el logo del recibimiento se pintan con la geometría de RF-SPL-2, cuyos
  caminos se construyen una vez. El latido y el pulso repintan solo el pintor del sello, con su
  `repaint`, sin reconstruir widgets en cada cuadro.
- **Ulises.** Su imagen está en caché antes del relevo (RF-SPL-21 y RF-BIEN-3). Su vuelo es una
  transformación de una capa aislada con `RepaintBoundary`. La estela y las partículas no pasan de
  36 puntos vivos a la vez, y no hay desenfoques ni `BackdropFilter`.
- **La conversación.** Es una lista perezosa con una clave por burbuja, así que una burbuja nueva
  no reconstruye las anteriores. Una conversación completa, con el registro y 14 preguntas, ronda
  las 80 burbujas.
- **Fluidez.** Se mide en modo perfil con la línea de tiempo de DevTools, en un Android de gama de
  entrada con pantalla de 60 Hz y en el iPhone SE del dueño, en el recibimiento, la subida al
  sello, el pulso y el paso al horario. En cada tramo, a lo sumo un cuadro pasa de 16,7 ms en el
  hilo de UI o en el de raster y ninguno pasa de 33,4 ms. Queda fuera de la medida el cuadro que
  construye `/home` bajo la capa, como en RF-SPL-17.
- **El teclado.** Abrir y cerrar el teclado no reconstruye la franja ni el sello.

Sin prueba automática. La medición va en «Verificación».

### RF-BIEN-19. La maqueta

- `docs/images/UI/bienvenida/ulises-te-recibe-combinada.html` queda como referencia visual, con los
  recorridos «Con sesión», «Soy nuevo» y «Ya tengo cuenta», la intro al azar o elegida, Repetir,
  modo oscuro y reducir movimiento. Está en el repo desde `026107d`.
- `docs/images/UI/bienvenida/README.md` dice que manda esta spec y lista las diferencias entre la
  maqueta y la spec.
- Sus datos son ficticios. El código `20230001`, la alumna Valeria, el código del authenticator
  `482913`, los cursos y las aulas son inventados.
- La maqueta difiere de la spec en estos puntos.
  - El test empieza mientras se crea la cuenta, con «Mientras tanto, ¿empezamos tu test de
    especialidad? Son 14 preguntas cortas.», «Prefiero esperar» y «Empezar el test»
    (decisión 1).
  - El código del authenticator se envía solo al completar las seis casillas (decisión 5).
  - «Soy nuevo» usa blanco al 14 % sobre el naranja (decisión 3), la pista de los campos usa
    `#8A94A6` y el foco usa `#FF6600` (RF-BIEN-14).
  - Ulises llama «Valeria» a la alumna (decisión 4).
  - E2 no trae «Soy nuevo», N2, N4 y N5 no traen «Volver» ni «Ya tengo cuenta», y no hay turno de
    error, de `incierto` ni de sesión expirada.
  - El duelo no trae «Me gustan las dos» ni «Ninguna me llama», y el resultado dice «Elegir
    Software como principal», sin «Rehacer el test», los electivos ni «También te puede
    interesar». Manda la spec del test (sus decisiones abiertas 3 y 4).
  - Las líneas de Ulises dentro del test, como «Primera práctica y te dejan escoger. ¿Cuál te
    pides?» o «¡Craa! Lo tuyo es esto, Valeria 👇», son ilustrativas. Mandan las del contenido
    (decisión abierta 8 de la spec del test).
  - El marcador «12 preguntas después» es un atajo de la maqueta y no existe en la app.
  - Los campos, las píldoras y los enlaces miden menos de 48 dp.
  - La franja mide 100 px y la cabecera 96 px. En la app miden lo mismo (RF-BIEN-4).

Sin prueba automática, porque es documentación.

## Textos nuevos

Los textos de Ulises y de los botones de la bienvenida salen de la maqueta. Los del registro, los
del login y los de los errores son los de hoy, y los del test son los de su spec y del contenido.

- **Recibimiento.** «¡Craa! Hola, soy Ulises 👋», «¿Ya usas ULima++?», «Sí, entrar» y «Soy
  nuevo».
- **Sí, entrar.** «¡Qué bueno verte! ¿Cuál es tu código o usuario?», «o», «Continuar con Google»,
  «Y tu contraseña de ULima++.», «Contraseña lista», «¡Hola de nuevo! Te llevo a tu horario 🪶» y
  «¡Hola de nuevo!».
- **Soy nuevo.** «¡Genial! Tu cuenta se crea aquí mismo.», «¿Cuál es tu código de alumno?»,
  «Código de alumno», «Ahora elige la contraseña con la que entrarás a ULima++. No es la de
  miUlima.», «Contraseña de ULima++ lista», «Para traer tus cursos entro a miUlima una sola vez.
  Antes, lee esto 👇», «Tu contraseña de miUlima, la del portal.», «Contraseña de miUlima lista»,
  «Último paso. El código de tu authenticator.» y «Código del authenticator listo».
- **Envío.** «Estoy creando tu cuenta y trayendo tu ciclo. Tarda cerca de un minuto.», «No cierres
  la app mientras tanto.», «Creando tu cuenta…», «Cuenta creada», «¡Craa! Tu cuenta ya está
  lista.», «Traje tus N cursos del ciclo.», «Traje tu curso del ciclo.», «No pudimos confirmar si
  tu cuenta se creó.» y «Tu cuenta ya está creada.».
- **Test.** «¿Empezamos tu test de especialidad? Son T preguntas cortas.», «Esto o aquello · N de
  T», «Escala de gusto · N de T» y «¡Listo! Te llevo a tu horario 🪶».
- **Sesión.** «Tu sesión caducó o iniciaste sesión en otro dispositivo.», que hoy es el texto del
  aviso «Sesión expirada».
- **Semántica.** «Tú, <texto>», «Enviar», «Mostrar contraseña» y «Ocultar contraseña».

Salen de la app «¿No tienes cuenta? Créala», «O inicia sesión con» y el «Google» del botón de
Android e iOS. De la pantalla del registro salen sus títulos y bajadas, que son «Crea tu cuenta
de ULima++», «Elige la contraseña con la que entrarás al app. No es la de miUlima.»,
«Verificamos que eres alumno», «Entramos a miUlima con tus datos una sola vez, para traer tus
cursos y tu avance. No los guardamos.», el título «Creando tu cuenta…» con su bajada «Estamos
entrando a miUlima y trayendo tus cursos, tu horario y tu avance. Puede tomar un par de minutos:
no cierres la app.», «Listo, <nombre>», «Listo, ya tienes cuenta», las filas del resumen y sus
botones «Continuar» y «Entrar». «Creando tu cuenta…» sigue como texto de la píldora.

## Contrato que se consume

Ninguno nuevo con las opciones por defecto.

- `POST /auth/login` y `POST /auth/google` para «Sí, entrar», como hoy.
- `POST /auth/register` para el registro, y después `GET /academic-profile/careers` y
  `GET /academic-profile/specialties` dentro de `adoptarSesion`, como hoy.
- `GET /specialty-test/content`, `POST /specialty-test/me/evaluate` y
  `PUT /academic-profile/me/specialties` para el test, como en su spec.
- Las rutas de `/password-reset/**` siguen en sus pantallas de hoy (decisión 9).

Con la alternativa de la decisión 1, el test necesita el contenido antes de que exista el token,
lo que cambia RS-BE-38 del backend y `docs/specs/api-contracts.md` («Decisiones»).

## Pantallas y archivos

### Se crean

| Archivo | Qué tiene |
| --- | --- |
| `lib/pages/bienvenida/bienvenida_page.dart` | La página de `/login` con el recibimiento, la franja, la conversación y el compositor |
| `lib/pages/bienvenida/bienvenida_controller.dart` | El recorrido, los turnos, el historial, el motivo de la llegada, los tramos del login, del registro y del test y el paso al horario |
| `lib/pages/bienvenida/widgets/**` | El recibimiento, el sello, las burbujas, el compositor, el vuelo de Ulises y el paso al horario |
| `lib/domain/bienvenida/bienvenida_turnos.dart` | Funciones puras de los turnos, el turno de cada error, el atrás, el conteo de cursos, la fórmula del pulso y del latido y la regla «Si no cabe» (decisión 26) |
| `test/bienvenida/*.dart` | Las pruebas de «Pruebas por requisito» |

### Cambian

| Archivo | Qué cambia |
| --- | --- |
| `lib/main.dart` | `/login` muestra la bienvenida y sale `/registro` |
| `lib/pages/login/login_binding.dart` | Registra también el controlador de la bienvenida, permanente, y lo reinicia después del cuadro |
| `lib/pages/login/login_controller.dart` | Deja de navegar y devuelve el resultado a la bienvenida |
| `lib/pages/registro/registro_controller.dart` | Suma un cierre propio que borra y descarta sus cinco campos, para que la bienvenida lo cierre sin GetX. Sus reglas no cambian |
| `lib/services/session_navigation.dart` | `offAllToLogin` suma el parámetro `motivo` |
| `lib/services/api_client.dart` | El interceptor del 401 pasa `motivo: expirada` |
| `lib/pages/password_reset/reset_password_controller.dart` | Pasa `motivo: restablecida` |
| `lib/components/google_sign_in_button_web.dart` | `renderButton` con `GSIButtonConfiguration` |
| `lib/components/chatbot_bubble.dart` | Informa su lugar y queda oculta hasta que Ulises aterriza (decisión 16) |
| `lib/configs/themes.dart` | Los tokens de RF-BIEN-14 |
| `lib/pages/specialty_test/**` | Las piezas del duelo, la escala, la espera y el resultado se pueden dibujar dentro del compositor y de la conversación (enmienda propuesta a la spec del test) |
| `README.md` | Las secciones del login, del registro y de la ruta post-login |
| `test/HU01_jeff/**`, `test/HU33_jeff/**` y `test/HU34_jeff/registro_consent_test.dart` | Pasan a montar la bienvenida donde montaban la tarjeta del login o la pantalla del registro |

### Salen

| Archivo | Por qué |
| --- | --- |
| `lib/pages/login/login_page.dart` | La bienvenida reemplaza a la tarjeta |
| `lib/pages/registro/registro_page.dart` y `lib/pages/registro/registro_binding.dart` | El registro corre dentro de la conversación (decisión 23) |
| `test/HU33_jeff/registro_page_test.dart` | Sus casos pasan a `bienvenida_registro_test.dart` |

### No cambian

| Archivo | Por qué |
| --- | --- |
| `lib/services/auth_service.dart` | `login`, `loginWithGoogle`, `finishGoogleLogin`, `adoptarSesion` y `logout` siguen igual, y la bienvenida atrapa el fallo de red que `login` no atrapa |
| `lib/services/registro_service.dart` | El plazo de 120 s y los mensajes siguen igual |
| `lib/components/portal_consent/portal_consent_view.dart` | La bienvenida usa sus constantes, y Portal Sync sigue usando la pantalla |
| `lib/services/post_login_route.dart` | Sigue decidiendo entre `/home` y `/setup-carrera` |
| `lib/pages/password_reset/**`, salvo el controlador del restablecimiento | Sus pantallas siguen (decisión 9) |
| `test/HU02_jeff/session_navigation_guard_test.dart` | Sigue prohibiendo navegar a `/login` fuera de `session_navigation.dart` |

## Cambios en otras specs

- **Auth.** Enmienda en `specs/features/auth/auth.spec.md`, pendiente de aprobación con esta
  spec. El formulario pasa a los turnos E1 y E2, `LoginController` deja de navegar, el fallo de
  red deja de colgar el botón, la tarjeta sale, el botón de Google de Android e iOS dice
  «Continuar con Google», el de web se configura con `continueWith` y `/login` recibe el motivo de
  la llegada. BR-AUTH-F-01 a BR-AUTH-F-10 siguen en todo lo demás.
- **Registro.** Enmienda en `specs/features/registro/registro.spec.md`, pendiente de aprobación
  con esta spec. RS-FE-1 a RS-FE-6 y BR-REG-F-01 a BR-REG-F-11 siguen, aplicadas a los turnos de
  la conversación. Salen la ruta `/registro`, la pantalla de seis estados y su botón «Entrar»,
  y `listo` pasa directo al test.
- **Test de especialidad (enmienda propuesta a una spec aprobada).** La spec vive en
  `feat/test-especialidad-fe`, aprobada el 2026-09-25 y sin implementar. Si el dueño aprueba esta
  spec, esa rama suma la enmienda con estos puntos, que se escriben allí como «pendiente de
  aprobación» hasta que el dueño la confirme.
  - **RF-TEST-1.** Suma un origen `bienvenida`. El alumno que crea su cuenta en la conversación
    hace el test en ella, sin la ruta `/test-especialidad`, sin el paso de carrera y sin
    `/setup-carrera`. El asistente sigue para el alumno con sesión y la configuración a medias
    que abre la app o entra con su código (decisión 10), y el Perfil sigue abriendo la ruta con
    `origen: perfil`.
  - **RF-TEST-2.** Con origen `bienvenida`, el contenido se pide una vez en T0 y no hay precarga.
    Las respuestas siguen solo en memoria.
  - **RF-TEST-3.** Con origen `bienvenida` no hay pantalla de bienvenida del test. Su papel lo
    toma T0, con «¿Empezamos tu test de especialidad? Son T preguntas cortas.», «Empezar el test» y
    «Saltar y elegir por mi cuenta», y sus estados de carga, error y no disponible pasan a
    burbujas de Ulises (RF-BIEN-10). No hay «Seguir el test» ni «Empezar de nuevo», porque no hay
    pausa.
  - **RF-TEST-4.** Con origen `bienvenida` no hay barra de 52 px, plumas, historial plegado ni
    pausa. La franja con el sello hace de cabecera, el contador va en el rótulo del compositor,
    «Pregunta anterior» es un enlace del compositor y la conversación entera es el historial. Las
    reglas de las líneas de Ulises, del sello de bloque y del atrás no cambian.
  - **RF-TEST-5 y RF-TEST-6.** El duelo y la escala se dibujan también en el compositor, con las
    tarjetas compactas de la maqueta (decisión 13) y la tarea de la escala en la burbuja de
    Ulises.
  - **RF-TEST-8.** Con origen `bienvenida`, el resultado va dentro de la conversación, que
    desplaza, y la regla «sin scroll» no aplica (decisión 15). El atrás del sistema no hace nada,
    como en el asistente.
  - **RF-TEST-9.** Con origen `bienvenida`, «Elegir como principal» y «Decidir después» terminan
    con la despedida y el paso al horario de RF-BIEN-11, en lugar de `Get.offAllNamed('/home')`.
  - **RF-TEST-11.** Con origen `bienvenida`, los textos de la tabla son burbujas de Ulises, y la
    fila del 401 sigue RF-BIEN-12, porque en `/login` el interceptor no navega.
  - **RF-TEST-13.** Con origen `bienvenida`, la burbuja de Ulises no es región viva y el foco del
    lector pasa a la primera burbuja nueva (RF-BIEN-16).
  - **«Textos nuevos» y «Pantallas y archivos».** Suman el origen `bienvenida` y los widgets que
    se dibujan en el compositor.
- **Splash.** RF-SPL-21 ya tiene su spec. La bienvenida recibe la pose, avisa al pintar su primer
  cuadro, declara su barra de estado y arranca sin pose (RF-BIEN-2, RF-BIEN-3 y RF-BIEN-17). La
  decisión 16 de esta spec y la 28 del splash deciden juntas cómo aparece Ulises en `/home`, y la
  decisión 10 de esta spec y la 29 del splash, qué pasa con la configuración a medias. El paso al
  horario usa la capa de la intro (RF-SPL-4) y su manera de medir la cabecera (RF-SPL-11).
- **App shell.** La estrella de BR-SHELL-F-04 es el destino del sello en el paso al horario, y la
  pestaña Horario la abre el argumento de BR-SHELL-F-02 enmendado. No cambia nada más.
- **Récord académico.** RF-REC-6 habla de una sola pantalla de consentimiento. En la
  conversación, el consentimiento es una tarjeta con los mismos textos y los botones «Acepto» y
  «Volver» (RF-BIEN-7). La nota se suma a esa spec cuando el dueño apruebe esta.
- **Perfil académico.** El alumno nuevo ya no pasa por el asistente de carrera, salvo que cierre la
  app antes de guardar su especialidad. La nota se suma a esa spec cuando el dueño apruebe esta.
- **Chatbot.** `ChatbotBubble` informa su lugar y espera a Ulises (decisión 16). La nota se suma a
  esa spec cuando el dueño apruebe esta.
- **Maquetas de `docs/images/UI`.** `InicioSesion.png` queda superada por la bienvenida. `AGENTS.md`
  pide respetar esas maquetas salvo un cambio aprobado, así que la aprobación de esta spec es ese
  cambio. La imagen no se toca.
- **Índice.** `docs/specs/feature-index.md` suma la fila 22 de esta spec y anota las enmiendas en
  las filas de Auth, Registro y Splash.

## Qué NO entra

- Endpoints nuevos o cambios en el backend, con las opciones por defecto.
- Arreglar que `POST /auth/register` distinga por sí mismo si un código tiene cuenta, que es de la
  spec del backend (RF-BIEN-9).
- Recuperar la contraseña dentro de la conversación, salvo con la alternativa de la decisión 9.
- Guardar la conversación, retomarla en otro arranque o recordar qué rama eligió el teléfono.
- Ulises con IA. Sus líneas son textos fijos de esta spec y del contenido del test, y la
  bienvenida no llama al servicio del chatbot.
- Cambiar el asistente de `/setup-carrera` o la ruta del test para las demás llegadas.
- Pasar lo escrito de una rama a la otra.
- Vibración nueva fuera de la del test.
- Sonido.
- Desplegar la app en web.
- Las alternativas de «Decisiones», mientras el dueño no las elija.

## Decisiones

Ninguna está aprobada. El dueño confirma o cambia cada una al aprobar la spec.

### Pedidos del dueño del 2026-09-25

La spec recoge estos pedidos del dueño. El texto que los describe sigue pendiente de su
aprobación, igual que el resto.

- Tras la intro al azar del splash, la estrella grande con sus «++» queda en el centro, entera y
  sin nada encima, y Ulises entra volando y aterriza a su lado (RF-BIEN-2).
- Ulises saluda con «¿Ya usas ULima++?» y dos botones grandes, «Sí, entrar» y «Soy nuevo», y al
  responder la estrella sube al sello junto a «ULIMA++» y sigue una conversación (RF-BIEN-2,
  RF-BIEN-4 y RF-BIEN-5).
- El que vuelve inicia sesión dentro de la conversación, con su código, su contraseña, «¿Olvidaste
  tu contraseña?» y «Continuar con Google» con el logo oficial de colores, y va a su horario
  (RF-BIEN-6 y RF-BIEN-11).
- El nuevo crea su cuenta dentro de la conversación con el registro que ya existe y, sin cortar la
  conversación, sigue con el test de especialidad con Ulises hasta su horario (RF-BIEN-7,
  RF-BIEN-8, RF-BIEN-10 y RF-BIEN-11).
- El sello late con cada respuesta y un pulso recorre los rombos mientras se crea la cuenta
  (RF-BIEN-4).
- «Soy nuevo» y «Ya tengo cuenta» quedan siempre visibles, para no revelar qué códigos tienen
  cuenta (RF-BIEN-9).
- El logo ULima++ con sus «++» no se pierde en ningún momento (RF-BIEN-4).

### Para el dueño

Cambian lo que ve el alumno. La columna «Qué ve el alumno» describe la opción por defecto.

| # | Decisión | Opción por defecto | Qué ve el alumno | Alternativa | Dónde queda |
| --- | --- | --- | --- | --- | --- |
| 1 | Cuándo empieza el test del alumno nuevo | Cuando la cuenta ya está creada, porque el contenido del test exige el token (RS-BE-38 del backend) | Mientras se crea la cuenta ve a Ulises, la píldora y el pulso del sello, cerca de un minuto, y después Ulises le ofrece el test | Como en la maqueta, el test empieza mientras se crea la cuenta, con «Mientras tanto, ¿empezamos…?», «Prefiero esperar» y «Empezar el test». Pide que el backend sirva el contenido sin token, sin `specialtyId`, lo que enmienda RS-BE-38 y el contrato, y que la conversación interrumpa el test si el registro falla, por ejemplo con un código del authenticator vencido, o lo descarte con `NOT_ENROLLED` | RF-BIEN-8 y RF-BIEN-10 |
| 2 | Cuándo aparecen los dos botones | Como en la maqueta, después de que Ulises aterriza, a los 2,3 s del relevo | Ve el vuelo completo y los botones de 3,5 a 3,7 s después de abrir la app | Los botones aparecen con el relevo, mientras Ulises todavía vuela | RF-BIEN-2 |
| 3 | «Soy nuevo» en claro | Relleno `#B84A00` con borde y texto blancos, 5,23:1 | Un botón naranja más oscuro que el fondo, que se lee bien | El blanco al 14 % de la maqueta, con 2,59:1, que no llega al 4,5:1 | RF-BIEN-14 |
| 4 | El nombre en las líneas de Ulises | Sin nombre, porque el backend lo manda como «APELLIDOS NOMBRES» y la app no sabe cuál es el de pila | «¡Craa! Tu cuenta ya está lista.» y «¡Hola de nuevo!» | El nombre de pila supuesto como las palabras después de las dos primeras, que falla con un solo apellido o con apellidos compuestos | RF-BIEN-6 y RF-BIEN-8 |
| 5 | Enviar el código del authenticator | Con el botón «Crear mi cuenta», como hoy | Escribe los seis dígitos y toca el botón | Se envía solo al completar las seis casillas, como en la maqueta, lo que deja fuera los códigos de 8 dígitos y gasta un intento con cada error de tipeo | RF-BIEN-7 |
| 6 | Qué pasa tras un login rechazado | Ulises dice el error y vuelve a pedir el código, ya escrito, con la contraseña vacía | Puede corregir el código o la contraseña | Se queda en el turno de la contraseña con el error debajo y la contraseña escrita, como hoy la tarjeta | RF-BIEN-6 y RF-BIEN-12 |
| 7 | Llegar después de cerrar sesión | El recibimiento corto, con el logo en el centro, el vuelo de Ulises y la pregunta | Tras cerrar sesión, Ulises lo vuelve a recibir, porque el teléfono puede cambiar de manos | La conversación directa, con la pregunta como respuestas rápidas y sin el vuelo | RF-BIEN-3 |
| 8 | Llegar por sesión expirada o contraseña restablecida | Directo a «¿Cuál es tu código o usuario?», con «Soy nuevo» a la vista | Escribe su código sin volver a responder la pregunta | Igual que tras cerrar sesión | RF-BIEN-3 |
| 9 | «¿Olvidaste tu contraseña?» | Las pantallas de hoy, encima de la bienvenida | Sale de la conversación mientras restablece su contraseña y el logo deja de verse | Dentro de la conversación, con los textos de hoy, pedir el código, escribirlo, elegir la contraseña nueva y entrar | RF-BIEN-6 |
| 10 | Alumno con sesión y la configuración a medias | Va a `/setup-carrera`, como hoy, al abrir la app o al entrar con su código | Ve el asistente de carrera y el logo se desvanece, igual que en la decisión 29 del splash | La bienvenida retoma la conversación en T0 y termina en el horario, con el logo en el sello | RF-BIEN-6 y RF-BIEN-13 |
| 11 | El paso de carrera en la conversación | No aparece, porque hay una sola carrera y sale del usuario | Pasa de la cuenta creada a la invitación al test | Ulises dice la carrera en una burbuja antes de la invitación | RF-BIEN-10 |
| 12 | Las líneas de bienvenida del contenido del test | No aparecen, porque Ulises ya se presentó | «¿Empezamos tu test de especialidad? Son T preguntas cortas.» | Las líneas `welcome` antes de la invitación, aunque repitan «Soy Ulises» | RF-BIEN-10 |
| 13 | Las tarjetas del duelo en la conversación | Las compactas de la maqueta, de 56 dp con la baldosa de 40 dp | El duelo cabe en el compositor con la pregunta a la vista | Las de RF-TEST-5, de 104 dp con la baldosa de 80 dp, que obligan a desplazar el compositor | RF-BIEN-10 |
| 14 | Salir del test a mitad | Sin pausa ni salto dentro de las preguntas | Termina el test o cierra la app, y al volver entra al asistente (decisión 10) | «Saltar y elegir por mi cuenta» también en cada pregunta | RF-BIEN-10 |
| 15 | El resultado en la conversación | Dentro de la conversación, que desplaza | Ve el resultado debajo de la última respuesta y desplaza para ver todo | Una hoja sobre la conversación, que cumple el «sin scroll» de RF-TEST-8 | RF-BIEN-10 |
| 16 | Ulises al llegar al horario | Vuela a su burbuja, como en la maqueta, lo que cambia `chatbot_bubble.dart` | Ulises se mueve de la conversación a su esquina | Se desvanece y su burbuja aparece con la página, como la opción por defecto de la decisión 28 del splash | RF-BIEN-11 |
| 17 | Aviso de no cerrar la app mientras se crea la cuenta | Una segunda burbuja, «No cierres la app mientras tanto.» | Sabe que no debe salir, como hoy en la pantalla del registro | Solo la línea de la maqueta, y el aviso aparece si intenta salir | RF-BIEN-8 |

### Técnicas (las propone el equipo)

No cambian lo que ve el alumno, salvo donde la columna lo dice.

| # | Decisión | Propuesta del equipo | Alternativa | Qué ve el alumno | Dónde queda |
| --- | --- | --- | --- | --- | --- |
| 18 | Dónde vive la conversación | Una sola ruta, `/login`, con los tramos del login, del registro y del test dentro | Las rutas `/login`, `/registro` y `/test-especialidad` con un andamio común y sin transición, con el historial pasado como argumento y el envío del registro sobreviviendo al cambio de ruta | Nada distinto | RF-BIEN-1 |
| 19 | Vida del controlador de la bienvenida | Permanente, como `LoginController`, y reiniciado después del cuadro al volver a entrar | Uno por visita con `lazyPut`, que expone de nuevo el «tipeo fantasma» si dos `/login` conviven | Nada distinto | RF-BIEN-1 |
| 20 | Vida del controlador del registro | La bienvenida lo crea y lo cierra ella misma, sin `Get.put` | `Get.put` con una etiqueta y `Get.delete` al cerrar, con el riesgo de atarlo a la ruta de un aviso | Nada distinto | RF-BIEN-9 |
| 21 | Cómo sabe la bienvenida por qué llega | El parámetro `motivo` de `offAllToLogin`, como argumento de ruta | Un campo en un service que la bienvenida lee y borra | Nada distinto | RF-BIEN-1 |
| 22 | El 401 dentro de la conversación | Comprobar el token guardado tras cada fallo de un turno con sesión | Un aviso desde el interceptor de `ApiClient` a la bienvenida | Nada distinto | RF-BIEN-12 |
| 23 | La ruta `/registro` | Sale con `RegistroPage` y `RegistroBinding` | Se queda sin enlaces que la abran | Nada distinto | RF-BIEN-1 |
| 24 | Los colores | Los tokens del test y los nuevos de RF-BIEN-14 | Tokens propios para todo | Nada distinto | RF-BIEN-14 |
| 25 | Web | La bienvenida también en web, con el botón oficial de GIS configurado con `continueWith`, `es` y el tema del sistema | La tarjeta de hoy en web | En web, la conversación en lugar de la tarjeta. Web no se despliega (`README.md:701`) | RF-BIEN-1 y RF-BIEN-6 |
| 26 | Dónde va la lógica pura | `lib/domain/bienvenida/`, como la del truco del 67 | Dentro de `lib/pages/bienvenida/` | Nada distinto | «Pantallas y archivos» |

## Pruebas por requisito

Todas se crean con la implementación y hoy no existen. Las de widget usan dobles escritos a mano,
un `ApiClient` falso y datos inventados, con el alumno de prueba 20230001.

| Requisito | Pruebas | Qué fijan |
| --- | --- | --- |
| RF-BIEN-1 | `bienvenida_ruta_test.dart` | `/login` muestra la bienvenida; `LoginController` y la bienvenida permanentes y reiniciados al volver; la navegación en la bienvenida y no en `LoginController`; sin `/registro`; el motivo de cada llegada; la guarda de `session_navigation_guard_test.dart` en verde |
| RF-BIEN-2 | `bienvenida_recibimiento_test.dart` | El primer cuadro idéntico a la pose recibida, en claro y en oscuro; el aviso a la capa; los tiempos de la tarjeta y de los botones; los toques ignorados antes; nada dentro del margen de la estrella a 375 × 667 con 1,0, 1,3 y 2,0; la subida de la estrella cuando no cabe; el primer grupo con las dos burbujas y la respuesta |
| RF-BIEN-3 | `bienvenida_recibimiento_test.dart` | El recibimiento corto sin argumentos; directo a E1 con `expirada` y con `restablecida`; «Soy nuevo» a la vista; el sello entero desde el primer cuadro |
| RF-BIEN-4 | `bienvenida_sello_test.dart` | El sello a 1,22 veces la cabecera; el latido con cada respuesta y al posarse; el pulso solo durante el envío y su fórmula; la vuelta a la opacidad plena con cada desenlace; el encabezado «ULIMA++» |
| RF-BIEN-5 | `bienvenida_conversacion_test.dart` | Los grupos y las respuestas; el ritmo de 850 y 500 ms; el compositor y sus piezas; el botón de envío inactivo con el campo vacío; el historial sin secretos, borrado al reiniciar y al pasar al horario; el teclado |
| RF-BIEN-6 | `bienvenida_entrar_test.dart` | E1, E2 y E3 con sus textos; el usuario alfanumérico; el error que vuelve a E1; el fallo de red que no cuelga el botón; Google en Android e iOS con «Continuar con Google» y la cancelación; la configuración de GIS en web; «¿Olvidaste tu contraseña?»; «Soy nuevo» en E1 y E2; el destino según el rol y la configuración |
| RF-BIEN-7 y RF-BIEN-8 | `bienvenida_registro_test.dart` | N1 a N5 con sus textos; los validadores por turno sin red; la tarjeta del consentimiento literal; «Volver» y el consentimiento que no se repite; el envío solo con el botón; el plazo de 120 s; el `PopScope` y su aviso; cada código de error con su turno de destino y el código del authenticator borrado; `incierto` con sus dos títulos y salidas; el 201 con el conteo y los avisos; el paso al test |
| RF-BIEN-9 | `bienvenida_credenciales_test.dart` | Los cinco campos fuera de todo `Rx` y del historial; el cierre al tocar «Ya tengo cuenta», al pasar al test, al reiniciar y al retirar `/login`; el controlador creado sin `Get.put` con un aviso abierto; las dos contraseñas nunca a la vez; ningún pedido al backend antes del envío; «Soy nuevo» y «Ya tengo cuenta» fijos, también tras un login rechazado y tras `USER_NOT_FOUND` de Google |
| RF-BIEN-10 | `bienvenida_test_especialidad_test.dart` | T0 con T del contenido; la carga, el error y el `404`; las líneas de Ulises por pregunta; el duelo y la escala en el compositor; las respuestas del alumno; «Pregunta anterior»; la espera y el desempate; el resultado con sus tres botones; la despedida y el paso al horario; «Rehacer el test»; la selección manual; sin pausa; el docente sin test |
| RF-BIEN-11 | `bienvenida_horario_test.dart` | `Get.offAll` a `/home` con el argumento de Horario y sin transición; el historial y el registro cerrados antes; Ulises en la burbuja del alumno y desvanecido para el docente; la burbuja oculta hasta el aterrizaje; el fundido cuando algo no se mide; la orientación vertical hasta que la capa se retira |
| RF-BIEN-12 | `bienvenida_errores_test.dart` | Cada fila de la tabla; el 401 en un turno con sesión, con la limpieza local y la vuelta a E1 |
| RF-BIEN-13 | `bienvenida_atras_test.dart` | Cada fila de la tabla del atrás; el envío que no se abandona; la sesión guardada con la configuración a medias que abre `/setup-carrera` |
| RF-BIEN-14 | `bienvenida_contraste_test.dart` | Cada token en los dos temas; cada par de la tabla de contraste; el recibimiento oscuro |
| RF-BIEN-15 | `bienvenida_movimiento_test.dart` | Sin vuelo, estela, latido, pulso ni desplazamiento con reducir movimiento; los fundidos y sus tiempos; las pausas del ritmo que se quedan |
| RF-BIEN-16 | `bienvenida_accesibilidad_test.dart` | El encabezado, los grupos y «Tú, <texto>»; el recibimiento sin espera con lector de pantalla; las burbujas de un turno juntas y el foco en la primera; las regiones vivas; las etiquetas «Enviar», «Mostrar contraseña» y «Ocultar contraseña»; los blancos de 48 dp; el orden de foco con teclado físico; sin desborde con 1,0, 1,3 y 2,0 |
| RF-BIEN-17 | `bienvenida_barra_estado_test.dart` | Los íconos claros en los dos temas; la columna de 600 dp en una pantalla ancha |
| RF-BIEN-18 | Ninguna | La medición manual de «Verificación» |
| RF-BIEN-19 | Ninguna | Es documentación |

Además, siguen en verde y se ajustan a la bienvenida
`test/HU01_jeff/login_navigation_paths_test.dart` y `login_relogin_regression_test.dart`, que cubren
los caminos a `/login` y el «tipeo fantasma»; `test/HU33_jeff/registro_controller_test.dart`,
`registro_service_test.dart` y `api_client_401_test.dart`, que cubren las reglas del registro; y los
casos 10 a 12 de `test/HU34_jeff/registro_consent_test.dart`, que pasan a montar la conversación.

## Verificación

- Antes de aprobar, el dueño abre `docs/images/UI/bienvenida/ulises-te-recibe-combinada.html`
  para ver los recorridos «Soy nuevo» y «Ya tengo cuenta», en claro y en oscuro, con y sin reducir
  movimiento, y la lista de diferencias de su `README.md`.
- `dart format` sobre los archivos Dart que cambien.
- `flutter analyze --no-pub`.
- `flutter test --no-pub` con la suite completa, porque cambian `main.dart`,
  `session_navigation.dart`, `api_client.dart` y `LoginController`, que usan otras
  funcionalidades. Incluye `test/bienvenida`, `test/HU01_jeff`, `test/HU02_jeff`, `test/HU33_jeff`
  y `test/HU34_jeff`.
- La bienvenida no se publica antes que el splash ni que el test de especialidad, porque recibe la
  pose del primero (decisión 30 del splash) y dibuja las piezas del segundo, y cada push a `main`
  publica el APK (`.github/workflows/build-apk.yml`).
- Una revisión manual en un Android 12 a 14 con barra de tres botones, en un Android 15 o superior
  y en el iPhone SE del dueño, en claro y en oscuro, con los recorridos «Sí, entrar» con código y
  con Google, un docente, «Soy nuevo» hasta el horario, un error de cada tramo y el modo avión
  durante el envío. La misma revisión con TalkBack, con VoiceOver, con el texto al 200 %, con un
  teclado físico y con reducir movimiento. Comprueba además que el llavero de iOS y el gestor de
  contraseñas de Google ofrecen la contraseña guardada en E2, aunque el código vaya en E1.
- Una grabación de pantalla a 60 fps, revisada cuadro a cuadro, comprueba que el logo no salta en
  el relevo del splash, que nada tapa la estrella mientras Ulises aterriza y que el paso al
  horario termina sin cambio al retirarse la capa.
- Un registro real contra el backend desplegado, con una cuenta que el dueño elija y que no esté
  en la base, hasta el horario. Lo hace el dueño con sus datos, que nunca entran al repo.
- La medición de RF-BIEN-18 en modo perfil, con tres recorridos por tramo.
