// test/modo_estatico/silabo_estatico_test.dart
//
// WIDGET · Versión estática del front (specs/features/modo-estatico/
// modo-estatico.spec.md), RF-EST-12 y RF-EST-13.
// En modo estático el visor de sílabos abre solo enlaces de Drive. Ante una
// URL que no es de Drive, como las de cactus que guardó la importación, dice
// «Sílabo no disponible» y no abre el navegador. Con el modo apagado, el
// visor es el de la 1.2.0.
// Archivos probados lib/pages/silabo/silabo_viewer_controller.dart y
// lib/pages/silabo/silabo_viewer_page.dart.

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/configs/modo_estatico.dart';
import 'package:ulima_plus/domain/silabo/silabo_link.dart';
import 'package:ulima_plus/pages/silabo/silabo_viewer_controller.dart';
import 'package:ulima_plus/pages/silabo/silabo_viewer_page.dart';
import 'package:ulima_plus/services/silabo_service.dart';

const String _urlDrive =
    'https://drive.google.com/file/d/1UOWW27UJ7x1Y4cRqmBUmTBuIIQZvUQXl/view';
const String _urlCactus =
    'https://cactus.ulima.edu.pe/ac/ac_bd001.nsf/vSyllabusXCicloAV/'
    'ABC123/\$File/silabo-de-prueba.pdf';

class _ServicioFalso extends SilaboService {
  _ServicioFalso(this._respuesta);

  final Future<Uint8List> Function() _respuesta;
  int llamadas = 0;

  @override
  Future<Uint8List> obtenerPdf(
    SilaboLink link, {
    bool forzarDescarga = false,
  }) {
    llamadas++;
    return _respuesta();
  }
}

Widget _app(_ServicioFalso servicio, String url) => GetMaterialApp(
  initialRoute: '/',
  getPages: [
    GetPage(
      name: '/',
      page: () => Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => Get.toNamed<void>(
              '/silabo',
              arguments: {'url': url, 'titulo': 'Ingeniería de Software II'},
            ),
            child: const Text('abrir silabo'),
          ),
        ),
      ),
    ),
    GetPage(
      name: '/silabo',
      page: () => const SilaboViewerPage(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => SilaboViewerController(service: servicio));
      }),
    ),
  ],
);

/// Anota cada llamada al canal de `url_launcher`.
List<MethodCall> _espiarElNavegador() {
  final llamadas = <MethodCall>[];
  const canal = MethodChannel('plugins.flutter.io/url_launcher');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(canal, (llamada) async {
        llamadas.add(llamada);
        return true;
      });
  addTearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(canal, null),
  );
  return llamadas;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(Get.reset);
  tearDown(() {
    ModoEstatico.activo = false;
    Get.reset();
  });

  group('RF-EST-12 · la URL no es de Drive', () {
    testWidgets('modo estático: «Sílabo no disponible», sin botones y sin '
        'abrir el navegador', (tester) async {
      ModoEstatico.activo = true;
      final navegador = _espiarElNavegador();
      final servicio = _ServicioFalso(
        () => fail('no debe pedir el PDF con un enlace que no es de Drive'),
      );
      await tester.pumpWidget(_app(servicio, _urlCactus));
      await tester.tap(find.text('abrir silabo'));
      await tester.pumpAndSettle();

      expect(find.text('Sílabo no disponible'), findsOneWidget);
      expect(find.text('Abrir en Drive'), findsNothing);
      expect(find.text('Reintentar'), findsNothing);
      expect(servicio.llamadas, 0);

      await Get.find<SilaboViewerController>().abrirEnDrive();
      expect(navegador, isEmpty);
    });

    testWidgets('modo estático: sin URL tampoco hay navegador', (tester) async {
      ModoEstatico.activo = true;
      final navegador = _espiarElNavegador();
      final servicio = _ServicioFalso(() => fail('sin PDF'));
      await tester.pumpWidget(_app(servicio, ''));
      await tester.tap(find.text('abrir silabo'));
      await tester.pumpAndSettle();
      expect(find.text('Sílabo no disponible'), findsOneWidget);
      await Get.find<SilaboViewerController>().abrirEnDrive();
      expect(navegador, isEmpty);
    });

    testWidgets('modo apagado: el aviso y el respaldo de la 1.2.0, que abre '
        'la URL cruda', (tester) async {
      final navegador = _espiarElNavegador();
      final servicio = _ServicioFalso(() => fail('sin PDF'));
      await tester.pumpWidget(_app(servicio, _urlCactus));
      await tester.tap(find.text('abrir silabo'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'El enlace del sílabo no es válido para verlo dentro de la app.',
        ),
        findsOneWidget,
      );
      expect(find.text('Sílabo no disponible'), findsNothing);
      expect(find.text('Abrir en Drive'), findsOneWidget);
      await Get.find<SilaboViewerController>().abrirEnDrive();
      expect(navegador, hasLength(1));
      expect(
        (navegador.single.arguments as Map<Object?, Object?>)['url'],
        _urlCactus,
      );
    });
  });

  group('RF-EST-12 · la URL es de Drive', () {
    testWidgets('modo estático: sigue pidiendo el PDF', (tester) async {
      ModoEstatico.activo = true;
      final servicio = _ServicioFalso(() => Completer<Uint8List>().future);
      await tester.pumpWidget(_app(servicio, _urlDrive));
      await tester.tap(find.text('abrir silabo'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(servicio.llamadas, 1);
      expect(find.text('Sílabo no disponible'), findsNothing);
    });

    testWidgets('modo estático: con un fallo de descarga, el respaldo abre '
        'la vista de Drive', (tester) async {
      ModoEstatico.activo = true;
      final navegador = _espiarElNavegador();
      final servicio = _ServicioFalso(
        () => Future.error(const SilaboDescargaException()),
      );
      await tester.pumpWidget(_app(servicio, _urlDrive));
      await tester.tap(find.text('abrir silabo'));
      await tester.pumpAndSettle();
      expect(find.text('Abrir en Drive'), findsOneWidget);
      await Get.find<SilaboViewerController>().abrirEnDrive();
      expect(navegador, hasLength(1));
      expect(
        (navegador.single.arguments as Map<Object?, Object?>)['url'],
        'https://drive.google.com/file/d/1UOWW27UJ7x1Y4cRqmBUmTBuIIQZvUQXl/view',
      );
    });
  });
}
