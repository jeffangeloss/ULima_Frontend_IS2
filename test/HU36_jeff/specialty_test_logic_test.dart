// test/HU36_jeff/specialty_test_logic_test.dart
//
// Pruebas unitarias de HU36, el test de especialidad, sobre las funciones
// puras de lib/pages/specialty_test/specialty_test_logic.dart, que son el mapa
// de íconos (RF-TEST-5), las líneas de Ulises, el sello, el historial y el
// cuerpo de la evaluación (RF-TEST-4) y la selección oficial, los corazones
// (RF-TEST-9 y RF-TEST-14) y la fecha en Lima (RF-TEST-10).
//
// Datos inventados (datos_de_prueba.dart).

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ulima_plus/pages/specialty_test/specialty_test_logic.dart';

void main() {
  _iconos();
}

void _iconos() {
  group('UNITARIA · Mapa de íconos (RF-TEST-5, decisión 8)', () {
    // Los 52 nombres de la versión 2026-09-25.4 con la constante que da su
    // camelCase. Es la misma lista que el mapa de la app, escrita aparte para
    // que un nombre cambiado de constante se note.
    const esperado = <String, IconData>{
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

    test('caso 1: el mapa trae los 52 nombres y ningún otro', () {
      expect(kIconosDelTest.length, 52);
      expect(kIconosDelTest.keys.toSet(), esperado.keys.toSet());
      for (final nombre in esperado.keys) {
        expect(kIconosDelTest[nombre], esperado[nombre], reason: nombre);
      }
    });

    test('caso 2: cada nombre da un ícono distinto y ninguno es el neutro', () {
      final puntos = kIconosDelTest.values.map((i) => i.codePoint).toSet();
      expect(puntos, hasLength(52));
      expect(puntos, isNot(contains(kIconoNeutro.codePoint)));
      expect(kIconoNeutro, LucideIcons.sparkles);
    });

    test('caso 3: un nombre fuera del mapa o ausente cae al neutro', () {
      expect(iconoDelTest('shopping-cart'), LucideIcons.shoppingCart);
      expect(iconoDelTest('gamepad-2'), LucideIcons.gamepad2);
      expect(iconoDelTest('icono-que-no-existe'), LucideIcons.sparkles);
      expect(iconoDelTest('ShoppingCart'), LucideIcons.sparkles);
      expect(iconoDelTest(''), LucideIcons.sparkles);
      expect(iconoDelTest(null), LucideIcons.sparkles);
    });
  });
}
