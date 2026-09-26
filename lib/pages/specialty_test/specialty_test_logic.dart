// lib/pages/specialty_test/specialty_test_logic.dart
// Funciones puras del test de especialidad (HU36). Ninguna toca la red, GetX
// ni el árbol de widgets, así que se prueban solas
// (test/HU36_jeff/specialty_test_logic_test.dart y
// test/HU36_jeff/specialty_test_contraste_test.dart).

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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

// ── Íconos de las tareas y de las especialidades (RF-TEST-5, decisión 8) ────

/// El ícono de un nombre fuera del mapa o ausente. No es de ninguna
/// especialidad ni de ninguna tarea, así que no delata nada.
const IconData kIconoNeutro = LucideIcons.sparkles;

/// Mapa cerrado de los 52 nombres de Lucide de la versión 2026-09-25.4 a sus
/// constantes de `lucide_icons_flutter` 3.1.15, cada una con el camelCase de
/// su nombre. La app nunca arma un `IconData` con un punto de código que
/// llegue del servidor, porque el build de release recorta la fuente a las
/// constantes que nombra el código. Un nombre nuevo sale neutro hasta el
/// siguiente APK.
const Map<String, IconData> kIconosDelTest = <String, IconData>{
  // Las cuatro especialidades.
  'code-xml': LucideIcons.codeXml,
  'server-cog': LucideIcons.serverCog,
  'chart-column-big': LucideIcons.chartColumnBig,
  'gamepad-2': LucideIcons.gamepad2,
  // Las 48 tareas, 24 de las preguntas y 24 de los desempates.
  'shopping-cart': LucideIcons.shoppingCart,
  'shelving-unit': LucideIcons.shelvingUnit,
  'refrigerator': LucideIcons.refrigerator,
  'mountain': LucideIcons.mountain,
  'eye': LucideIcons.eye,
  'store': LucideIcons.store,
  'drumstick': LucideIcons.drumstick,
  'rabbit': LucideIcons.rabbit,
  'camera': LucideIcons.camera,
  'folder-search': LucideIcons.folderSearch,
  'school': LucideIcons.school,
  'drafting-compass': LucideIcons.draftingCompass,
  'rocket': LucideIcons.rocket,
  'smartphone': LucideIcons.smartphone,
  'hand-coins': LucideIcons.handCoins,
  'clipboard-pen-line': LucideIcons.clipboardPenLine,
  'ticket': LucideIcons.ticket,
  'clock-arrow-up': LucideIcons.clockArrowUp,
  'route': LucideIcons.route,
  'messages-square': LucideIcons.messagesSquare,
  'user-minus': LucideIcons.userMinus,
  'pencil': LucideIcons.pencil,
  'footprints': LucideIcons.footprints,
  'bus': LucideIcons.bus,
  'calendar-clock': LucideIcons.calendarClock,
  'hospital': LucideIcons.hospital,
  'key-round': LucideIcons.keyRound,
  'receipt': LucideIcons.receipt,
  'blocks': LucideIcons.blocks,
  'goal': LucideIcons.goal,
  'database': LucideIcons.database,
  'rocking-chair': LucideIcons.rockingChair,
  'land-plot': LucideIcons.landPlot,
  'dices': LucideIcons.dices,
  'ghost': LucideIcons.ghost,
  'headphones': LucideIcons.headphones,
  'siren': LucideIcons.siren,
  'badge-percent': LucideIcons.badgePercent,
  'stamp': LucideIcons.stamp,
  'graduation-cap': LucideIcons.graduationCap,
  'house-wifi': LucideIcons.houseWifi,
  'drama': LucideIcons.drama,
  'droplet': LucideIcons.droplet,
  'radio-tower': LucideIcons.radioTower,
  'soup': LucideIcons.soup,
  'map-pinned': LucideIcons.mapPinned,
  'split': LucideIcons.split,
  'pill-bottle': LucideIcons.pillBottle,
};

/// El ícono de [nombre], o [kIconoNeutro] si no está en el mapa o es null.
IconData iconoDelTest(String? nombre) => kIconosDelTest[nombre] ?? kIconoNeutro;
