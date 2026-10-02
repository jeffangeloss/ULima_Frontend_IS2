// test/aviso_version/aviso_version_dialog_test.dart
//
// WIDGET · Aviso de versión nueva (specs/features/aviso-version/aviso-version.spec.md).
// RF-AVV-3 fija el título, el texto y los dos botones del diálogo, RF-AVV-4 que
// «Más tarde» guarda la versión publicada y cierra, y RF-AVV-5 que «Descargar»
// abre la URL del APK en una aplicación externa, cierra y no guarda nada.
// Archivo probado lib/components/aviso_version/aviso_version_dialog.dart.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ulima_plus/components/aviso_version/aviso_version_dialog.dart';
import 'package:ulima_plus/models/version_publicada_model.dart';

const String _apk =
    'https://github.com/meltiruiz/ULima_Frontend_IS2/releases/download/'
    'v1.2.0/ULimaPlus-build-78.apk';

final VersionPublicada _publicada = VersionPublicada(
  version: '1.2.0',
  build: 78,
  url: Uri.parse(_apk),
);

/// Lo que el diálogo le pide a quien lo abre, anotado.
class _Anfitrion {
  final List<String> pospuestas = <String>[];
  final List<Uri> abiertas = <Uri>[];
  late Future<void> cierre;

  Future<void> alPosponer(String version) async => pospuestas.add(version);

  Future<bool> abrir(Uri url) async {
    abiertas.add(url);
    return true;
  }
}

/// Monta una pantalla vacía y abre el diálogo encima.
Future<void> _mostrar(
  WidgetTester tester,
  _Anfitrion anfitrion, {
  VersionPublicada? publicada,
  String instalada = '1.1.0',
  Future<void> Function(String version)? alPosponer,
  Future<bool> Function(Uri url)? abrir,
  bool conAbrirDelAnfitrion = true,
}) async {
  await tester.pumpWidget(
    const MaterialApp(home: Scaffold(body: SizedBox.expand())),
  );
  anfitrion.cierre = mostrarAvisoVersion(
    tester.element(find.byType(Scaffold)),
    publicada: publicada ?? _publicada,
    instalada: instalada,
    alPosponer: alPosponer ?? anfitrion.alPosponer,
    abrir: conAbrirDelAnfitrion ? (abrir ?? anfitrion.abrir) : null,
  );
  await tester.pumpAndSettle();
}

Finder get _dialogo => find.byType(AlertDialog);

Finder _boton(String texto) => find.descendant(
  of: _dialogo,
  matching: find.widgetWithText(TextButton, texto),
);

