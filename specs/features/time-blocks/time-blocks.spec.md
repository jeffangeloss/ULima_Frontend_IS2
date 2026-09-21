---
name: Time Blocks
description: Bloques de horario propios del alumno en la pantalla de horario — crearlos, editarlos, corregir un día suelto, verlos junto a las clases y sumar sus horas semanales
targets:
  - ../../../lib/pages/time_blocks/**
  - ../../../lib/services/time_blocks_service.dart
  - ../../../lib/models/time_block_model.dart
  - ../../../lib/pages/horario/horario.dart
  - ../../../lib/pages/horario/horario_controller.dart
  - ../../../lib/main.dart
---

# Bloques de horario propios

> Estado: **diseñada con el dueño del proyecto el 2026-09-20**, sección por sección.
> Pendiente de su aprobación de esta spec escrita antes de planificar.
> Contraparte de backend: `ULima_Backend_IS2/specs/features/time-blocks/time-blocks.spec.md`
> (RS-BE-30 a RS-BE-35).

## User Stories

- Como alumno, quiero registrar mis prácticas en mi horario para ver mi semana completa.
- Como alumno, quiero corregir una semana suelta sin deshacer el patrón.
- Como alumno, quiero saber cuántas horas a la semana me llevan mis bloques.

## Requisitos

### RF-BLQ-1 — Agregar un bloque desde el horario

En la pantalla de horario, y solo para alumnos, un botón para agregar un bloque. Abre el
formulario de RF-BLQ-2 como ruta nueva con binding por ruta, como el resto de la app.

Un docente no lo ve: su horario es el de sus clases y asesorías.

`[@test] ../../../test/HU35_jeff/time_blocks_form_test.dart`

### RF-BLQ-2 — El formulario

Campos, en este orden: **nombre**, **color**, **días de la semana**, **hora de inicio y
fin**, **desde** y **hasta**.

- El color se elige de la paleta de doce que la app ya usa para los cursos
  (`lib/configs/course_colors.dart`), como una fila de círculos. No se agrega ninguna
  dependencia de selector de color.
- Los días son botones de alternancia, de lunes a domingo. Viajan al servidor como números
  con su convención: 1 es lunes y 7 es domingo, igual que `schedule_session.day_of_week`.
- Las horas usan `showTimePicker` y las fechas `showDatePicker`, igual que el formulario de
  asesorías (`lib/pages/teacher/create_advising_page.dart`), que es el precedente del repo.
- La validación vive en funciones puras que devuelven `String?` en español, como
  `lib/pages/teacher/advising_validators.dart`: nombre entre 1 y 60 caracteres, al menos un
  día, hora de fin posterior a la de inicio, las dos dentro de **7 am–10 pm**, y fecha de
  fin no anterior a la de inicio.
- El mismo formulario sirve para crear y para editar; al editar trae los valores actuales.

El servidor vuelve a validar todo: el mensaje que se muestra ante un error del servidor es
el que él manda, no uno inventado por la app.

`[@test] ../../../test/HU35_jeff/time_blocks_form_test.dart`

### RF-BLQ-3 — Aviso de choque antes de guardar

Antes de enviar, la app compara el bloque contra las clases que ya tiene en pantalla y
contra los demás bloques del alumno. Si hay cruce, muestra un aviso que **nombra con qué**
y **cuándo** —"se cruza con Paradigmas de Programación, martes de 4:00 pm a 6:00 pm"— y
ofrece guardar igual o volver a editar. **Nunca impide guardar**: el cruce puede ser real y
el alumno lo sabe.

La detección es una función pura, probada aparte: dos rangos de hora en el mismo día de la
semana se cruzan si uno empieza antes de que el otro termine. Tocarse en el borde (una
termina 18:00 y la otra empieza 18:00) **no** es cruce.

`[@test] ../../../test/HU35_jeff/time_blocks_conflicto_test.dart`

### RF-BLQ-4 — Pintados junto a las clases, sin taparse

Los bloques propios se pintan en las dos vistas del horario —la de día y la semanal
horizontal— con el color que eligió el alumno, y llevan su nombre. No muestran salón ni
sección, porque no tienen.

**Reparto lado a lado.** Cuando dos o más bloques coinciden en el mismo tramo de un día, se
reparten el ancho en columnas y todos quedan visibles y tocables. Hoy no es así: dos
bloques simultáneos se dibujan uno encima del otro a ancho completo y el de arriba se come
los toques del de abajo (`horario.dart:276-277`, `left`/`right` fijos por vista). Esta
funcionalidad lo arregla, porque sus bloques **van a chocar a propósito** con las clases.

El cálculo del reparto es una función pura —dado un conjunto de bloques con inicio y fin,
devuelve para cada uno su columna y cuántas columnas hay— al estilo de `blockGeometry` y
`blockMetaLines`, con pruebas de dos y tres simultáneos, de uno contenido en otro y de dos
que solo se tocan en el borde.

**El domingo.** La vista semanal horizontal hoy llega hasta el sábado
(`horario.dart:153-160`), aunque el backend manda domingo y la vista de día sí lo muestra.
Un bloque de domingo se vería en una vista y desaparecería en la otra, así que la semanal
pasa a incluirlo.

`[@test] ../../../test/HU35_jeff/time_blocks_grilla_test.dart`

### RF-BLQ-5 — Tocar un bloque propio

Tocar un bloque propio abre una hoja con cuatro acciones:

- **Editar el bloque** (todas las semanas): abre el formulario de RF-BLQ-2.
- **Cancelar solo este día**.
- **Cambiar la hora solo este día**.
- **Borrar el bloque**, con confirmación que dice que se borra el bloque y todos sus días.

Tocar una clase sigue llevando al detalle del curso, como hoy. El bloque propio necesita su
propia rama en el `onTap` de `_courseBlock`, junto a las que ya existen para asesorías y
evaluaciones: hoy cualquier bloque con sección navega al detalle del curso
(`horario.dart:441`), y un bloque propio no tiene curso al que ir.

Una excepción se puede deshacer desde el mismo día: si el día está cancelado o movido, la
hoja ofrece **volver al patrón**.

`[@test] ../../../test/HU35_jeff/time_blocks_acciones_test.dart`

### RF-BLQ-6 — Las horas de la semana

En la pantalla de horario, una línea discreta con las horas que los bloques propios ocupan
en la semana del día que se está viendo —la semana de lunes a domingo que contiene el día
activo de la vista—: "Tus bloques: 12 h esta semana". El número lo calcula el
servidor (RS-BE-34) y la app lo muestra; **no se recalcula en el cliente**, para que no
haya dos cuentas que puedan diferir.

Si el alumno no tiene bloques, la línea no aparece. Si el número viene `null`, tampoco: no
se pinta un 0.

`[@test] ../../../test/HU35_jeff/time_blocks_horas_test.dart`

### RF-BLQ-7 — Capa de datos tipada

Un `TimeBlocksService` (`GetxService` permanente, como `MallaService`) y un modelo tipado
para los bloques y sus ocurrencias, con `fromJson` que conserva `null` y no inventa ceros.
El service es el único que habla HTTP; ningún widget lee JSON.

La pantalla de horario hoy llama a `ApiClient` directo desde el controlador y pide el
horario dos veces (`horario_controller.dart:101-103` y `:136-138`). Esta funcionalidad
**no** reescribe eso: agrega su propia capa tipada y deja el horario como está, salvo lo
que RF-BLQ-4 y RF-BLQ-5 obligan a tocar.

Los bloques se guardan en una lista propia del controlador, **nunca** mezclados con
`_todasLasSecciones`: ese arreglo alimenta el reparto de colores de los cursos y el marcado
de evaluaciones, y un bloque propio ahí dentro le robaría color a un curso real.

La ventana que la app pide es la del ciclo visible; si no hay ciclo con fechas, las cuatro
semanas alrededor de hoy.

`[@test] ../../../test/HU35_jeff/time_blocks_service_test.dart`

## Contrato que se consume

`GET`, `POST`, `PATCH`, `DELETE /time-blocks/me`, `PUT` y `DELETE` de una ocurrencia, y
`GET /time-blocks/me/occurrences?from=&to=`. Las horas llegan como `"HH:MM"` y las fechas
como `"YYYY-MM-DD"`, en hora de Lima. El detalle está en la spec del backend.

## Qué NO entra

- Repeticiones más ricas que "estos días de la semana".
- Recordatorios, notificaciones o compartir bloques.
- Bloques fuera de 7 am–10 pm: el formulario no los deja y el servidor los rechaza.
- Reescribir la pantalla de horario: se toca lo que el reparto en columnas, el domingo y el
  toque de un bloque propio obligan, y nada más.
- Mostrar las horas de las clases en la suma: solo cuentan los bloques propios.

## Decisiones

Las siete decisiones del dueño están en la tabla de la spec del backend. Las que mandan
sobre esta pantalla: el reparto lado a lado en vez de taparse o pintar semitransparente; el
aviso de choque que no impide guardar; y la grilla que se queda en 7 am–10 pm.
