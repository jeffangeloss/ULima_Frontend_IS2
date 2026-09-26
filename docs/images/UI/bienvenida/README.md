# Maqueta de la bienvenida con Ulises

`ulises-te-recibe-combinada.html` es la versión combinada de «Ulises te recibe», la que el dueño
elige el 2026-09-25 para el arranque sin sesión. Es la referencia visual de RF-SPL-20 y RF-SPL-21
de `specs/features/splash/splash.spec.md` y de `specs/features/bienvenida/bienvenida.spec.md`
(RF-BIEN-19). Las dos specs siguen pendientes de la aprobación del dueño, y donde la maqueta y una
spec difieren, manda la spec.

- Se abre sola en un navegador. Arriba elige el recorrido («Con sesión», «Soy nuevo» y «Ya tengo
  cuenta») y la intro del splash («Al azar», Ensamble, Incremento y Código), y abajo tiene Repetir,
  «Modo oscuro» y «Reducir movimiento».
- La imagen de Ulises es `assets/images/ulises_chatbot.png` del repo, que la maqueta lee con una
  ruta relativa, así que se abre desde esta carpeta del repo.
- Con sesión, la intro termina en `/home` abierto en la pestaña Horario (RF-SPL-20). Sin sesión, la
  estrella se queda entera en el centro con sus «++», Ulises aterriza a su lado sin taparla y, al
  responder «¿Ya usas ULima++?», la estrella sube al sello junto a «ULIMA++» (RF-SPL-21 y
  RF-BIEN-2).

## Diferencias con la spec del splash

- Las tres intros son las maquetas de `docs/images/UI/splash/`, con las diferencias que lista su
  README, como los 86 dp de la estrella de Código.
- Con sesión, Ulises aparece en su burbuja con un rebote después de la salida. En la spec del
  splash aparece con la página, como hoy (decisión 28).
- La maqueta abre Horario solo para una alumna. La pestaña de cada rol es la decisión 24 del
  splash.

## Diferencias con la spec de la bienvenida

Todo lo que pasa después del relevo lo fija la spec de la bienvenida, y en estos puntos manda ella.

- El test empieza mientras se crea la cuenta, con «Mientras tanto, ¿empezamos tu test de
  especialidad? Son 14 preguntas cortas.», «Prefiero esperar» y «Empezar el test». En la spec
  empieza con la cuenta ya creada, porque su contenido exige el token (decisión 1).
- El código del authenticator se envía solo al completar las seis casillas. En la spec se envía
  con el botón «Crear mi cuenta» (decisión 5).
- «Soy nuevo» usa blanco al 14 % sobre el naranja, con 2,59:1. En la spec va sobre `#B84A00`, con
  5,23:1 (decisión 3). La pista de los campos usa `#8A94A6` y el foco `#FF6600`, que en la spec
  pasan a `testMuted` y a `bienvenidaFoco` (RF-BIEN-14).
- Ulises llama «Valeria» a la alumna. En la spec va sin nombre (decisión 4).
- El turno de la contraseña de «Ya tengo cuenta» no trae «Soy nuevo», y los turnos del registro
  no traen «Volver» ni «Ya tengo cuenta». En la spec están en todos (RF-BIEN-6, RF-BIEN-7 y
  RF-BIEN-9).
- No hay turnos de error, de `incierto` ni de sesión expirada, que la spec define en RF-BIEN-8 y
  RF-BIEN-12.
- El duelo no trae «Me gustan las dos» ni «Ninguna me llama», y el resultado dice «Elegir Software
  como principal», sin «Rehacer el test», los electivos ni «También te puede interesar». Mandan
  la spec del test y RF-BIEN-10.
- Las líneas de Ulises dentro del test, como «Primera práctica y te dejan escoger. ¿Cuál te
  pides?» o «¡Craa! Lo tuyo es esto, Valeria 👇», son ilustrativas. Mandan las del contenido.
- El marcador «12 preguntas después» es un atajo de la maqueta y no existe en la app.
- Los campos, las píldoras y los enlaces miden menos de 48 dp. En la spec miden al menos 48 dp
  (RF-BIEN-16).
- La franja mide 100 px y la cabecera 96 px. En la spec miden lo mismo (RF-BIEN-4).

Los datos son ficticios. El código es `20230001`, la alumna se llama Valeria, las contraseñas son
de relleno y se muestran como puntos, el código del autenticador, `482913`, es inventado, y los
cursos y las aulas también.