void main() {
  group('el diálogo (RF-AVV-3)', () {
    testWidgets('lleva el título, el texto y los dos botones exactos', (
      tester,
    ) async {
      await _mostrar(tester, _Anfitrion());
      expect(_dialogo, findsOneWidget);
      expect(
        find.descendant(
          of: _dialogo,
          matching: find.text('Hay una versión nueva'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: _dialogo,
          matching: find.text(
            'ULima++ 1.2.0 ya está disponible. Tienes la 1.1.0.',
          ),
        ),
        findsOneWidget,
      );
      expect(_boton('Más tarde'), findsOneWidget);
      expect(_boton('Descargar'), findsOneWidget);
      expect(
        find.descendant(of: _dialogo, matching: find.byType(TextButton)),
        findsNWidgets(2),
        reason: 'solo hay dos botones',
      );
    });

    testWidgets(
      'el texto lleva la versión publicada y la instalada que recibe',
      (tester) async {
        await _mostrar(
          tester,
          _Anfitrion(),
          publicada: VersionPublicada(
            version: '1.10.0',
            build: 90,
            url: Uri.parse(_apk),
          ),
          instalada: '1.9.0',
        );
        expect(
          find.text('ULima++ 1.10.0 ya está disponible. Tienes la 1.9.0.'),
          findsOneWidget,
        );
      },
    );

    testWidgets('sale encima de la pantalla y la deja montada', (tester) async {
      await _mostrar(tester, _Anfitrion());
      expect(_dialogo, findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('sin tocar nada no pospone ni abre nada', (tester) async {
      final anfitrion = _Anfitrion();
      await _mostrar(tester, anfitrion);
      expect(_dialogo, findsOneWidget);
      expect(anfitrion.pospuestas, isEmpty);
      expect(anfitrion.abiertas, isEmpty);
    });
  });

  group('«Más tarde» (RF-AVV-4)', () {
    testWidgets("llama a alPosponer('1.2.0') y cierra el diálogo", (
      tester,
    ) async {
      final anfitrion = _Anfitrion();
      await _mostrar(tester, anfitrion);
      await tester.tap(_boton('Más tarde'));
      await tester.pumpAndSettle();
      expect(anfitrion.pospuestas, <String>['1.2.0']);
      expect(_dialogo, findsNothing);
      await anfitrion.cierre;
    });

    testWidgets('no abre la descarga', (tester) async {
      final anfitrion = _Anfitrion();
      await _mostrar(tester, anfitrion);
      await tester.tap(_boton('Más tarde'));
      await tester.pumpAndSettle();
      expect(anfitrion.abiertas, isEmpty);
    });

    testWidgets(
      'si alPosponer falla, el diálogo se cierra y el error no sale',
      (tester) async {
        final anfitrion = _Anfitrion();
        await _mostrar(
          tester,
          anfitrion,
          alPosponer: (_) async => throw StateError('sin almacén'),
        );
        await tester.tap(_boton('Más tarde'));
        await tester.pumpAndSettle();
        expect(_dialogo, findsNothing);
        await anfitrion.cierre;
      },
    );
  });

  group('«Descargar» (RF-AVV-5)', () {
    testWidgets('llama a abrir con la URL del APK y cierra el diálogo', (
      tester,
    ) async {
      final anfitrion = _Anfitrion();
      await _mostrar(tester, anfitrion);
      await tester.tap(_boton('Descargar'));
      await tester.pumpAndSettle();
      expect(anfitrion.abiertas, <Uri>[Uri.parse(_apk)]);
      expect(_dialogo, findsNothing);
      await anfitrion.cierre;
    });

    testWidgets('no guarda nada, para que el aviso vuelva en el siguiente '
        'arranque', (tester) async {
      final anfitrion = _Anfitrion();
      await _mostrar(tester, anfitrion);
      await tester.tap(_boton('Descargar'));
      await tester.pumpAndSettle();
      expect(anfitrion.pospuestas, isEmpty);
    });

    testWidgets('si abrir falla o devuelve false, el diálogo se cierra y el '
        'error no sale', (tester) async {
      for (final abrir in <Future<bool> Function(Uri)>[
        (_) async => throw PlatformException(code: 'sin-aplicacion'),
        (_) async => false,
      ]) {
        final anfitrion = _Anfitrion();
        await _mostrar(tester, anfitrion, abrir: abrir);
        await tester.tap(_boton('Descargar'));
        await tester.pumpAndSettle();
        expect(_dialogo, findsNothing);
        await anfitrion.cierre;
      }
    });

    testWidgets('sin abrir propio, usa url_launcher en modo aplicación '
        'externa', (tester) async {
      final llamadas = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/url_launcher'),
            (llamada) async {
              llamadas.add(llamada);
              return true;
            },
          );
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
              const MethodChannel('plugins.flutter.io/url_launcher'),
              null,
            ),
      );
      final anfitrion = _Anfitrion();
      await _mostrar(tester, anfitrion, conAbrirDelAnfitrion: false);
      await tester.tap(_boton('Descargar'));
      await tester.pumpAndSettle();
      await anfitrion.cierre;

      expect(llamadas, hasLength(1));
      expect(llamadas.single.method, 'launch');
      final argumentos = llamadas.single.arguments as Map<Object?, Object?>;
      expect(argumentos['url'], _apk);
      // Aplicación externa: ni la vista web de la app ni el modo por defecto,
      // que con una URL https abriría una vista web dentro de ella.
      expect(argumentos['useWebView'], isFalse);
      expect(argumentos['useSafariVC'], isFalse);
      expect(argumentos['universalLinksOnly'], isFalse);
    });
  });

  group('cerrar sin elegir', () {
    testWidgets(
      'un toque fuera del diálogo lo cierra sin guardar ni abrir nada',
      (tester) async {
        final anfitrion = _Anfitrion();
        await _mostrar(tester, anfitrion);
        expect(_dialogo, findsOneWidget);
        await tester.tapAt(const Offset(4, 4));
        await tester.pumpAndSettle();
        expect(_dialogo, findsNothing);
        expect(anfitrion.pospuestas, isEmpty);
        expect(anfitrion.abiertas, isEmpty);
        await anfitrion.cierre;
      },
    );

    testWidgets('el botón atrás lo cierra sin guardar ni abrir nada', (
      tester,
    ) async {
      final anfitrion = _Anfitrion();
      await _mostrar(tester, anfitrion);
      expect(_dialogo, findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(_dialogo, findsNothing);
      expect(anfitrion.pospuestas, isEmpty);
      expect(anfitrion.abiertas, isEmpty);
      await anfitrion.cierre;
    });
  });

  group('el futuro de mostrarAvisoVersion', () {
    testWidgets('termina cuando la acción elegida termina', (tester) async {
      final anfitrion = _Anfitrion();
      final terminaAbrir = Completer<bool>();
      await _mostrar(tester, anfitrion, abrir: (_) => terminaAbrir.future);
      var termino = false;
      unawaited(anfitrion.cierre.then((_) => termino = true));
      await tester.tap(_boton('Descargar'));
      await tester.pumpAndSettle();
      expect(termino, isFalse);
      terminaAbrir.complete(true);
      await tester.pumpAndSettle();
      expect(termino, isTrue);
    });
  });
}
