---
name: Splash animado
description: Splash nativo que no corta el logo y una intro animada en Flutter con tres variantes al azar, Ensamble, Incremento y Código, que corre mientras carga la app y termina en su pantalla de destino
targets:
  - ../../../lib/main.dart
  - ../../../lib/pages/splash/**
  - ../../../lib/components/logo/**
  - ../../../lib/services/splash_variante_service.dart
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

> Estado. **Diseñada el 2026-09-25 y pendiente de la aprobación del dueño antes de implementar.**
> Nada de esta spec está aprobado. «Decisiones» reúne cada punto que el dueño confirma o
> cambia, con la opción que la spec toma por defecto.
> El pedido del dueño del 2026-09-25 es reparar el splash de Android, que corta el logo, y
> volverlo animado e innovador con el logo y los «++». Se le mostraron tres conceptos animados
> y respondió que le gustan todos y que quiere «que se puedan randomizar siempre que la app se
> abra». Los tres son A «Ensamble», B «Incremento» y C «Código», y sus maquetas quedan en
> `docs/images/UI/splash/` (RF-SPL-19).
> La spec es propia y no una sección de `specs/features/app-shell/app-shell.spec.md`, porque el
> splash corre antes de la sesión y toca los recursos nativos, `pubspec.yaml` y el arranque de
> `main.dart`, mientras app-shell cubre el shell autenticado. Es el mismo reparto de la spec del
> chat, que vive aparte y suma a app-shell solo lo que cambia en la cabecera. Aquí ese cambio es
> BR-SHELL-F-04, la estrella junto a «ULIMA++» («Cambios en otras specs»).
> Las referencias `archivo:línea` apuntan a `41ff0a6`, la base de la rama `feat/splash-animado`.
> Los `[@test]` apuntan a pruebas que todavía no existen. Cada uno lleva «(pendiente)», nombra
> la prueba que fija el requisito y se escribe con la implementación.
> Donde esta spec y las maquetas difieren, manda la spec. Difieren en el arranque de Ensamble
> (RF-SPL-7), en el tamaño único de la estrella del primer cuadro (RF-SPL-1) y en la geometría
> única del logo (RF-SPL-2).

## User Stories

- Como alumno o docente, quiero ver el logo completo al abrir la app, sin puntas ni «++»
  cortados y sin un cuadrado de otro naranja detrás.
- Como alumno, quiero que el arranque se sienta vivo y distinto de una vez a otra, sin que
  tarde más.
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
- **Sin red.** `tryRestoreSession` atrapa cualquier error, también uno de red, borra la sesión y
  devuelve `false` (`auth_service.dart:209-215`), así que un arranque sin red termina hoy en
  `/login` y sin sesión guardada. Esta spec no cambia ese comportamiento («Qué NO entra»).
- **La cabecera.** `AppHeader` muestra solo el texto «ULIMA++» (`app_header.dart:79-88`) y el
  `SvgPicture` de `logo.svg` está comentado (`:161-168`). Las tres maquetas terminan con la
  estrella junto a «ULIMA++».
- **Los destinos.** `postLoginRoute` devuelve `/home` para docentes y para alumnos con la
  configuración completa, y `/setup-carrera` para los demás (`post_login_route.dart:11-14`); sin
  sesión, la ruta es `/login` (`main.dart:98-100`).
  - `/home` usa `AppHeader`, con fondo `headerColor`, que es `#FF6600` en claro y
    `rgb(30, 30, 36)` en oscuro (`themes.dart:21-25`), y un borde inferior de 2 dp en
    `primaryContainer` (`app_header.dart:58-65`). El docente no tiene campana y ocupa su lugar un
    espacio de 30 dp (`:149-150`).
  - `/setup-carrera` no usa `AppHeader`. Su cabecera es `_WizardHeader`, `#FF6600` en los dos
    temas, dentro de un `SafeArea` y sobre un fondo `#F7F7F8` fijo
    (`setup_carrera_page.dart:20-25` y `:47-95`).
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
  queda definida al compilar. Muestra la estrella completa, blanca y sin «++», centrada, sobre `#E77330` plano de
  borde a borde.
- La imagen es `assets/splash/splash_estrella.png`, de 1152 × 1152 px, con fondo transparente y la
  estrella dibujada desde la geometría de RF-SPL-2 con R = 360 px. Como `flutter_native_splash`
  la toma como 4x, mide 288 dp y la estrella llega a R = 90 dp. Con el retraimiento de la
  rendija, las puntas quedan a 88,5 dp del centro, dentro del círculo de 96 dp de radio que
  Android 12 o superior deja ver.
- `pubspec.yaml` apunta `image` y `android_12.image` a esa imagen y deja `color` y
  `android_12.color` en `#E77330`, sin `icon_background_color` ni variantes oscuras
  (decisión 1). El mismo PNG sirve en Android 12 o superior, en Android anterior, en iOS y en
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
- Cada «+» es una cruz de 72,8 u de punta a punta y 17,4 u de grosor, medida en el ícono. Sus
  centros están a (308,7; −133,8) u y (402,5; −133,8) u del centro de la estrella, arriba a la
  derecha, como en el ícono.
- Los caminos se construyen una sola vez y no en cada cuadro.

`[@test] ../../../test/splash/splash_geometria_test.dart` (pendiente)

### RF-SPL-3. Cómo se genera el PNG del splash

- El PNG lo escribe una prueba de golden que pinta la estrella con la geometría de RF-SPL-2 sobre
  un lienzo transparente de 1152 × 1152 px (decisión 3). Se genera con
  `flutter test --update-goldens test/splash/splash_png_nativo_test.dart` y después con
  `dart run flutter_native_splash:create`.
- La misma prueba, sin la bandera, comprueba que el PNG del repo coincide con la geometría, que
  mide 1152 × 1152 px, que sus esquinas son transparentes y que ningún píxel blanco queda a más de
  384 px del centro.
- No se agrega ningún paquete ni herramienta fuera del SDK de Flutter.

`[@test] ../../../test/splash/splash_png_nativo_test.dart` (pendiente)

### RF-SPL-4. `runApp` inmediato y la carga en paralelo

- `main()` llama a `runApp` justo después de `WidgetsFlutterBinding.ensureInitialized` y del
  bloqueo en vertical, que hoy ya van primero (`main.dart:59-62`).
- La carga pasa a una función que devuelve la ruta de destino y corre en paralelo con la intro.
  Da los mismos pasos que hoy y en el mismo orden, con Firebase (`main.dart:63`), la línea de
  `LucideIcons` (`:64`), `StorageService` (`:67-70`), el registro de los servicios permanentes
  (`:71-81`), `tryRestoreSession` (`:84`) y la ruta de `postLoginRoute` o `/login`
  (`:85-100`). Solo cambian las alertas del punto siguiente.
- Por defecto, `fetchAlerts` sale de la carga (`main.dart:91-97`), porque `HomeController` ya
  la pide al montarse y la campana se actualiza sola (decisión 6).
- `GetMaterialApp` arranca en `/arranque`, una página vacía de color `#E77330`. Su `builder`
  pone la capa de la intro encima del `Navigator`.
- Cuando terminan la entrada de la variante y la carga, la capa navega con
  `Get.offAllNamed(ruta)` sin animación de transición propia, espera el primer cuadro de la
  página ya montada debajo, mide los destinos (RF-SPL-11 y RF-SPL-12) y reproduce la salida. Al
  terminar, la capa se retira y la página queda tal cual.
- Mientras la capa cubre la pantalla, ningún toque llega a la página de debajo, y la barra de
  estado usa íconos claros sobre el naranja.
- El destino se decide igual que hoy. Un usuario con sesión nunca ve el login un instante.

`[@test] ../../../test/splash/splash_arranque_test.dart` (pendiente)

### RF-SPL-5. El primer cuadro es idéntico al splash nativo

- El primer cuadro de Flutter pinta `#E77330` de borde a borde y la estrella de RF-SPL-1, con R =
  90 dp, sin «++» y sin giro, centrada en la ventana completa (`MediaQuery.sizeOf`, sin
  `SafeArea`).
- Las tres variantes arrancan de ese mismo cuadro, así que el primer cuadro no depende de la
  variante.
- Si la grabación en un Android con barra de navegación de tres botones muestra un salto entre el
  nativo y el primer cuadro, el centro se corrige con el alto de esa barra (`viewPadding`) y la
  corrección queda escrita en esta spec.
- Una prueba compara el primer cuadro, pintado a 4x, con `assets/splash/splash_estrella.png`
  compuesto sobre `#E77330`, con una tolerancia para el antialiasing (decisión 16).

`[@test] ../../../test/splash/splash_primer_cuadro_test.dart` (pendiente)

### RF-SPL-6. Una variante al azar en cada arranque en frío

- Hay intro en cada arranque en frío, es decir, cada vez que corre `main()`, también al abrir la
  app después de cerrarla con el botón atrás de Android. Al volver de segundo plano con la app
  viva no corre `main()` y no hay intro (decisión 5).
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
  widgets no tocan el almacenamiento.
- Hasta que la variante está elegida, la estrella queda quieta, igual que en el primer cuadro, y
  en ese momento empieza a correr el tiempo de la intro. Si la lectura falla, la variante sale
  entre las tres y no se guarda.

`[@test] ../../../test/splash/splash_seleccion_test.dart` (pendiente)

### RF-SPL-7. Variante A, «Ensamble»

La maqueta es `docs/images/UI/splash/ensamble.html`. Por la decisión 2, Ensamble arranca desde la
estrella completa del nativo y no desde la estrella central sola. Los rombos se abren en espiral y
vuelven a encajar, y desde ahí sigue la maqueta.

| Fase | Tiempo (ms) | Qué pasa | Curva |
| --- | --- | --- | --- |
| Quieta | 0 a 80 | La estrella completa, igual al nativo | Ninguna |
| Apertura en espiral | Rombo k (k = 0 arriba y luego en sentido horario) desde 80 + 45·k y durante 176 ms | Se aleja 200 u del centro, gira −60° alrededor del centro y baja a escala 0,6 y opacidad 0,4 | easeOutCubic |
| Encaje | Los 264 ms siguientes de cada rombo, hasta 835 el último | Vuelve a su lugar, con el giro de vuelta a 0°, la escala a 1 y la opacidad a 1 en los primeros 50 ms | Desplazamiento con easeOutBack (s = 1,25); giro y escala con easeOutCubic |
| Compresión | En cada encaje | La estrella central se contrae hasta 2,2 % y vuelve | Seno de 190 ms |
| Destello | 720 a 1080 | Una banda blanca con degradado cruza el logo en diagonal por detrás de los rombos y se ve por las rendijas, y una banda tenue cruza el fondo | Seno |
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
45° cada 1300 ms (RF-SPL-10).

`[@test] ../../../test/splash/splash_incremento_test.dart` (pendiente)

### RF-SPL-9. Variante C, «Código»

La maqueta es `docs/images/UI/splash/codigo.html`. En ella R mide 86 dp y aquí mide 90 dp, así
que sus medidas se escalan con R.

| Fase | Tiempo (ms) | Qué pasa | Curva |
| --- | --- | --- | --- |
| Subida | 0 a 320 | La estrella sube 0,66 R y se achica a 0,82 R | easeOutCubic |
| Cursor | 160 a 240 | Aparece un cursor | Lineal |
| Tecleo | 250, 318, 386, 454 y 522 | Se escribe «ULima» en letra monoespaciada de 0,34 R, con la línea base a 0,81 R bajo el centro y el renglón «ULima++» centrado | Ninguna |
| «+» tecleados | 610 y 680 | Cada «+» aparece en `#FFE7A3` con un rebote de escala de 0,55 a 1 en 110 ms | easeOutBack |
| Vuelo de los «+» | 780 a 1160 y 830 a 1210 | Cada «+» salta en arco hacia arriba hasta su lugar junto a la estrella, gira 90°, se engruesa hasta la cruz del logo y pasa a blanco | easeInOutCubic sobre una Bézier cuadrática |
| Regreso | 820 a 1210 | La estrella vuelve al centro y a R. El texto se desvanece y baja 0,12 R entre 790 y 960 | easeInOutCubic |
| Aterrizaje | 150 ms desde que llega cada «+» | Rebote de escala de 12 % | Seno |
| Pulso y anillo | 1190 a 1410 | La estrella late 3,5 % y un anillo sale de 1,02 R a 1,5 R con opacidad de 0,38 a 0 | easeOutCubic |
| Fin de la entrada | 1330 | El logo completo con sus «++» | Ninguna |

- La letra monoespaciada es la del sistema, `monospace` en Android y `Menlo` en iOS, sin archivos
  de fuente nuevos (decisión 14). El texto no escala con el tamaño de letra del sistema, porque
  es parte del dibujo.
- La salida hacia `/home` dura 420 ms (RF-SPL-11). Si la carga sigue, un cursor parpadea junto a
  los «++» (RF-SPL-10).

`[@test] ../../../test/splash/splash_codigo_test.dart` (pendiente)

### RF-SPL-10. La espera en bucle si la carga tarda

- Si la carga termina antes que la entrada, la salida empieza al terminar la entrada. Si no, la
  variante repite su bucle hasta que la carga termina.
- **A.** Una onda recorre los rombos en sentido horario, con un período de 1100 ms y hasta 20 u
  hacia afuera (forma de seno a la sexta). Entra en 300 ms y se apaga en el primer tercio de la
  salida.
- **B.** Desde 1400 ms y cada 1300 ms, la estrella da un tic de 45° con un resorte de rigidez 158
  y amortiguación 18,1, los rombos laten 8 u y cada «+» asiente con un 14 % de escala en 320 ms,
  el segundo 110 ms después del primero. La salida nunca empieza a mitad de un tic, sino 700 ms
  después de su inicio o más tarde.
- **C.** Un cursor parpadea a la derecha de los «++». Entra en 200 ms y después sigue un coseno
  de 1060 ms. Cuando la carga termina, se apaga en 120 ms mientras empieza la salida.
- El bucle no tiene tope propio (decisión 7). Sigue mientras la carga siga, como hoy sigue el
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
  `GlobalKey` compartida que falle si dos cabeceras conviven un instante.
- La página sube y aparece como un todo, sin animar sus partes. Detrás de ella va el color de
  fondo del tema, así que no hay destello blanco ni negro.
- **A (530 ms, easeInOutCubic).** El borde inferior del panel se curva y se abomba hasta unos 130
  dp a mitad de la salida. El logo vuela en una curva cuadrática, cada «+» vuela por su cuenta, el
  segundo un 4 % después, y se inclina hasta −12° para igualar la cursiva. «ULIMA» se revela de
  izquierda a derecha desde el 68 % de la salida. La página sube 20 dp y aparece entre el 30 % y el
  70 %.
- **B (620 ms, curva enfatizada de Material, `Cubic(0.2, 0, 0, 1)`).** La estrella vuela en un
  arco que entra a la cabecera desde abajo y gira otros 45°. Los «++» viajan pegados a la estrella
  hasta los 150 ms y después se sueltan hacia los glifos en 450 ms. El panel se recoge con las
  esquinas inferiores redondeadas hasta 75 dp de radio. La página sube 32 dp y el texto de la
  cabecera aparece entre el 62 % y el 95 % del vuelo.
- **C (420 ms, easeInOutCubic).** El panel se recoge con el borde recto y la estrella vuela en
  una curva de Bézier. «ULIMA» se teclea en la cabecera desde el 55 % de la salida, una letra cada
  7 %. Los «++» sueltan la estrella al 45 % y aterrizan al final de la palabra con una
  inclinación de −10°. La página sube 20 dp y aparece desde el 35 %.
- En el último cuadro de la salida la capa muestra lo mismo que la página de debajo, así que al
  retirarla la pantalla no cambia.
- Si la cabecera no se puede medir, la salida es un fundido de 300 ms.
- Sin la estrella en la cabecera (alternativa de la decisión 10), la estrella se achica hasta la
  altura del texto y se disuelve a su izquierda.

`[@test] ../../../test/splash/splash_salida_test.dart` (pendiente)

### RF-SPL-12. La salida hacia `/setup-carrera` y hacia `/login`

Las dos salidas son comunes a las tres variantes y duran 420 ms, con easeInOutCubic
(decisión 8).

- **`/setup-carrera`.** El panel se recoge hasta el rectángulo de `_WizardHeader`, con el
  `SafeArea` de arriba incluido, y su color va a `#FF6600`, que es el de esa cabecera en los dos
  temas. La estrella y los «++» se achican hacia el ícono del saludo (`LucideIcons.sparkles`, 22
  dp) y se desvanecen en el último 40 %. El contenido de la cabecera aparece con un fundido del
  panel en el último 30 %.
- **`/login`.** En el primer 60 % de la salida, la estrella y los «++» se mueven y se achican
  hasta coincidir con la estrella y los «++» del ícono de 96 dp de la tarjeta, mientras el panel
  sigue a pantalla completa. En el 40 % restante el panel se desvanece y la página del login
  aparece con su fondo y su tarjeta alrededor de la figura, que ya está en su lugar, así que nunca
  se ven dos estrellas. La escala final sale del ícono, que dibuja la estrella a 1,581 px por
  unidad sobre 1539 px, con centro en (773, 774).
- `login_page.dart` y `setup_carrera_page.dart` informan dónde quedan el ícono de la tarjeta y la
  cabecera del asistente, igual que la cabecera de RF-SPL-11. Si no se pueden medir, la salida es
  un fundido de 300 ms.

`[@test] ../../../test/splash/splash_salida_test.dart` (pendiente)

### RF-SPL-13. Modo oscuro

- El splash nativo y la entrada no cambian en oscuro y siguen en `#E77330` (decisión 9).
- La salida funde el panel al color de destino de cada tema, que es `rgb(30, 30, 36)` en la
  cabecera oscura de `/home`, `#262626` en el login oscuro y `#FF6600` en el asistente, que no
  cambia con el tema.
- En `/home` oscuro, el borde inferior de 2 dp de la cabecera, en `primaryContainer`, aparece con
  el fundido final de RF-SPL-11.
- La estrella y los «++» siguen blancos, que es el color del texto de la cabecera en los dos
  temas.

`[@test] ../../../test/splash/splash_salida_test.dart` (pendiente)

### RF-SPL-14. Reducir movimiento

- Con `MediaQuery.disableAnimationsOf(context)` en `true`, que Flutter toma de «Quitar
  animaciones» en Android y de «Reducir movimiento» en iOS, no hay variante (decisión 11). No se
  lee ni se escribe `splash_ultima_variante`.
- La estrella queda fija en el centro. Los «++» aparecen en su lugar con un fundido de 200 ms, sin
  desplazamiento.
- Cuando la carga termina, la capa se desvanece en 250 ms sobre la página de destino, que ya está
  montada debajo.
- Nada se mueve, gira ni cambia de escala en ningún momento.

`[@test] ../../../test/splash/splash_reducir_movimiento_test.dart` (pendiente)

### RF-SPL-15. Accesibilidad

- La capa es un solo nodo de semántica con la etiqueta fija «ULIMA++, cargando» (decisión 12).
  El dibujo queda fuera de la semántica, y el texto de Código también, porque es decorativo.
- La etiqueta no cambia durante la intro ni durante la espera, y la capa no es una región viva ni
  llama a `SemanticsService.announce`, así que el lector la anuncia una sola vez y no anuncia cada
  cuadro.
- Mientras la capa está encima, el lector no ve la página de debajo. Al retirarse la capa, el
  lector pasa a la página de destino.

`[@test] ../../../test/splash/splash_accesibilidad_test.dart` (pendiente)

### RF-SPL-16. Háptica

- Por defecto no hay háptica (decisión 13). La intro no responde a ningún toque, y las guías de
  interfaz de Apple reservan la háptica para acompañar lo que hace la persona. Una vibración en
  cada arranque en frío, que se repite varias veces al día, deja de informar y pasa a molestar.
- Si el dueño la enciende, suena un `HapticFeedback.selectionClick()` al aterrizar cada «+» y
  nunca con reducir movimiento.

`[@test] ../../../test/splash/splash_arranque_test.dart` (pendiente)

### RF-SPL-17. Rendimiento y tiempos

- Sin paquetes nuevos. La intro usa solo el SDK, con `CustomPainter`, `AnimationController`,
  `SpringSimulation`, `Curves` y `TextPainter`. `flutter_native_splash` sigue en
  `dev_dependencies`.
- El dibujo se repinta con el `repaint` del controlador, sin reconstruir widgets en cada cuadro.
  El destello de Ensamble es un degradado y no un desenfoque (decisión 15), y la opacidad sobre
  la página solo se usa durante la salida.
- Con una carga rápida, la animación completa dura 1,8 s o menos. Las entradas duran 1250, 1150 y
  1330 ms y las salidas hacia `/home` 530, 620 y 420 ms, para totales de 1780, 1770 y 1750 ms. Las
  salidas comunes de RF-SPL-12 duran 420 ms.
- **60 fps.** En modo perfil, en un Android de gama de entrada con pantalla de 60 Hz y en el
  iPhone SE del dueño, ningún cuadro de la intro supera 16,7 ms en los hilos de UI y de raster,
  en tres arranques en frío por variante. En pantallas de 90 o 120 Hz la intro sigue el refresco.
- **Sin retrasar el arranque.** El primer cuadro de Flutter llega antes que hoy, porque `runApp`
  ya no espera la carga. La carga no espera a la animación y dura lo mismo que hoy, con 50 ms de
  margen, sin contar `/alerts/me`. La app queda lista cuando termina la salida, que empieza en el
  mayor de dos momentos, el fin de la entrada y el fin de la carga.
- Con una carga más corta que la entrada, la app queda lista a lo sumo 1,8 s después del primer
  cuadro, que es el costo de ver la animación completa. Con una carga más larga, la app queda
  lista una salida después de que termina la carga, y sacar `/alerts/me` de la carga
  (decisión 6) compensa ese tiempo.

`[@test] ../../../test/splash/splash_ensamble_test.dart` (pendiente)
`[@test] ../../../test/splash/splash_incremento_test.dart` (pendiente)
`[@test] ../../../test/splash/splash_codigo_test.dart` (pendiente)

### RF-SPL-18. Fallos de la carga y tope de tiempo

- **Sin red.** Todo sigue como hoy. `tryRestoreSession` devuelve `false` y la ruta es `/login`
  (`auth_service.dart:209-215`), y la intro navega ahí al terminar su entrada.
- **Una excepción antes de registrar los servicios.** Si fallan `Firebase.initializeApp` o
  `StorageService`, no hay una ruta segura, porque el login y el home necesitan esos servicios.
  La intro termina su entrada y queda en su bucle, como hoy queda quieto el splash nativo cuando
  `runApp` nunca llega, y el error queda en el registro con `debugPrint`.
- **Una excepción después de registrarlos.** No se espera, porque `tryRestoreSession` atrapa
  todo, pero si ocurre, la intro la registra con `debugPrint` y navega a `/login`, sin borrar nada
  que hoy no se borre.
- **Tope.** La intro no tiene un tope de navegación propio (decisión 7). Un tope que lleve a
  `/login` mientras `tryRestoreSession` sigue corriendo choca con ese método, que borra la sesión
  si falla tarde, incluso después de que la persona vuelve a entrar. Un tope real de red va en un
  cambio aparte de auth y de platform-runtime («Qué NO entra»).

`[@test] ../../../test/splash/splash_arranque_test.dart` (pendiente)

### RF-SPL-19. Las maquetas quedan en el repo

- `docs/images/UI/splash/` guarda las maquetas como referencia visual, con su línea de tiempo en
  milisegundos, sin datos reales.
  - `ensamble.html`, `incremento.html` y `codigo.html` son los tres conceptos. Se abren solos en un
    navegador y tienen Repetir, carga lenta y sin movimiento.
  - `splash-conceptos.html` es la página que vio el dueño, con los tres conceptos, el diagnóstico
    y las mejoras comunes, dentro de un marco mínimo que la abre fuera del compañero de
    brainstorming.
  - `splash-actual-recorte.jpg` es el centro de la captura del splash actual, sin la barra de
    estado del teléfono.
- Las tarjetas, los cursos y las aulas de las maquetas son inventados.

Sin prueba automática, porque es documentación.

## Textos nuevos

«ULIMA++, cargando» es la etiqueta de semántica de la capa (RF-SPL-15). «ULima» y los «++» de
Código son parte del dibujo y quedan fuera de la semántica (RF-SPL-9). La intro no muestra ningún
otro texto.

## Contrato que se consume

Ninguno nuevo. La carga llama a lo mismo que hoy a través de `tryRestoreSession`, con
`GET /auth/me` y los catálogos. `GET /alerts/me` pasa de la carga al montaje del home
(decisión 6), que ya lo pide hoy.

## Cambios en otras specs

- **App shell.** Suma BR-SHELL-F-04, la estrella junto a «ULIMA++» en la cabecera, pendiente de
  aprobación junto con esta spec (decisión 10). BR-SHELL-F-00 a BR-SHELL-F-03 no cambian, y el
  enlace de BR-SHELL-F-01 sigue siendo solo el texto.
- **Auth.** BR-AUTH-F-03 sigue siendo cierta, porque el arranque sigue llamando a
  `tryRestoreSession`, ahora desde la carga en paralelo. No cambia.
- **README.** La sección «El arranque» describe hoy doce pasos antes de `runApp`
  (`README.md:128-143`). La implementación la reescribe con el arranque nuevo.

## Qué NO entra

- Elegir o fijar una variante a mano, por ejemplo desde Perfil.
- Saltar la intro con un toque.
- Cambiar el ícono del launcher.
- Un splash nativo oscuro (alternativa de la decisión 1).
- Cambiar `tryRestoreSession`, que hoy borra la sesión ante cualquier error, también sin red
  (`auth_service.dart:209-215`), o sumar un tope de red a `ApiClient`, que hoy no tiene ninguno.
  Van en un cambio aparte de auth y de platform-runtime.
- Aislar un fallo de Firebase para que el resto de la app arranque sin él. Exige revisar antes cómo
  se comporta el chat sin Firebase (`chat_repository.dart:62-63`).
- Animar por partes el contenido de la página de destino, como las tarjetas escalonadas de la
  maqueta de Ensamble.
- Sonido.
- La intro al volver de segundo plano.
- Una revisión manual en web. La intro corre igual en web, pero la revisión es de Android y de iOS.
- Paquetes de animación como Lottie, Rive o `flutter_animate`.

## Decisiones

Ninguna está aprobada. El dueño confirma o cambia cada una al aprobar la spec.

| # | Decisión | Opción por defecto | Alternativa | Dónde queda |
| --- | --- | --- | --- | --- |
| 1 | Splash nativo único | Estrella completa sin «++», R = 90 dp y puntas a 88,5 dp dentro del círculo de 96 dp, sobre `#E77330` plano, con el mismo PNG en Android 12 o superior, Android anterior, iOS y web, en claro y en oscuro | R = 86 dp, con más margen, o fondo oscuro en modo oscuro con `color_dark` | RF-SPL-1 |
| 2 | Arranque de Ensamble | Desde la estrella completa, con los rombos que se abren en espiral y vuelven a encajar | Rombos que laten sin separarse | RF-SPL-7 |
| 3 | Cómo se genera el PNG | Una prueba de golden que pinta con la geometría de la app, seguida de `flutter_native_splash:create` | Un script de Python con Pillow que lee el SVG | RF-SPL-3 |
| 4 | Azar | Probabilidad pareja sin repetir la anterior, 1/2 entre las otras dos y 1/3 la primera vez, con la clave `splash_ultima_variante` | 1/3 en cada arranque, con repeticiones | RF-SPL-6 |
| 5 | Cuándo hay intro | En cada arranque en frío, cada vez que corre `main()`, y nunca al volver de segundo plano | Ninguna | RF-SPL-6 |
| 6 | Alertas en el arranque | `fetchAlerts` sale de la carga, porque el home ya las pide al montarse | Se queda en la carga y el arranque espera también `/alerts/me` | RF-SPL-4 y RF-SPL-17 |
| 7 | Fallos y tope | Sin red, igual que hoy hacia `/login`; sin tope de navegación propio, con el bucle hasta que termina la carga | Tope de 10 s hacia `/login`, con cambios en `AuthService` para que un fallo tardío no borre la sesión nueva | RF-SPL-10 y RF-SPL-18 |
| 8 | Finales por destino | `/home` con el final propio de cada variante; `/setup-carrera` y `/login` con un final común de 420 ms | Un final propio de cada variante en los tres destinos | RF-SPL-11 y RF-SPL-12 |
| 9 | Modo oscuro | Nativo y entrada en naranja; la salida funde a `rgb(30, 30, 36)`, `#262626` o `#FF6600` según el destino | Nativo e intro oscuros | RF-SPL-13 |
| 10 | Cabecera | Estrella de 26 dp a 10 dp de «ULIMA++», decorativa y fuera del enlace | Solo el texto, y la estrella se disuelve en él al final | BR-SHELL-F-04 de app-shell y RF-SPL-11 |
| 11 | Reducir movimiento | Sin variante, estrella fija, «++» con un fundido de 200 ms y un fundido de 250 ms a la app | Ninguna animación, ni siquiera fundidos | RF-SPL-14 |
| 12 | Lector de pantalla | Una etiqueta fija, «ULIMA++, cargando», sin región viva, y la página de debajo oculta al lector hasta que la capa se retira | La etiqueta «ULIMA++» sola | RF-SPL-15 |
| 13 | Háptica | Apagada | `selectionClick` al aterrizar cada «+», nunca con reducir movimiento | RF-SPL-16 |
| 14 | Letra de Código | Monoespaciada del sistema, `monospace` en Android y `Menlo` en iOS | JetBrains Mono en un subconjunto como fuente del proyecto, con su licencia OFL, para que se vea igual en los dos | RF-SPL-9 |
| 15 | Rendimiento | Solo el SDK, el destello de Ensamble sin desenfoque y ningún cuadro sobre 16,7 ms en perfil | Un desenfoque en el destello si el perfil lo permite | RF-SPL-17 |
| 16 | Golden del primer cuadro | Sí, contra el PNG del nativo y con tolerancia para el antialiasing | Solo la revisión manual con grabación | RF-SPL-5 |
| 17 | Lugar de la spec y de las maquetas | Spec propia en `specs/features/splash/`, BR-SHELL-F-04 en app-shell y maquetas en `docs/images/UI/splash/` | La spec dentro de app-shell | Estado y RF-SPL-19 |

## Verificación

- `dart format` sobre los archivos Dart que cambien.
- `flutter analyze --no-pub`.
- `flutter test --no-pub`, con la suite completa, porque `main.dart` y `app_header.dart` los usan
  otras features. Incluye `test/splash` y `test/components/header/app_header_test.dart`.
- `flutter test --update-goldens test/splash/splash_png_nativo_test.dart` y
  `dart run flutter_native_splash:create` después de cambiar la geometría, y un `git diff` que solo
  muestre los recursos del splash.
- Una revisión manual en un Android 12 o superior, en un Android anterior (puede ser un
  emulador) y en el iPhone SE del dueño, en claro y en oscuro, con cada variante y con cada
  destino. Una grabación de pantalla a 60 fps, revisada cuadro a cuadro, comprueba que la estrella
  no salta entre el nativo y el primer cuadro de Flutter ni al retirarse la capa.
- La misma revisión con reducir movimiento, con TalkBack y con VoiceOver.
- La medición de RF-SPL-17 en modo perfil, con cinco arranques en frío por caso, contra `main` en
  `41ff0a6` y con la misma red.
