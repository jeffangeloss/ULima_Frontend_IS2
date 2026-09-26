// lib/pages/specialty_test/specialty_test_logic.dart
// Funciones puras del test de especialidad (HU36). Ninguna toca la red, GetX
// ni el árbol de widgets, así que se prueban solas
// (test/HU36_jeff/specialty_test_logic_test.dart y
// test/HU36_jeff/specialty_test_contraste_test.dart).

import 'package:flutter/material.dart';

import '../../models/specialty_test_models.dart';

// ── Color y contraste (RF-TEST-12) ────────────────────────────────────────────

/// Mínimo WCAG de un texto contra su fondo.
const double kContrasteTexto = 4.5;

/// Mínimo WCAG de un ícono que da información.
const double kContrasteIcono = 3.0;

/// Razón de contraste WCAG 2.x entre dos colores opacos, de 1 a 21.
double razonDeContraste(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final claro = la > lb ? la : lb;
  final oscuro = la > lb ? lb : la;
  return (claro + 0.05) / (oscuro + 0.05);
}

final RegExp _hex = RegExp(r'^#([0-9a-fA-F]{6})$');

/// El color de un hex `#RRGGBB`, o null si no se puede leer. Un null cuenta
/// como neutro y no invalida el contenido (RF-TEST-2).
Color? colorDeHex(String? hex) {
  final m = _hex.firstMatch(hex?.trim() ?? '');
  if (m == null) return null;
  return Color(0xFF000000 | int.parse(m.group(1)!, radix: 16));
}

/// El color de una especialidad en el tema, `color.light` o `color.dark`.
Color? colorDeEspecialidad(TestSpecialty? especialidad, Brightness brillo) {
  if (especialidad == null) return null;
  return colorDeHex(
    brillo == Brightness.light
        ? especialidad.colorLight
        : especialidad.colorDark,
  );
}

/// [color] al [alfa] sobre [fondo], ya opaco y redondeado a 8 bits por canal,
/// como lo pinta la pantalla. Así se miden la tarjeta encendida (12 %), la del
/// resultado en oscuro (18 %) y la insignia «IA».
Color tinte(Color color, Color fondo, double alfa) {
  int canal(double c, double f) => ((c * alfa + f * (1 - alfa)) * 255).round();
  return Color.fromARGB(
    255,
    canal(color.r, fondo.r),
    canal(color.g, fondo.g),
    canal(color.b, fondo.b),
  );
}

/// [color] un 20 % más oscuro, el extremo inferior del degradado de la
/// tarjeta de la ganadora en claro (RF-TEST-8).
Color oscurecido(Color color) => tinte(Colors.black, color, 0.2);

/// La guarda de RF-TEST-12. Devuelve [color] si llega al mínimo contra
/// [fondo] (4,5:1 como texto, 3:1 como ícono), o [respaldo] si no llega o si
/// es null. El contenido puede cambiar sin otro APK, así que la app no confía
/// a ciegas en sus colores.
Color colorQueSeLee(
  Color? color, {
  required Color fondo,
  required Color respaldo,
  bool esTexto = true,
}) {
  if (color == null) return respaldo;
  final minimo = esTexto ? kContrasteTexto : kContrasteIcono;
  return razonDeContraste(color, fondo) >= minimo ? color : respaldo;
}
