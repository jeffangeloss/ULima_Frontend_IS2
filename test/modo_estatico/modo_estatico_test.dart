// test/modo_estatico/modo_estatico_test.dart
//
// UNITARIA + WIDGET · Versión estática del front (specs/features/
// modo-estatico/modo-estatico.spec.md).
// RF-EST-7 (un único punto de lectura), RF-EST-11 (las rutas ocultas llevan
// al inicio) y RF-EST-13 (con el modo apagado nada cambia).
// Archivos probados lib/configs/modo_estatico.dart y lib/main.dart.

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/configs/modo_estatico.dart';
import 'package:ulima_plus/main.dart' show paginasDeLaApp;

/// Lo primero que corre en este isolate, antes de que ninguna prueba toque el
/// interruptor.
final bool _valorInicial = ModoEstatico.activo;

/// Una app mínima con la pantalla [ruta] tal como la declara `main.dart`
/// (mismo nombre y mismos middlewares) y un inicio de mentira.
Widget _app(String ruta) {
  final real = paginasDeLaApp.firstWhere((p) => p.name == ruta);
  return GetMaterialApp(
    initialRoute: '/home',
    getPages: <GetPage<dynamic>>[
      GetPage(name: '/home', page: () => const Text('INICIO')),
      GetPage(
        name: ruta,
        page: () => const Text('PANTALLA OCULTA'),
        middlewares: real.middlewares,
      ),
    ],
  );
}

void main() {
  setUp(() {
    Get.testMode = true;
    Get.reset();
  });
  tearDown(() {
    ModoEstatico.activo = false;
    Get.reset();
  });

  group('RF-EST-7 · un único punto de lectura', () {
    test('sin --dart-define el modo viene apagado', () {
      expect(_valorInicial, isFalse);
    });

    test('las pruebas lo fijan en cada caso', () {
      ModoEstatico.activo = true;
      expect(ModoEstatico.activo, isTrue);
      ModoEstatico.activo = false;
      expect(ModoEstatico.activo, isFalse);
    });

    test('ningún otro archivo de lib lee MODO_ESTATICO', () {
      final lectores = <String>[
        for (final f in Directory('lib').listSync(recursive: true))
          if (f is File &&
              f.path.endsWith('.dart') &&
              f.readAsStringSync().contains("fromEnvironment('MODO_ESTATICO'"))
            f.path,
      ];
      expect(lectores, <String>['lib/configs/modo_estatico.dart']);
    });
  });

  group('RF-EST-11 · rutas ocultas', () {
    test('son /portal-sync, /mi-record y /mis-notas', () {
      expect(ModoEstatico.rutasOcultas, <String>[
        '/portal-sync',
        '/mi-record',
        '/mis-notas',
      ]);
    });

    test('main.dart les pone el middleware y no se lo pone a las demás', () {
      for (final p in paginasDeLaApp) {
        final conMiddleware =
            p.middlewares?.any((m) => m is OcultaEnModoEstatico) ?? false;
        expect(
          conMiddleware,
          ModoEstatico.rutasOcultas.contains(p.name),
          reason: p.name,
        );
      }
    });

    for (final ruta in ModoEstatico.rutasOcultas) {
      testWidgets('modo estático: $ruta lleva al inicio', (tester) async {
        ModoEstatico.activo = true;
        await tester.pumpWidget(_app(ruta));
        await tester.pump();
        unawaited(Get.toNamed<void>(ruta));
        await tester.pumpAndSettle();
        expect(find.text('PANTALLA OCULTA'), findsNothing);
        expect(find.text('INICIO'), findsOneWidget);
        expect(Get.currentRoute, '/home');
      });

      testWidgets('modo apagado: $ruta abre su pantalla como en la 1.2.0', (
        tester,
      ) async {
        ModoEstatico.activo = false;
        await tester.pumpWidget(_app(ruta));
        await tester.pump();
        unawaited(Get.toNamed<void>(ruta));
        await tester.pumpAndSettle();
        expect(find.text('PANTALLA OCULTA'), findsOneWidget);
        expect(Get.currentRoute, ruta);
      });
    }
  });
}
