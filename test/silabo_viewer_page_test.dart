// test/silabo_viewer_page_test.dart
// HU21: estados del visor de sílabos in-app (ruta '/silabo') con un
// SilaboService falso (sin red y sin canales nativos de pdfx):
//   - skeleton mientras descarga
//   - error "no accesible" (permisos mixtos de Drive) con Reintentar +
//     fallback "Abrir en Drive"
//   - Reintentar vuelve a pedir el PDF
//   - URL que no es de Drive → error de enlace inválido

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/components/skeleton.dart';
import 'package:ulima_plus/domain/silabo/silabo_link.dart';
import 'package:ulima_plus/pages/silabo/silabo_viewer_controller.dart';
import 'package:ulima_plus/pages/silabo/silabo_viewer_page.dart';
import 'package:ulima_plus/services/silabo_service.dart';

const String _urlDrive =
    'https://drive.google.com/file/d/1UOWW27UJ7x1Y4cRqmBUmTBuIIQZvUQXl/view';

class _FakeSilaboService extends SilaboService {
  _FakeSilaboService(this._onFetch);

  final Future<Uint8List> Function() _onFetch;
  int llamadas = 0;

  @override
  Future<Uint8List> obtenerPdf(
    SilaboLink link, {
    bool forzarDescarga = false,
  }) {
    llamadas++;
    return _onFetch();
  }
}

/// App de prueba: un botón navega a '/silabo' con los argumentos reales que
/// usa el call-site del course_detail_sheet.
Widget _app(_FakeSilaboService service, {String url = _urlDrive}) {
  return GetMaterialApp(
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
          Get.lazyPut(() => SilaboViewerController(service: service));
        }),
      ),
    ],
  );
}

void main() {
  tearDown(Get.reset);

  testWidgets('muestra skeleton mientras el PDF descarga', (tester) async {
    // Future que nunca completa: el visor queda en estado cargando.
    final service = _FakeSilaboService(() => Completer<Uint8List>().future);

    await tester.pumpWidget(_app(service));
    await tester.tap(find.text('abrir silabo'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(SkeletonPulse), findsOneWidget);
    expect(find.text('Ingeniería de Software II'), findsOneWidget);
    expect(service.llamadas, 1);
  });

  testWidgets(
      'sílabo no accesible (login de Drive) → mensaje + Reintentar + '
      'Abrir en Drive', (tester) async {
    final service = _FakeSilaboService(
      () => Future.error(const SilaboNoAccesibleException()),
    );

    await tester.pumpWidget(_app(service));
    await tester.tap(find.text('abrir silabo'));
    await tester.pumpAndSettle();

    expect(
      find.text('El sílabo no está disponible para verlo dentro de la app.'),
      findsOneWidget,
    );
    expect(find.text('Reintentar'), findsOneWidget);
    expect(find.text('Abrir en Drive'), findsOneWidget);
  });

  testWidgets('Reintentar vuelve a pedir el PDF al servicio', (tester) async {
    final service = _FakeSilaboService(
      () => Future.error(const SilaboDescargaException()),
    );

    await tester.pumpWidget(_app(service));
    await tester.tap(find.text('abrir silabo'));
    await tester.pumpAndSettle();
    expect(service.llamadas, 1);

    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(service.llamadas, 2);
    expect(find.text('No se pudo descargar el sílabo.'), findsOneWidget);
  });

  testWidgets('URL que no es de Drive → error de enlace con fallback',
      (tester) async {
    final service = _FakeSilaboService(
      () => fail('no debe llamar al servicio con enlace inválido'),
    );

    await tester.pumpWidget(
      _app(service, url: 'https://www.ulima.edu.pe/silabo.pdf'),
    );
    await tester.tap(find.text('abrir silabo'));
    await tester.pumpAndSettle();

    expect(
      find.text('El enlace del sílabo no es válido para verlo dentro de la app.'),
      findsOneWidget,
    );
    expect(find.text('Abrir en Drive'), findsOneWidget);
    expect(service.llamadas, 0);
  });
}
