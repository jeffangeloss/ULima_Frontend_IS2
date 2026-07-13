import 'package:flutter/material.dart';

/// Paleta de acentos por curso/sección para las vistas del DOCENTE (Calificar),
/// donde el backend no envía un color por curso (a diferencia del horario del
/// alumno, que trae el hex del `schedule_session`). Es determinística por `seed`
/// (p. ej. `sectionId`) para que cada sección conserve SIEMPRE el mismo color, en
/// la misma línea colorida que el horario.
const List<Color> kCoursePalette = [
  Color(0xFF2F80ED), // azul
  Color(0xFF27AE60), // verde
  Color(0xFFEB5757), // rojo
  Color(0xFF9B51E0), // morado
  Color(0xFFEC4899), // rosa
  Color(0xFFF2994A), // naranja
  Color(0xFF00B8A9), // teal
  Color(0xFFF2C94C), // amarillo
];

/// Color estable para una sección/curso a partir de un `seed` (usar `sectionId`).
Color courseAccentColor(int seed) =>
    kCoursePalette[seed.abs() % kCoursePalette.length];
