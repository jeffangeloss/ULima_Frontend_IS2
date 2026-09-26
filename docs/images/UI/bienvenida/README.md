# Maqueta de la bienvenida con Ulises

`ulises-te-recibe-combinada.html` es la versión combinada de «Ulises te recibe», la que el dueño
elige el 2026-09-25 para el arranque sin sesión. Es la referencia visual de RF-SPL-20 y RF-SPL-21
de `specs/features/splash/splash.spec.md` y de la spec nueva de la bienvenida, que todavía no está
escrita. Las dos specs siguen pendientes de la aprobación del dueño, y donde la maqueta y una spec
difieren, manda la spec.

- Se abre sola en un navegador. Arriba elige el recorrido («Con sesión», «Soy nuevo» y «Ya tengo
  cuenta») y la intro del splash («Al azar», Ensamble, Incremento y Código), y abajo tiene Repetir,
  «Modo oscuro» y «Reducir movimiento».
- La imagen de Ulises es `assets/images/ulises_chatbot.png` del repo, que la maqueta lee con una
  ruta relativa, así que se abre desde esta carpeta del repo.
- Con sesión, la intro termina en `/home` abierto en la pestaña Horario (RF-SPL-20). Sin sesión, la
  estrella se queda entera en el centro con sus «++», Ulises aterriza a su lado sin taparla y, al
  responder «¿Ya usas ULima++?», la estrella sube al sello junto a «ULIMA++» (RF-SPL-21).

La maqueta difiere de las specs en estos puntos, y en todos mandan las specs.

- Las tres intros son las maquetas de `docs/images/UI/splash/`, con las diferencias que lista su
  README, como los 86 dp de la estrella de Código.
- Con sesión, Ulises aparece en su burbuja con un rebote después de la salida. En la spec del
  splash aparece con la página, como hoy (decisión 28).
- La maqueta abre Horario solo para una alumna. La pestaña de cada rol es la decisión 25 del
  splash.
- Todo lo que pasa después del relevo, que incluye el vuelo de Ulises, el paso al naranja de la
  conversación, el sello, el inicio de sesión, el registro y el test, lo fija la spec de la
  bienvenida y no la del splash.

Los datos son ficticios. El código es `20230001`, la alumna se llama Valeria, las contraseñas son
de relleno y se muestran como puntos, el código del autenticador, `482913`, es inventado, y los
cursos y las aulas también.
