---
name: Splash animado
description: Splash nativo que no corta el logo y una intro animada en Flutter con tres variantes al azar, Ensamble, Incremento y Código, que corre mientras carga la app y termina en su pantalla de destino
targets:
  - ../../../lib/main.dart
  - ../../../lib/pages/splash/**
  - ../../../lib/components/logo/**
  - ../../../lib/services/splash_variante_service.dart
  - ../../../lib/services/session_navigation.dart
  - ../../../lib/components/header/app_header.dart
  - ../../../lib/pages/login/login_page.dart
  - ../../../lib/pages/setup_carrera/setup_carrera_page.dart
  - ../../../pubspec.yaml
  - ../../../assets/splash/**
  - ../../../android/app/src/main/res/drawable*/**
  - ../../../android/app/src/main/res/values*/styles.xml
  - ../../../ios/Runner/Assets.xcassets/LaunchImage.imageset/**
  - ../../../ios/Runner/Assets.xcassets/LaunchBackground.imageset/**
  - ../../../ios/Runner/Base.lproj/LaunchScreen.storyboard
  - ../../../ios/Runner/Info.plist
  - ../../../web/index.html
  - ../../../web/splash/**
  - ../../../test/splash/**
  - ../../../test/components/header/app_header_test.dart
  - ../../../docs/images/UI/splash/**
  - ../../../README.md
---

# Splash animado

> Estado. **Diseñada el 2026-09-25, corregida el mismo día con los hallazgos de dos revisiones y
> pendiente de la aprobación del dueño antes de implementar.**
> Nada de esta spec está aprobado. «Decisiones» reúne cada punto que el dueño confirma o cambia,
> con la opción que la spec toma por defecto, en dos tablas. La primera reúne las que cambian lo
> que ve el alumno, que decide el dueño, y la segunda las técnicas, que propone el equipo.
> El pedido del dueño del 2026-09-25 es reparar el splash de Android, que corta el logo, y
> volverlo animado e innovador con el logo y los «++». Se le muestran tres conceptos animados y
> responde que le gustan todos y que quiere «que se puedan randomizar siempre que la app se
> abra». Los tres son A «Ensamble», B «Incremento» y C «Código», y sus maquetas quedan en
> `docs/images/UI/splash/` (RF-SPL-19).
> La spec es propia y no una sección de `specs/features/app-shell/app-shell.spec.md`, porque el
> splash corre antes de la sesión y toca los recursos nativos, `pubspec.yaml` y el arranque de
> `main.dart`, mientras app-shell cubre el shell autenticado. Es el mismo reparto de la spec del
> chat, que vive aparte y suma a app-shell solo lo que cambia en la cabecera. Aquí ese cambio es
> BR-SHELL-F-04, la estrella junto a «ULIMA++» («Cambios en otras specs»).
> Las referencias `archivo:línea` apuntan a `41ff0a6`, la base de la rama `feat/splash-animado`.
> Las que nombran un paquete apuntan a la versión que fija `pubspec.lock`, como get 4.7.3, y las
> del engine o de flutter_tools, al SDK de Flutter 3.47.2 instalado en la Mac del equipo.
> Los `[@test]` apuntan a pruebas que todavía no existen. Cada uno lleva «(pendiente)», nombra
> la prueba que fija el requisito y se escribe con la implementación.
> Donde esta spec y las maquetas difieren, manda la spec, y `docs/images/UI/splash/README.md` lo
> dice junto a ellas. Difieren en el arranque de Ensamble (RF-SPL-7), que ya muestra
> `ensamble-adaptada.html`, en el tamaño único de la estrella del primer cuadro (RF-SPL-1) y en la
> geometría única del logo (RF-SPL-2). También difieren en el destello de Ensamble, sin
> desenfoque (RF-SPL-7), en la página de destino, que aparece entera y no por tarjetas
> escalonadas (RF-SPL-11), en el radio y la letra de Código (RF-SPL-9) y en la salida de
> Incremento, que no espera el fin de un tic (RF-SPL-10).

## User Stories

- Como alumno o docente, quiero ver el logo completo al abrir la app, sin puntas ni «++»
  cortados y sin un cuadrado de otro naranja detrás.
- Como alumno, quiero que el arranque se sienta vivo y distinto de una vez a otra, con una
  animación que no dure más de 1,8 s.
- Como persona que usa «reducir movimiento» o un lector de pantalla, quiero un arranque
  tranquilo que se anuncie una sola vez.

## Contexto

El diagnóstico del 2026-09-25 sobre `41ff0a6` es lo que motiva la spec.

- **El recorte.** `flutter_native_splash` usa `assets/images/UL_fondo_naranja_grande.png`, el
  ícono de la app de 1539 px, como `image` y como `android_12.image` (`pubspec.yaml:79-84`).
  Android 12 o superior muestra el ícono del splash en un lienzo de 288 dp y lo enmascara a un
  círculo de 192 dp de diámetro, es decir, de radio 1/3 del lado. En ese PNG los «++» llegan a
  0,47 del lado desde el centro y las puntas de la estrella a 0,37, así que el círculo corta las
  dos cosas. La captura recortada de `docs/images/UI/splash/splash-actual-recorte.jpg` lo muestra.
- **El cuadrado.** El fondo del ícono tiene textura y varía alrededor de `#E77330` (entre
  `#E4722F` y `#E77433` en una muestra de puntos), mientras el fondo del splash es `#E77330`
  plano, y el borde del ícono se nota. En Android anterior a 12 y en iOS el mismo PNG entra como
  imagen 4x y mide 385 dp, o 385 pt en iOS, más que el ancho de un teléfono de 360 dp o de un
  iPhone SE de 375 pt.
- **El arranque.** `main()` espera la orientación (`main.dart:60-62`), Firebase (`:63`),
  `StorageService` (`:67-70`), el registro de servicios (`:71-81`), `tryRestoreSession`, que
  llama a la red (`:84`), y `fetchAlerts` para alumnos, que también llama a la red (`:91-97`).
  Solo después llama a `runApp` (`:102`). Mientras tanto, el splash nativo queda quieto.
- **Las alertas se piden dos veces.** `HomeController.onInit` ya llama a `fetchAlerts` al
  montarse (`home_controller.dart:38-44`), y la campana se actualiza sola cuando llegan
  (`app_header.dart:94-98`).
- **Sin red.** `tryRestoreSession` atrapa cualquier error de `GET /auth/me` y de lo que carga
  después, también uno de red, borra la sesión y devuelve `false` (`auth_service.dart:196-215`),
  así que un arranque sin red termina hoy en `/login` y sin sesión guardada. La lectura del token
  en flutter_secure_storage va antes del `try` (`:193`), así que un error del almacén de claves
  no se atrapa y hoy deja la app sin `runApp`. Esta spec no cambia cómo se restaura la sesión
  («Qué NO entra»).
- **El 401 en el arranque.** Un 401 de esas llamadas borra la sesión en `ApiClient` y llama a
  `offAllToLogin` (`api_client.dart:143-160`), que hoy no navega porque `Get.context` es null
  antes de `runApp` (`session_navigation.dart:32-38`). Por eso hoy no hay snackbar «Sesión
  expirada» en el arranque y la ruta sale de `tryRestoreSession`.
- **La cabecera.** `AppHeader` muestra solo el texto «ULIMA++» (`app_header.dart:79-88`) y el
  `SvgPicture` de `logo.svg` está comentado (`:161-168`). Las tres maquetas terminan con la
  estrella junto a «ULIMA++».
- **La barra de estado.** Ningún archivo de `lib/` fija un `SystemUiOverlayStyle`, y Flutter
  conserva el último estilo que se aplica aunque desaparezca la región que lo pide.
- **Los destinos.** `postLoginRoute` devuelve `/home` para docentes y para alumnos con la
  configuración completa, y `/setup-carrera` para los demás (`post_login_route.dart:11-14`); sin
  sesión, la ruta es `/login` (`main.dart:98-100`). Las tres `GetPage` usan la transición por
  defecto (`main.dart:129-172`).
  - `/home` usa `AppHeader`, con fondo `headerColor`, que es `#FF6600` en claro y
    `rgb(30, 30, 36)` en oscuro (`themes.dart:21-25`), y un borde inferior de 2 dp en
    `primaryContainer` (`app_header.dart:58-65`). El docente no tiene campana y ocupa su lugar un
    espacio de 30 dp (`:149-150`).
  - `/setup-carrera` no usa `AppHeader`. Su cabecera es `_WizardHeader`, `#FF6600` en los dos
    temas, dentro de un `SafeArea` y sobre un fondo `#F7F7F8` fijo
    (`setup_carrera_page.dart:20-25` y `:47-95`), así que la franja bajo la barra de estado es
    gris claro y la cabecera naranja empieza debajo.
  - `/login` no tiene cabecera. Es una página `#FF6600` con una tarjeta blanca en claro, y
    `#262626` con una tarjeta `#050505` en oscuro (`login_page.dart:464-465` y `:485-486`). La
    tarjeta lleva el ícono de la app en 96 dp con esquinas de 22 dp (`login_page.dart:80-88`).

## Requisitos

Dos medidas se repiten. **u** es la unidad de `assets/images/Universidad_de_Lima_logo.svg`, cuya
estrella tiene centro (590,2; 394,3) y radio nominal de 354,8 u hasta la punta. **R** es ese radio
en el primer cuadro, 90 dp, así que una unidad mide R/354,8 dp. Los tiempos se cuentan desde que
la intro empieza a moverse (RF-SPL-6).

### RF-SPL-1. El splash nativo no corta el logo

- Un solo splash nativo para las tres variantes, porque el nativo es una imagen estática que
  queda definida al compilar. Muestra la estrella completa, blanca y sin «++», centrada, sobre
  `#E77330` plano de borde a borde (decisión 1).
- La imagen es `assets/splash/splash_estrella.png`, de 1152 × 1152 px, con fondo transparente y la
  estrella dibujada desde la geometría de RF-SPL-2 con R = 360 px. Como `flutter_native_splash`
  la toma como 4x, mide 288 dp y la estrella llega a R = 90 dp. Con el retraimiento de la
  rendija, las puntas quedan a 88,5 dp del centro, dentro del círculo de 96 dp de radio que
  Android 12 o superior deja ver.
- `pubspec.yaml` apunta `image` y `android_12.image` a esa imagen y deja `color` y
  `android_12.color` en `#E77330`, sin `icon_background_color` ni variantes oscuras
  (decisión 2). El mismo PNG sirve en Android 12 o superior, en Android anterior, en iOS y en
  web, y en los temas claro y oscuro.
- `assets/splash/` no entra en los assets de Flutter (`pubspec.yaml:106-107` solo declara
  `assets/images/`), así que la imagen no se empaqueta dos veces.
- El ícono del launcher no cambia y sigue en `UL_fondo_naranja_grande.png`
  (`pubspec.yaml:68-74`), igual que el logo de la tarjeta del login.
- Los recursos nativos se regeneran con `dart run flutter_native_splash:create`.

`[@test] ../../../test/splash/splash_png_nativo_test.dart` (pendiente)

### RF-SPL-2. Una sola geometría del logo

- Un solo archivo Dart en `lib/components/logo/` guarda la geometría. La usan la intro, la
  estrella de la cabecera (BR-SHELL-F-04 de app-shell) y la generación del PNG (RF-SPL-3).
- Los ocho rombos son los polígonos de `Universidad_de_Lima_logo.svg` y la estrella central es el
  polígono de 16 vértices que forman sus vértices interiores. Cada polígono se retrae 3,5 u, lo
  que deja la rendija naranja de 7 u que tiene el ícono. Los polígonos retraídos son los de
  `docs/images/UI/splash/ensamble.html`.
- La silueta sin retraer, que es la unión de los polígonos originales del SVG, recorta el
  destello de Ensamble (RF-SPL-7).
- Cada «+» es una cruz de 72,8 u de punta a punta y 17,4 u de grosor, medida en el ícono. Sus
  centros están a (308,7; −133,8) u y (402,5; −133,8) u del centro de la estrella, arriba a la
  derecha, como en el ícono.
- Los caminos se construyen una sola vez y no en cada cuadro.

`[@test] ../../../test/splash/splash_geometria_test.dart` (pendiente)

### RF-SPL-3. Cómo se genera el PNG del splash

- El PNG lo escribe una prueba de golden que pinta la estrella con la geometría de RF-SPL-2 sobre
  un lienzo transparente de 1152 × 1152 px (decisión 16). Se genera con
  `flutter test --update-goldens test/splash/splash_png_nativo_test.dart` y después con
  `dart run flutter_native_splash:create`.
- La misma prueba, sin la bandera, comprueba que el PNG del repo coincide con la geometría, que
  mide 1152 × 1152 px, que sus esquinas son transparentes y que ningún píxel blanco queda a más de
  384 px del centro.
- La comparación con la geometría usa un comparador con la tolerancia de RF-SPL-5 y no la
  comparación exacta de `matchesGoldenFile`, porque el antialiasing cambia entre macOS y Linux.
  La CI de hoy (`.github/workflows/build-apk.yml`) no corre pruebas, así que la prueba corre en
  la Mac del equipo, igual que el resto de la suite.
- No se agrega ningún paquete ni herramienta fuera del SDK de Flutter.

`[@test] ../../../test/splash/splash_png_nativo_test.dart` (pendiente)

### RF-SPL-4. `runApp` inmediato y la carga en paralelo

- `main()` llama a `runApp` justo después de `WidgetsFlutterBinding.ensureInitialized` y del
  bloqueo en vertical, que hoy ya van primero (`main.dart:59-62`). En web no hay intro y `main()`
  conserva el orden de hoy (decisión 22), porque `WidgetsApp` usa la ruta de la URL antes que
  `initialRoute` y una recarga en `/#/home` construiría `HomePage`, con `AuthService.to` en sus
  campos, antes de que existan los servicios.
- La carga pasa a una función que devuelve la ruta de destino y corre en paralelo con la intro.
  Da los mismos pasos que hoy y en el mismo orden, con Firebase (`main.dart:63`), la línea de
  `LucideIcons` (`:64`), `StorageService` (`:67-70`), el registro de los servicios permanentes
  (`:71-81`), `tryRestoreSession` (`:84`) y la ruta de `postLoginRoute` o `/login`
  (`:85-100`). Solo cambian las alertas del punto siguiente.
- Por defecto, `fetchAlerts` sale de la carga (`main.dart:91-97`), porque `HomeController` ya
  la pide al montarse y la campana se actualiza sola (decisión 7).
- La intro recibe la carga inyectada, como una `Future<String> Function()`, igual que recibe el
  `Random` (RF-SPL-6). Así las pruebas la reemplazan sin llamar a `Firebase.initializeApp` ni a
  flutter_secure_storage.
- `GetMaterialApp` arranca en `/arranque`, una página vacía de color `#E77330`. Su `builder`
  pone la capa de la intro encima del `Navigator`.
- El estado de la capa vive en el `State` de su widget y no en un `GetxController` registrado
  con `Get.put` mientras la ruta actual es `/arranque`. GetX liga esa instancia a la ruta y la
  borra cuando la navegación retira `/arranque`, en plena salida (`get_instance.dart:199-210` y
  `router_report.dart` de get 4.7.3). Los servicios permanentes que registra la carga también
  quedan ligados a `/arranque`, y al retirarla GetX se niega a borrarlos y solo deja un aviso en
  el registro, que es esperado.
- Cuando terminan la entrada de la variante y la carga, la capa navega sin transición, espera el
  primer cuadro de la página ya montada debajo, mide los destinos (RF-SPL-11 y RF-SPL-12) y
  reproduce la salida. Al terminar, la capa se retira y la página queda tal cual.
- **Navegación sin transición.** En get 4.7.3, `Get.offAllNamed` no acepta transición
  (`extension_navigation.dart:778-792`), y como las `GetPage` de los tres destinos no fijan
  ninguna, correría la transición por defecto de 300 ms del `PageTransitionsTheme`
  (`get_transition_mixin.dart`, caso `default`), que en iOS es un deslizamiento lateral. En el
  primer cuadro la página estaría transformada y la capa mediría posiciones erradas. Por eso la
  intro navega con `Get.offAll`, con el `page` y el `binding` de la misma `GetPage` del destino,
  `routeName` igual a la ruta, `Transition.noTransition` y `opaque: true` (decisión 19). Las
  `GetPage` se declaran una sola vez en `main.dart` y la intro las toma de ahí, así que el binding
  no se duplica. `Get.currentRoute` queda en el nombre de la ruta, como hoy, y el login, el logout
  y el resto de la navegación conservan su transición.
- **`/login` siempre por `offAllToLogin`.** La intro navega a `/login` por `offAllToLogin` de
  `session_navigation.dart`, que suma la opción de navegar sin transición de la misma manera, y
  nunca con `Get.offAllNamed('/login')` directo, como pide ese archivo
  (`session_navigation.dart:4-19`).
- **Un 401 durante la carga.** Con `runApp` inmediato, `/arranque` ya está montada, así que un
  401 de `GET /auth/me` o de los catálogos dentro de `tryRestoreSession`, que no usa
  `suppressSessionExpiry` (`auth_service.dart:197` y `:430-446`), navegaría a `/login` bajo la
  capa y mostraría el snackbar «Sesión expirada», que seguiría visible tras la salida. Después la
  intro navegaría otra vez a `/login`, que es la doble ruta que prohíbe
  `session_navigation.dart:4-19`. Para que el arranque siga igual que hoy, `offAllToLogin` no
  navega y devuelve `false` mientras la ruta actual es `/arranque`, salvo cuando la llama la
  intro (decisión 20). Así el interceptor de `api_client.dart:143-160` borra la sesión como hoy,
  no muestra el snackbar, `tryRestoreSession` devuelve `false` y la intro navega una sola vez a
  `/login`.
- Si la ruta de debajo cambia durante la salida, por ejemplo por un 401 de las peticiones que la
  página de destino hace al montarse, la capa deja la salida y termina con el fundido de 300 ms
  de RF-SPL-11.
- Mientras la capa cubre la pantalla, ningún toque llega a la página de debajo.
- **La barra de estado.** Mientras la capa cubre la pantalla, la barra de estado usa íconos
  claros sobre el naranja. Como Flutter conserva el último estilo, cada destino declara el suyo
  con un `AnnotatedRegion<SystemUiOverlayStyle>` en su raíz, que rige desde que la capa se
  retira y también cuando se llega por otro camino. `AppHeader`, y con ella `/home`, y `/login`
  usan íconos claros en los dos temas. `/setup-carrera` usa íconos oscuros sobre su franja gris,
  o claros con la alternativa de la decisión 10. En la salida hacia `/setup-carrera` con la franja
  gris, la capa pasa a íconos oscuros cuando el borde superior del panel baja de la mitad de la
  franja.
- El destino se decide igual que hoy. Un usuario con sesión nunca ve el login un instante.

`[@test] ../../../test/splash/splash_arranque_test.dart` (pendiente)

### RF-SPL-5. El primer cuadro es idéntico al splash nativo

- El primer cuadro de Flutter pinta `#E77330` de borde a borde y la estrella de RF-SPL-1, con R =
  90 dp, sin «++» y sin giro.
- **El centro.** La spec toma como centro del nativo el de la pantalla física, porque el splash
  se dibuja en la ventana completa, y la grabación lo confirma. En Android 15 o superior con
  targetSdk 36, que Flutter fija por defecto (`FlutterExtension.kt:34` de flutter_tools), el
  sistema fuerza el modo de borde a borde, la vista de Flutter cubre la pantalla entera y su
  centro es el mismo. En iOS pasa igual. En Android 12 a 14, Flutter solo pone
  `LAYOUT_STABLE | LAYOUT_FULLSCREEN` (`PlatformPlugin.java:38-39` del engine), así que la vista
  arranca bajo la barra de estado pero termina sobre la barra de navegación, y con tres botones su
  centro queda más arriba que el de la pantalla. En ese caso `viewPadding.bottom` vale 0 y no
  sirve para medir la barra. Por eso la intro centra la estrella en la mitad del alto de la
  pantalla física, `View.of(context).display.size` dividido por `devicePixelRatio` y medido desde
  el borde superior de la vista, y no en la mitad de la vista (decisión 21). Donde la vista cubre
  la pantalla, las dos medidas coinciden y no hay corrección.
- Si la grabación de «Verificación» muestra que el nativo de Android 12 a 14 no se centra en la
  pantalla física, la implementación se detiene y el cambio vuelve a esta spec antes de
  corregirlo.
- Las tres variantes arrancan de ese mismo cuadro, así que el primer cuadro no depende de la
  variante.
- **Guarda de regresión.** Una prueba compara el primer cuadro, pintado a 4x, con
  `assets/splash/splash_estrella.png` compuesto sobre `#E77330`, con una tolerancia para el
  antialiasing (decisión 18). Como el PNG sale del mismo painter (RF-SPL-3), la prueba solo
  detecta que la estrella de uno cambie sin la del otro. La equivalencia real, con el centrado de
  la ventana frente a la vista y el remuestreo por densidad, la comprueba la grabación.

`[@test] ../../../test/splash/splash_primer_cuadro_test.dart` (pendiente)

### RF-SPL-6. Una variante al azar en cada arranque en frío

- Hay intro en cada arranque en frío, es decir, cada vez que corre `main()`. Al volver de segundo
  plano con la app viva no corre `main()` y no hay intro, y si el sistema cierra la app en
  segundo plano, la siguiente apertura es en frío y sí la tiene (decisión 5).
- Hasta Android 15, salir con el botón atrás desde la primera pantalla cierra la actividad y la
  siguiente apertura tiene intro. En Android 16 con targetSdk 36 el atrás predictivo viene
  activo, Flutter no registra `OnBackInvokedCallback` en la ruta raíz
  (`FlutterActivity.java:730-735` del engine) y el sistema manda la tarea al fondo sin terminarla,
  así que al reabrir no corre `main()` y no hay intro.
- La variante sale al azar con probabilidad pareja y sin repetir la del arranque anterior
  (decisión 4). Con una última variante guardada, sale una de las otras dos con probabilidad 1/2
  cada una. Sin una última válida (la primera vez, un valor desconocido o un error al leer), sale
  una de las tres con probabilidad 1/3. A la larga, cada variante sale en un tercio de los
  arranques.
- La elección es una función pura que recibe la última variante y un `Random`, que las pruebas
  inyectan.
- La última variante se guarda en `shared_preferences` con la clave `splash_ultima_variante` y
  los valores `ensamble`, `incremento` o `codigo`. Es una preferencia de interfaz y no un dato
  académico. Se escribe apenas se elige, y el cierre de sesión no la borra, porque
  `clearSession` solo quita las claves de la sesión (`storage_service.dart:206-218`).
- El servicio de `lib/services/splash_variante_service.dart` lee y escribe la clave, porque los
  widgets no tocan el almacenamiento. Lo hace con su propia instancia de `SharedPreferences` y no
  por `StorageService.to`, que la carga registra después de `Firebase.initializeApp`, así que la
  lectura no espera a la carga.
- Hasta que la variante está elegida, la estrella queda quieta, igual que en el primer cuadro, y
  en ese momento empieza a correr el tiempo de la intro. Si la lectura falla, la variante sale
  entre las tres y no se guarda.

`[@test] ../../../test/splash/splash_seleccion_test.dart` (pendiente)

### RF-SPL-7. Variante A, «Ensamble»

La maqueta de referencia es `docs/images/UI/splash/ensamble-adaptada.html`, que parte del nativo
de RF-SPL-1. `ensamble.html` conserva el concepto que ve el dueño, que arranca desde la estrella
central sola. Por la decisión 3, Ensamble arranca desde la estrella completa del nativo. Los
rombos se abren juntos, así que el logo queda desarmado, y vuelven a encajar uno a uno en sentido
horario con el paso de 50 ms y el rebote de la maqueta original. El logo se arma frente al alumno
y desde ahí sigue la maqueta.

| Fase | Tiempo (ms) | Qué pasa | Curva |
| --- | --- | --- | --- |
| Quieta | 0 a 80 | La estrella completa, igual al nativo | Ninguna |
| Apertura | 80 a 260 | Los ocho rombos se abren a la vez. Cada uno se aleja 200 u del centro, gira −60° alrededor del centro y baja a escala 0,6 y opacidad 0,4, así que el logo queda desarmado alrededor de la estrella central | easeOutCubic |
| Encaje | Rombo k (k = 0 arriba y luego en sentido horario) desde 260 + 50·k y durante 264 ms, hasta 874 el último | Vuelve a su lugar, con el giro de vuelta a 0°, la escala a 1 y la opacidad a 1 en los primeros 50 ms | Desplazamiento con easeOutBack (s = 1,25); giro y escala con easeOutCubic |
| Compresión | 119 ms después del inicio de cada encaje | La estrella central se contrae hasta 2,2 % y vuelve | Seno de 190 ms |
| Destello | 720 a 1080 | Una banda blanca con degradado cruza el logo en diagonal. Va recortada a la silueta del logo con los polígonos sin retraer (RF-SPL-2) y se dibuja detrás de los rombos y de la estrella central, así que solo asoma por las rendijas. Una banda tenue, aparte, cruza el fondo naranja. Ninguna de las dos lleva desenfoque (decisión 17) | Seno |
| Anillo | 720 a 1260 | Un anillo blanco crece de 370 u a 640 u, con trazo de 16 u a 3 u y opacidad de 0,35 a 0 | easeOutCubic |
| Primer y segundo «+» | 860 a 1160 y 930 a 1230 | Cada cruz aparece en su lugar girando de −90° a 0° con un rebote de escala, y deja una onda de 48 u a 120 u | Giro con easeOutCubic; escala con easeOutBack (s = 2,4) |
| Fin de la entrada | 1250 | El logo completo con sus «++» | Ninguna |

La salida hacia `/home` dura 530 ms (RF-SPL-11). Si la carga sigue al terminar la entrada, una
onda recorre los rombos en sentido horario, con un período de 1100 ms y hasta 20 u hacia afuera
(RF-SPL-10).

`[@test] ../../../test/splash/splash_ensamble_test.dart` (pendiente)

### RF-SPL-8. Variante B, «Incremento»

La maqueta es `docs/images/UI/splash/incremento.html`, que ya arranca desde la estrella completa
con R = 90 dp.

| Fase | Tiempo (ms) | Qué pasa | Curva |
| --- | --- | --- | --- |
| Giro | 0 a 500 | La estrella gira 45° y, por su simetría de orden ocho, termina igual | `SpringSimulation` con masa 1, rigidez 246,7 y amortiguación 17,3 (ω0 = 15,7 rad/s y ζ = 0,55) |
| Latido | 180 a 560 | Los rombos salen 24 u y la estrella central baja a 95 %, con la subida en el primer 32 % | easeOutCubic al subir y easeInOutCubic al volver |
| Onda | 230 a 790 | Un anillo va de 250 u a 540 u, con trazo de 13,5 u a 1,5 u y opacidad de 0,42 a 0 | easeOutCubic |
| Primer «+» | 480 a 920 | Sale de detrás de la estrella, de x = 190 u a x = 309 u, y su escala va de 0,72 a 1. Hasta 920 ms las cruces solo se ven a la derecha de x = 236 u, así que nacen detrás del rombo derecho | easeOutBack (s = 1,6) |
| Segundo «+» | 700 a 1120 | Nace del primero, se corre 94 u y su escala va de 0,8 a 1, como `i++` | easeOutBack (s = 1,5) |
| Corrimiento | 480 a 1060 | Todo el conjunto se corre −36 u en x para quedar centrado con sus «++» | easeInOutCubic |
| Fin de la entrada | 1150 | El logo completo con sus «++» | Ninguna |

La salida hacia `/home` dura 620 ms (RF-SPL-11). Si la carga sigue, desde 1400 ms hay un tic de
45° cada 1300 ms, y la salida absorbe el tic en curso (RF-SPL-10).

`[@test] ../../../test/splash/splash_incremento_test.dart` (pendiente)

### RF-SPL-9. Variante C, «Código»

La maqueta es `docs/images/UI/splash/codigo.html`. En ella R mide 86 dp y aquí mide 90 dp, así
que sus medidas se escalan con R.

| Fase | Tiempo (ms) | Qué pasa | Curva |
| --- | --- | --- | --- |
| Subida | 0 a 320 | La estrella sube 0,66 R y se achica a 0,82 R | easeOutCubic |
| Cursor | Aparece de 160 a 240 y se desvanece con el texto de 790 a 960 | Un cursor sigue al texto. Avanza con cada letra y cada «+» y retrocede dos posiciones a los 780 ms, cuando los «++» saltan | Lineal |
| Tecleo | 250, 318, 386, 454 y 522 | Se escribe «ULima» en letra monoespaciada de 0,34 R, con la línea base a 0,81 R bajo el centro y el renglón «ULima++» centrado | Ninguna |
| «+» tecleados | 610 y 680 | Cada «+» aparece en `#FFE7A3` con un rebote de escala de 0,55 a 1 en 110 ms | easeOutBack |
| Vuelo de los «+» | 780 a 1160 y 830 a 1210 | Cada «+» salta en arco hacia arriba hasta su lugar junto a la estrella, gira 90°, se engruesa hasta la cruz del logo y pasa a blanco | easeInOutCubic sobre una Bézier cuadrática |
| Regreso | 820 a 1210 | La estrella vuelve al centro y a R. El texto se desvanece y baja 0,12 R entre 790 y 960 | easeInOutCubic |
| Aterrizaje | 150 ms desde que llega cada «+» | Rebote de escala de 12 % | Seno |
| Pulso | 1210 a 1330 | La estrella late 3,5 % cuando el segundo «+» ya está en su lugar | Seno |
| Anillo | 1190 a 1410 | Un anillo sale de 1,02 R a 1,5 R con opacidad de 0,38 a 0. Si la salida empieza a los 1330 ms, el anillo sigue en el centro de la pantalla mientras la estrella vuela y se apaga a los 1410 ms | easeOutCubic |
| Fin de la entrada | 1330 | El logo completo con sus «++» | Ninguna |

- La letra monoespaciada es la del sistema, `monospace` en Android y `Menlo` en iOS, sin archivos
  de fuente nuevos (decisión 15). El texto no escala con el tamaño de letra del sistema, porque
  es parte del dibujo.
- La salida hacia `/home` dura 420 ms (RF-SPL-11). Si la carga sigue, un cursor parpadea junto a
  los «++» (RF-SPL-10).

`[@test] ../../../test/splash/splash_codigo_test.dart` (pendiente)

### RF-SPL-10. La espera en bucle si la carga tarda

- Si la carga termina antes que la entrada, la salida empieza al terminar la entrada. Si no, la
  variante repite su bucle hasta que la carga termina, y la salida empieza en ese momento, en las
  tres variantes.
- **A.** Una onda recorre los rombos en sentido horario, con un período de 1100 ms y hasta 20 u
  hacia afuera (forma de seno a la sexta). Entra en 300 ms y se apaga en el primer tercio de la
  salida.
- **B.** Desde 1400 ms y cada 1300 ms, la estrella da un tic de 45° con un resorte de rigidez 158
  y amortiguación 18,1. Con cada tic, los rombos laten 8 u durante 420 ms, con forma de seno, y
  cada «+» asiente con un 14 % de escala en 320 ms, el primero 60 ms después del inicio del tic y
  el segundo 110 ms después del primero.
- La salida de B puede empezar a mitad de un tic y lo absorbe. Su giro parte del ángulo de ese
  momento y termina 45° más allá del destino del tic, que por la simetría de orden ocho se ve
  igual, y el latido y el asentimiento que falten se apagan en los primeros 150 ms de la salida.
  Así B no suma espera después de la carga. La maqueta todavía espera 700 ms desde el inicio del
  tic, y en eso manda la spec.
- **C.** Un cursor parpadea a la derecha de los «++». Entra en 200 ms y después sigue un coseno
  de 1060 ms. Cuando la carga termina, se apaga en 120 ms mientras empieza la salida.
- El bucle no tiene tope propio (decisión 8). Sigue mientras la carga siga, como hoy sigue el
  splash nativo quieto.

`[@test] ../../../test/splash/splash_arranque_test.dart` (pendiente)

### RF-SPL-11. La salida hacia `/home`, con cabecera

Vale para el alumno y para el docente, cuyo `/home` usa la misma cabecera sin campana.

- **Lo común.** El panel naranja se recoge desde la pantalla completa hasta el rectángulo de la
  cabecera, borde inferior incluido, y su color va de `#E77330` a `headerColor` del tema. La
  estrella vuela hasta la estrella de la cabecera (BR-SHELL-F-04) y se achica a 26 dp. Los «++»
  terminan sobre los «++» del texto «ULIMA++», con un fundido cruzado en el último 25 % de la
  salida, porque la cruz dibujada y el glifo de la fuente no son idénticos.
- La capa dibuja una réplica del texto «ULIMA» con el mismo estilo de la cabecera para revelarlo
  como pide cada variante. El estilo vive en un solo lugar de `app_header.dart`. La campana y el
  resto de la cabecera aparecen con un fundido del panel sobre la cabecera en los últimos 100 ms.
- La cabecera informa dónde quedan su estrella y su texto una vez que se dibuja, sin una
  `GlobalKey` compartida que falle si dos cabeceras conviven un instante. Como la navegación va
  sin transición (RF-SPL-4), en ese primer cuadro la página ya está en su lugar final.
- La página sube y aparece como un todo, sin animar sus partes. Detrás de ella va el color de
  fondo del tema, así que no hay destello blanco ni negro.
- **A (530 ms, easeInOutCubic).** El borde inferior del panel se curva y se abomba hasta unos 130
  dp a mitad de la salida. El logo vuela en una curva cuadrática, cada «+» vuela por su cuenta, el
  segundo un 4 % después, y se inclina hasta −12° para igualar la cursiva. «ULIMA» se revela de
  izquierda a derecha desde el 68 % de la salida. La página sube 20 dp y aparece entre el 30 % y el
  70 %.
- **B (620 ms, curva enfatizada de Material, `Cubic(0.2, 0, 0, 1)`).** La estrella vuela en un
  arco que entra a la cabecera desde abajo y gira otros 45°, más lo que falte del tic en curso
  (RF-SPL-10). Los «++» viajan pegados a la estrella hasta los 150 ms y después se sueltan hacia
  los glifos en 450 ms. El panel se recoge con las esquinas inferiores redondeadas hasta 75 dp de
  radio. La página sube 32 dp y el texto de la cabecera aparece entre el 62 % y el 95 % del vuelo.
- **C (420 ms, easeInOutCubic).** El panel se recoge con el borde recto y la estrella vuela en
  una curva de Bézier. «ULIMA» se teclea en la cabecera desde el 55 % de la salida, una letra cada
  7 %. Los «++» sueltan la estrella al 45 % y aterrizan al final de la palabra con una
  inclinación de −10°. La página sube 20 dp y aparece desde el 35 %.
- En el último cuadro de la salida la capa muestra lo mismo que la página de debajo, así que al
  retirarla la pantalla no cambia.
- Si la cabecera no se puede medir, la salida es un fundido de 300 ms.
- Sin la estrella en la cabecera (alternativa de la decisión 11), la estrella se achica hasta la
  altura del texto y se disuelve a su izquierda.

`[@test] ../../../test/splash/splash_salida_test.dart` (pendiente)

### RF-SPL-12. La salida hacia `/setup-carrera` y hacia `/login`

Las dos salidas son comunes a las tres variantes y duran 420 ms, con easeInOutCubic
(decisión 9). A `/login` se llega la primera vez que se instala la app, después de cerrar sesión
y cuando la sesión no se puede restaurar, también sin red, así que en esos arranques las tres
variantes solo se distinguen por la entrada.

- **`/setup-carrera`.** Por defecto la página no cambia y la franja bajo la barra de estado
  sigue gris `#F7F7F8`, como hoy (decisión 10). El panel se recoge hasta el rectángulo de
  `_WizardHeader`, sin la franja, así que su borde superior baja de 0 al alto de la franja y deja
  ver el gris de la página, mientras su color va a `#FF6600`, el de esa cabecera en los dos
  temas. La estrella y los «++» se achican hacia el ícono del saludo (`LucideIcons.sparkles`, 22
  dp) y se desvanecen en el último 40 %. En el último 30 %, el panel se desvanece sobre la
  cabecera real, con su contenido y su sombra, así que en el último cuadro la capa ya no cubre
  nada y la pantalla no cambia al retirarla.
- Con la alternativa de la decisión 10, `setup_carrera_page.dart` pinta la franja de `#FF6600` en
  los dos temas, también cuando se llega desde el login, y el panel se recoge hasta la cabecera
  con la franja incluida.
- **`/login`.** En el primer 60 % de la salida, la estrella y los «++» se mueven y se achican
  hasta coincidir con la estrella y los «++» del ícono de 96 dp de la tarjeta, mientras el panel
  sigue a pantalla completa. En el 40 % restante el panel se desvanece y la página del login
  aparece con su fondo y su tarjeta alrededor de la figura, que ya está en su lugar. La escala
  final sale del ícono, que dibuja la estrella a 1,581 px por unidad sobre 1539 px, con centro en
  (773, 774).
- La figura vectorial y el PNG del ícono no coinciden al píxel, y el diseñador de Código mide un
  96 % de superposición entre el blanco de los dos. Por eso, en los últimos 120 ms la figura se
  funde con el ícono de la tarjeta, como los «++» en `/home`, y nunca se ven dos estrellas
  separadas.
- Antes de la salida hacia `/login`, la intro precarga el ícono con `precacheImage`, porque es un
  `Image.asset` de 1539 px sin `cacheWidth` (`login_page.dart:83-88`) que se decodifica aparte y
  podría faltar cuando el panel se desvanece.
- `login_page.dart` y `setup_carrera_page.dart` informan dónde quedan el ícono de la tarjeta y la
  cabecera del asistente, igual que la cabecera de RF-SPL-11. Si no se pueden medir, la salida es
  un fundido de 300 ms.

`[@test] ../../../test/splash/splash_salida_test.dart` (pendiente)

### RF-SPL-13. Modo oscuro

- El splash nativo y la entrada no cambian en oscuro y siguen en `#E77330` (decisión 2).
- La salida funde el panel al color de destino de cada tema, que es `rgb(30, 30, 36)` en la
  cabecera oscura de `/home`, `#262626` en el login oscuro y `#FF6600` en el asistente, que no
  cambia con el tema, igual que su franja gris.
- En `/home` oscuro, el borde inferior de 2 dp de la cabecera, en `primaryContainer`, aparece con
  el fundido final de RF-SPL-11.
- La estrella y los «++» siguen blancos, que es el color del texto de la cabecera en los dos
  temas.
- Con la alternativa de la decisión 2, el nativo y la entrada van sobre fondo oscuro en el tema
  oscuro, con su propia imagen nativa, y esta regla se reescribe antes de implementar.

`[@test] ../../../test/splash/splash_salida_test.dart` (pendiente)

### RF-SPL-14. Reducir movimiento

- Con `MediaQuery.disableAnimationsOf(context)` en `true`, que Flutter toma de «Quitar
  animaciones» en Android y de «Reducir movimiento» en iOS, no hay variante (decisión 12). No se
  lee ni se escribe `splash_ultima_variante`.
- La estrella queda fija en el centro. Los «++» aparecen en su lugar con un fundido de 200 ms, sin
  desplazamiento.
- Cuando la carga termina, la intro navega sin transición (RF-SPL-4) y la capa se desvanece en
  250 ms sobre la página de destino, que ya está montada debajo.
- Nada se mueve, gira ni cambia de escala en ningún momento.

`[@test] ../../../test/splash/splash_reducir_movimiento_test.dart` (pendiente)

### RF-SPL-15. Accesibilidad

- La capa es un solo nodo de semántica con la etiqueta fija «ULIMA++, cargando» (decisión 13).
  El dibujo queda fuera de la semántica, y el texto de Código también, porque es decorativo.
- La etiqueta no cambia durante la intro ni durante la espera, y la capa no es una región viva ni
  llama a `SemanticsService.announce`, así que el lector la anuncia una sola vez y no anuncia cada
  cuadro.
- Mientras la capa está encima, el lector no ve la página de debajo. Al retirarse la capa, el
  lector pasa a la página de destino.

`[@test] ../../../test/splash/splash_accesibilidad_test.dart` (pendiente)

### RF-SPL-16. Háptica

- Por defecto no hay háptica (decisión 14). La intro no responde a ningún toque, y una vibración
  que no acompaña un gesto de la persona, en cada arranque en frío y varias veces al día, deja de
  informar y pasa a molestar.
- Si el dueño la enciende, suena un `HapticFeedback.selectionClick()` cuando cada «+» llega por
  primera vez a su tamaño y a su lugar finales, y nunca con reducir movimiento. En Ensamble es
  cuando la escala de cada cruz llega a 1, hacia los 950 y 1020 ms. En Incremento es cuando cada
  «+» llega a su lugar, hacia los 650 y 870 ms. En Código es cuando cada «+» aterriza junto a la
  estrella, a los 1160 y 1210 ms.

`[@test] ../../../test/splash/splash_arranque_test.dart` (pendiente)

### RF-SPL-17. Rendimiento y tiempo hasta la app lista

- Sin paquetes nuevos. La intro usa solo el SDK, con `CustomPainter`, `AnimationController`,
  `SpringSimulation`, `Curves` y `TextPainter`. `flutter_native_splash` sigue en
  `dev_dependencies`.
- El dibujo se repinta con el `repaint` del controlador, sin reconstruir widgets en cada cuadro.
  El destello de Ensamble es un degradado recortado a la silueta del logo y no un desenfoque
  (decisión 17), y la opacidad sobre la página solo se usa durante la salida.
- **Duración.** Con una carga más corta que la entrada, la animación completa dura 1,8 s o menos.
  Las entradas duran 1250, 1150 y 1330 ms y las salidas hacia `/home` 530, 620 y 420 ms, para
  totales de 1780, 1770 y 1750 ms. Las salidas comunes de RF-SPL-12 duran 420 ms, así que hacia
  `/login` y `/setup-carrera` los totales son 1670, 1570 y 1750 ms.
- **Fluidez.** Se mide en modo perfil con la línea de tiempo de DevTools, en un Android de gama de
  entrada con pantalla de 60 Hz y en el iPhone SE del dueño, con tres arranques en frío por
  variante (decisión 17). Dos cuadros quedan fuera de la medida, porque su costo no depende de la
  intro. Uno es el primero después de `runApp`, que construye `GetMaterialApp` y el tema. El otro
  es el que construye la página de destino bajo la capa, como `HomePage` con
  `Get.put(HomeController())`, sus pestañas y la cabecera (`home_page.dart:33-34`). Ese cuadro
  ocurre siempre entre el fin de la entrada y el inicio de la salida, con el logo quieto o en su
  bucle de espera, y nunca durante la entrada ni la salida.
- Fuera de esos dos cuadros, en cada arranque a lo sumo un cuadro pasa de 16,7 ms en el hilo de
  UI o en el de raster, y ninguno pasa de 33,4 ms. El hilo de UI incluye el trabajo Dart de la
  carga, que corre en el mismo isolate, y desde Flutter 3.29 es el mismo hilo de la plataforma. En
  pantallas de 90 o 120 Hz la intro sigue el refresco y el límite es el de su cuadro.
- **Tiempo hasta la app lista.** La app queda lista cuando la capa se retira. Con E la entrada,
  C la carga, P el primer cuadro de la página de destino, que la capa espera antes de medir
  (RF-SPL-4), y S la salida, eso ocurre en máx(E, C) + P + S desde el primer cuadro de Flutter.
  Hoy la app queda lista en C + A + P desde que corre `main()`, donde A son las alertas del
  alumno, y el primer cuadro de Flutter llega recién ahí. Ninguna variante suma espera después de
  la carga, porque la salida de Incremento absorbe el tic en curso (RF-SPL-10).
- Con la intro el arranque se ve antes, porque el primer cuadro ya no espera la carga, pero la app
  queda lista más tarde que hoy en casi todos los casos. Las diferencias por destino son
  estimaciones que la medición de «Verificación» confirma.
  - `/login` sin sesión guardada. `tryRestoreSession` vuelve sin llamar a la red
    (`auth_service.dart:193-194`), así que C es solo Firebase y el almacenamiento y hoy el login
    aparece apenas terminan. Con la intro aparece de 1,6 a 1,8 s después del primer cuadro, más
    de 1 s después que hoy.
  - `/home` o `/setup-carrera` del alumno con sesión. Con una carga más corta que la entrada, la
    app queda lista hasta E + S − C − A después que hoy, entre unas décimas y algo más de 1 s
    según lo que tarde la red. Con una carga más larga, queda lista S − A después, una salida
    menos las alertas que la decisión 7 saca de la carga.
  - `/home` del docente con sesión. Hoy no pide alertas, así que con una carga larga queda lista
    una salida después que hoy, de 420 a 620 ms, y con una corta, hasta E + S − C después.
- La decisión 6 fija si la entrada se ve siempre completa, que es la opción por defecto, o si se
  acorta o se salta con un toque cuando la carga ya está lista.

`[@test] ../../../test/splash/splash_ensamble_test.dart` (pendiente)
`[@test] ../../../test/splash/splash_incremento_test.dart` (pendiente)
`[@test] ../../../test/splash/splash_codigo_test.dart` (pendiente)

### RF-SPL-18. Fallos de la carga y tope de tiempo

- **Sin red.** Todo sigue como hoy. `tryRestoreSession` devuelve `false` y la ruta es `/login`
  (`auth_service.dart:209-215`), y la intro navega ahí por `offAllToLogin` al terminar su entrada
  (RF-SPL-4).
- **Una excepción antes de registrar los servicios.** Si fallan `Firebase.initializeApp` o
  `StorageService`, no hay una ruta segura, porque el login y el home necesitan esos servicios.
  La intro termina su entrada y queda en su bucle, como hoy queda quieto el splash nativo cuando
  `runApp` nunca llega, y el error queda en el registro con `debugPrint`.
- **Una excepción después de registrarlos.** `tryRestoreSession` atrapa los errores de
  `GET /auth/me` y de lo que carga después, pero la lectura del token en flutter_secure_storage va
  antes del `try` (`auth_service.dart:193`), así que un `PlatformException` del almacén de claves
  se propaga, y hoy deja la app sin `runApp`. Si esa u otra excepción llega a la intro después
  del registro de los servicios, la intro la registra con `debugPrint` y navega a `/login` por
  `offAllToLogin`, sin borrar nada que hoy no se borre.
- **Tope.** La intro no tiene un tope de navegación propio (decisión 8). Un tope que lleve a
  `/login` mientras `tryRestoreSession` sigue corriendo choca con ese método, que borra la sesión
  si falla tarde, incluso después de que la persona vuelve a entrar. Un tope real de red va en un
  cambio aparte de auth y de platform-runtime («Qué NO entra»).

`[@test] ../../../test/splash/splash_arranque_test.dart` (pendiente)

### RF-SPL-19. Las maquetas quedan en el repo

- `docs/images/UI/splash/` guarda las maquetas como referencia visual, con su línea de tiempo en
  milisegundos, sin datos reales. Están en el repo desde `b720d70`, como parte de esta spec, y
  siguen pendientes de aprobación con ella (decisión 23).
  - `ensamble.html`, `incremento.html` y `codigo.html` son los tres conceptos. Se abren solos en un
    navegador y tienen Repetir, carga lenta y sin movimiento.
  - `ensamble-adaptada.html` es Ensamble con el arranque de RF-SPL-7, desde la estrella completa
    del nativo, el destello sin desenfoque y la página que aparece entera. Su casilla «Arranque
    alternativo» muestra la alternativa de la decisión 3.
  - `splash-conceptos.html` es la página que ve el dueño el 2026-09-25, con los tres conceptos,
    el diagnóstico y las mejoras comunes, dentro de un marco mínimo que la abre fuera del
    compañero de brainstorming. Queda como constancia y no se corrige.
  - `splash-actual-recorte.jpg` es el centro de la captura del splash actual, sin la barra de
    estado del teléfono.
  - `README.md` dice que, donde una maqueta y esta spec difieren, manda la spec, y lista las
    diferencias.
- Las tarjetas, los cursos y las aulas de las maquetas son inventados.

Sin prueba automática, porque es documentación.

## Textos nuevos

«ULIMA++, cargando» es la etiqueta de semántica de la capa (RF-SPL-15). «ULima» y los «++» de
Código son parte del dibujo y quedan fuera de la semántica (RF-SPL-9). La intro no muestra ningún
otro texto.

## Contrato que se consume

Ninguno nuevo. La carga llama a lo mismo que hoy a través de `tryRestoreSession`, con
`GET /auth/me` y, después, los catálogos del alumno o, para el docente,
`GET /official-grades/teacher/sections` (`auth_service.dart:201-205` y `:416-425`).
`GET /alerts/me` pasa de la carga al montaje del home (decisión 7), que ya lo pide hoy.

## Cambios en otras specs

- **App shell.** Suma BR-SHELL-F-04, la estrella junto a «ULIMA++» en la cabecera, pendiente de
  aprobación junto con esta spec (decisión 11). La misma regla dice que la cabecera declara
  íconos claros en la barra de estado (RF-SPL-4), que no depende de esa decisión. BR-SHELL-F-00 a
  BR-SHELL-F-03 no cambian, y el enlace de BR-SHELL-F-01 sigue siendo solo el texto.
- **Auth.** BR-AUTH-F-03 sigue siendo cierta, porque el arranque sigue llamando a
  `tryRestoreSession`, ahora desde la carga en paralelo. No cambia. `offAllToLogin` suma la
  guarda de `/arranque` y la navegación sin transición de la intro (RF-SPL-4), y sus demás
  llamadores no cambian. El login declara íconos claros en la barra de estado y dice dónde queda
  el ícono de su tarjeta (RF-SPL-12).
- **Academic profile.** El asistente de `/setup-carrera` declara íconos oscuros sobre su franja
  gris y dice dónde queda su cabecera (RF-SPL-4 y RF-SPL-12). Con la alternativa de la decisión
  10, además pinta la franja de naranja.
- **README.** La sección «El arranque» describe hoy doce pasos antes de `runApp`
  (`README.md:128-143`). La implementación la reescribe con el arranque nuevo.

## Qué NO entra

- Elegir o fijar una variante a mano, por ejemplo desde Perfil.
- Cambiar el ícono del launcher.
- Cambiar `tryRestoreSession`, que hoy borra la sesión ante cualquier error, también sin red
  (`auth_service.dart:209-215`), o sumar un tope de red a `ApiClient`, que hoy no tiene ninguno.
  Van en un cambio aparte de auth y de platform-runtime.
- Aislar un fallo de Firebase para que el resto de la app arranque sin él. Exige revisar antes cómo
  se comporta el chat sin Firebase (`chat_repository.dart:62-63`).
- Animar por partes el contenido de la página de destino, como las tarjetas escalonadas de las
  maquetas originales.
- Sonido.
- La intro en web (decisión 22). En web, `main()` conserva el arranque de hoy.
- Quitar la animación de salida que Android 12 o superior puede reproducir sobre el primer cuadro,
  que exige `setOnExitAnimationListener` en `MainActivity.kt`, fuera de targets («Verificación»).
- Paquetes de animación como Lottie, Rive o `flutter_animate`.
- Las alternativas de «Decisiones», mientras el dueño no las elija.

## Decisiones

Ninguna está aprobada. El dueño confirma o cambia cada una al aprobar la spec.

### Para el dueño

Cambian lo que ve el alumno. La columna «Qué ve el alumno» describe la opción por defecto.

| # | Decisión | Opción por defecto | Qué ve el alumno | Alternativa | Dónde queda |
| --- | --- | --- | --- | --- | --- |
| 1 | Imagen fija al tocar el ícono | La estrella completa, blanca y sin «++», sobre el mismo naranja de fondo y un poco más chica que hoy, para que Android no la corte | Ve la estrella entera, sin puntas cortadas ni un cuadrado de otro naranja. Los «++» llegan con la animación | La misma estrella algo más chica, con más aire hasta el borde del círculo que Android deja ver | RF-SPL-1 |
| 2 | Modo oscuro | Todo el arranque en naranja en los dos temas, y al final el naranja se funde con el color oscuro de la pantalla de destino | Con el teléfono en oscuro, la apertura se ve naranja, igual que en claro, y la app aparece oscura | La imagen fija y la animación sobre fondo oscuro en el tema oscuro, con la estrella blanca | RF-SPL-1 y RF-SPL-13 |
| 3 | Cómo empieza Ensamble | Los ocho rombos se abren juntos desde la estrella completa y vuelven a encajar uno a uno en sentido horario (`ensamble-adaptada.html`) | La estrella se desarma y se vuelve a armar frente a él, pieza por pieza | Los rombos se apagan en su sitio y vuelven a entrar uno a uno en espiral desde afuera, como en la maqueta original (casilla «Arranque alternativo» de la misma maqueta) | RF-SPL-7 |
| 4 | Azar | Cada apertura elige una de las tres animaciones sin repetir la de la vez anterior | Nunca ve la misma dos veces seguidas, y a la larga ve las tres por igual | Cada apertura elige entre las tres, así que a veces se repite | RF-SPL-6 |
| 5 | Cuándo hay animación | Cada vez que la app se abre desde cero | La ve al abrir la app cerrada. Al volver a la app que sigue abierta en segundo plano no la ve, salvo que el teléfono la haya cerrado en segundo plano para liberar memoria. Hasta Android 15, salir con el botón atrás cierra la app y la siguiente apertura tiene animación; desde Android 16 la app queda en segundo plano y no la tiene | También al volver a la app después de 30 minutos o más en segundo plano, sobre la pantalla en que está, lo que pide una salida más | RF-SPL-6 |
| 6 | Cuánto dura si la app carga rápido | La animación completa siempre, de 1,6 a 1,8 s | La ve entera en cada apertura. Sin sesión guardada, el login aparece más de 1 s después que hoy. Con sesión, el inicio aparece entre unas décimas y algo más de 1 s después que hoy, según la red | Un toque en la pantalla salta a la salida en cuanto la app termina de cargar, o una entrada abreviada a unos 600 ms cuando la app ya está cargada | RF-SPL-17 |
| 7 | El número de la campana | La app entra sin esperar las alertas, y el inicio las pide al abrirse, como ya hace hoy | Entra al inicio antes, y el número de la campana puede aparecer un momento después | La app espera también las alertas, y el número está desde el primer momento, a cambio de entrar más tarde | RF-SPL-4 y RF-SPL-17 |
| 8 | Si la carga no termina | La animación sigue en su espera hasta que la app responde | Sin red va al login, como hoy. Si la red se cuelga sin fallar, ve la espera animada todo lo que dure, como hoy ve la imagen fija | A los 10 s va al login, lo que pide cambiar antes cómo se restaura la sesión para que un fallo tardío no cierre la sesión nueva | RF-SPL-10 y RF-SPL-18 |
| 9 | Cómo termina según la pantalla | Al llegar al inicio, del alumno o del docente, cada animación termina a su manera. Al llegar al login o al asistente de carrera, las tres terminan igual | En el login, que ve la primera vez que instala la app, después de cerrar sesión o sin red, y en el asistente, el final es el mismo con las tres, y la diferencia está en el comienzo | Un final propio de cada animación también en el login y en el asistente | RF-SPL-11 y RF-SPL-12 |
| 10 | La franja de arriba del asistente de carrera | Queda gris claro, como hoy | La barra de estado queda sobre gris claro con íconos oscuros, y la cabecera naranja empieza debajo | Pintarla de naranja, para que la cabecera llegue hasta arriba, también al entrar desde el login | RF-SPL-4 y RF-SPL-12 |
| 11 | Estrella en la cabecera | La estrella blanca a la izquierda de «ULIMA++», como adorno | La cabecera muestra la estrella junto al nombre, y la estrella de la animación aterriza en ella | Solo el texto, como hoy, y la estrella de la animación se disuelve junto a él | BR-SHELL-F-04 de app-shell y RF-SPL-11 |
| 12 | Reducir movimiento | Sin animación. La estrella queda quieta, los «++» aparecen con un fundido corto y la app aparece con otro | Con «Quitar animaciones» o «Reducir movimiento» activado en el teléfono, nada se mueve ni gira | Ni siquiera fundidos, y la app aparece de golpe cuando termina de cargar | RF-SPL-14 |
| 13 | Lector de pantalla | Anuncia «ULIMA++, cargando» una sola vez | Con TalkBack o VoiceOver oye esa frase una vez y después la pantalla de destino, sin repeticiones mientras carga | Anuncia solo «ULIMA++» | RF-SPL-15 |
| 14 | Vibración | Sin vibración | El teléfono no vibra al abrir la app | Una vibración muy leve cuando aparece cada «+», nunca con reducir movimiento | RF-SPL-16 |
| 15 | Letra de Código | La letra de máquina de escribir que trae el teléfono | La palabra «ULima» que se escribe en Código se ve un poco distinta en Android y en iPhone | Una letra propia, JetBrains Mono, de licencia libre, para que se vea igual en los dos | RF-SPL-9 |

### Técnicas (las propone el equipo)

No cambian lo que ve el alumno, salvo donde la columna lo dice.

| # | Decisión | Propuesta del equipo | Alternativa | Qué ve el alumno | Dónde queda |
| --- | --- | --- | --- | --- | --- |
| 16 | Cómo se genera el PNG del nativo | Una prueba de golden que pinta con la geometría de la app, seguida de `flutter_native_splash:create` | Un script de Python con Pillow que lee el SVG | Nada distinto | RF-SPL-3 |
| 17 | Rendimiento y su medida | Solo el SDK; el destello de Ensamble es un degradado recortado a la silueta, sin desenfoque; la fluidez se mide en perfil, sin el primer cuadro ni el de la navegación, con a lo sumo un cuadro sobre 16,7 ms por arranque y ninguno sobre 33,4 ms | Un desenfoque en el destello, como en la maqueta original, si el perfil lo permite | El destello de Ensamble sin el halo difuso de la maqueta original | RF-SPL-7 y RF-SPL-17 |
| 18 | Prueba del primer cuadro | Un golden contra el PNG del nativo, con tolerancia, como guarda de regresión, y la equivalencia real con la grabación | Solo la grabación | Nada distinto | RF-SPL-5 |
| 19 | Navegar sin transición | `Get.offAll` con el `page` y el `binding` de la `GetPage` del destino y `Transition.noTransition`, solo desde la intro | `transition` en las `GetPage` de los tres destinos, que quita también la transición del login y del logout, o medir al terminar la transición de 300 ms y sumarla a la animación | Nada distinto. Con la primera alternativa, el login y el logout pierden su transición; con la segunda, la animación dura 300 ms más | RF-SPL-4 |
| 20 | Un 401 durante la carga | `offAllToLogin` no navega mientras la ruta es `/arranque`, salvo desde la intro | Las llamadas de `tryRestoreSession` con `suppressSessionExpiry`, que cambia `auth_service.dart` y exige sumarlo a `fetchTeacherSections` | Con la sesión vencida va al login sin el aviso «Sesión expirada», como hoy | RF-SPL-4 |
| 21 | Centro de la estrella en Android 12 a 14 | La mitad del alto de la pantalla física (`display.size`), medido desde el borde superior de la vista | Activar el modo de borde a borde en toda la app, que es un cambio global | Nada distinto. Con la alternativa, todas las pantallas llegan bajo la barra de navegación | RF-SPL-5 |
| 22 | Web | Sin intro en web, con el arranque de hoy | Forzar `/arranque` como ruta inicial en web, también al recargar en otra ruta | Nada en Android ni en iOS. Web no se despliega (`README.md:701`) | RF-SPL-4 |
| 23 | Lugar de la spec y de las maquetas | Spec propia en `specs/features/splash/`, BR-SHELL-F-04 en app-shell y maquetas en `docs/images/UI/splash/`, que están en el repo desde `b720d70` | La spec dentro de app-shell | Nada distinto | Estado y RF-SPL-19 |

## Verificación

- Antes de aprobar, el dueño abre `docs/images/UI/splash/ensamble-adaptada.html`, con y sin
  «Arranque alternativo», para decidir la decisión 3 sobre lo que se construye.
- `dart format` sobre los archivos Dart que cambien.
- `flutter analyze --no-pub`.
- `flutter test --no-pub`, con la suite completa, porque `main.dart`, `app_header.dart` y
  `session_navigation.dart` los usan otras features. Incluye `test/splash` y
  `test/components/header/app_header_test.dart`. `splash_arranque_test` cubre el 401 durante la
  carga, sin snackbar y con una sola navegación a `/login`.
- `flutter test --update-goldens test/splash/splash_png_nativo_test.dart` y
  `dart run flutter_native_splash:create` después de cambiar la geometría, y un `git diff` que solo
  muestre los recursos del splash.
- Una revisión manual en un Android 12 a 14 con barra de tres botones, en un Android 15 o superior,
  en un Android anterior a 12 (puede ser un emulador) y en el iPhone SE del dueño, en claro y en
  oscuro, con cada variante y con cada destino. Una grabación de pantalla a 60 fps, revisada
  cuadro a cuadro, comprueba que la estrella no salta entre el nativo y el primer cuadro de
  Flutter ni al retirarse la capa, y que la barra de estado queda legible en cada destino.
- En Android 12 o superior, el sistema puede reproducir su animación de salida del splash, un
  fundido o un revelado, encima del primer cuadro de Flutter. Si la grabación la muestra, quitarla
  exige `setOnExitAnimationListener` en `MainActivity.kt`, que no está en targets, y el cambio
  vuelve a esta spec antes de tocarlo.
- iOS guarda en caché la pantalla de lanzamiento, así que antes de revisar el splash nativo en el
  iPhone SE se borra y se reinstala la app, o se reinicia el teléfono.
- La misma revisión con reducir movimiento, con TalkBack y con VoiceOver.
- La medición de RF-SPL-17 en modo perfil con la línea de tiempo. Para la fluidez, tres arranques
  en frío por variante. Para el tiempo hasta la app lista, cinco arranques en frío por destino,
  contra `main` en `41ff0a6` y con la misma red.
