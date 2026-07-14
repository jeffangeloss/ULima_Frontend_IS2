// test/silabo_viewer_zoom_test.dart
// Ampliación HU21 (issue #106): zoom y compartir del visor de sílabos.
// Parte 1 — calcularMatrizZoom (función PURA de matrices): escala compuesta
// anclada al punto pedido, límites 1x..5x y corrección de encuadre.
// Parte 2 — tests de widget de la ampliación: pill de zoom visible, botón de
// compartir deshabilitado en carga / oculto en error / compartiendo con el
// nombre presentable del curso (sin canales nativos de pdfx: el
// PdfControllerPinch inyectado usa un document que nunca completa).

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pdfx/pdfx.dart';
import 'package:share_plus/share_plus.dart';
import 'package:ulima_plus/domain/silabo/silabo_link.dart';
import 'package:ulima_plus/pages/silabo/silabo_viewer_controller.dart';
import 'package:ulima_plus/pages/silabo/silabo_viewer_page.dart';
import 'package:ulima_plus/services/silabo_service.dart';

void main() {
  const viewport = Size(400, 600);
  final centro = viewport.center(Offset.zero);

  double escalaDe(Matrix4 m) => m.row0[0];
  Offset traslacionDe(Matrix4 m) => Offset(m.row0[3], m.row1[3]);

  group('calcularMatrizZoom', () {
    test('acercar desde 1x aplica el factor anclado al centro del viewport',
        () {
      final destino = SilaboViewerController.calcularMatrizZoom(
        actual: Matrix4.identity(),
        factor: 1.4,
        centro: centro,
        viewport: viewport,
      );

      expect(escalaDe(destino), closeTo(1.4, 1e-9));
      // T(c)·S(f)·T(-c) sobre identidad → traslación = c·(1-f).
      expect(traslacionDe(destino).dx, closeTo(centro.dx * (1 - 1.4), 1e-9));
      expect(traslacionDe(destino).dy, closeTo(centro.dy * (1 - 1.4), 1e-9));
    });

    test('el punto del documento bajo el ancla no se mueve al hacer zoom', () {
      // Estado arbitrario: 2x con desplazamiento (-100, -50).
      final actual = Matrix4.identity()
        ..translateByDouble(-100, -50, 0, 1)
        ..scaleByDouble(2, 2, 1, 1);
      final ancla = const Offset(200, 300);
      // Punto del documento actualmente visible bajo el ancla.
      final puntoDoc = Offset(
        (ancla.dx + 100) / 2,
        (ancla.dy + 50) / 2,
      );

      final destino = SilaboViewerController.calcularMatrizZoom(
        actual: actual,
        factor: 1.4,
        centro: ancla,
        viewport: viewport,
      );

      final proyectado = MatrixUtils.transformPoint(destino, puntoDoc);
      expect(proyectado.dx, closeTo(ancla.dx, 1e-6));
      expect(proyectado.dy, closeTo(ancla.dy, 1e-6));
      expect(escalaDe(destino), closeTo(2.8, 1e-9));
    });

    test('no pasa del máximo (5x)', () {
      final actual = Matrix4.identity()..scaleByDouble(4, 4, 1, 1);

      final destino = SilaboViewerController.calcularMatrizZoom(
        actual: actual,
        factor: 2, // 4 × 2 = 8 → clamp a 5
        centro: centro,
        viewport: viewport,
      );

      expect(escalaDe(destino), closeTo(SilaboViewerController.zoomMaximo, 1e-9));
    });

    test('no baja del mínimo (1x = ajuste de ancho)', () {
      final actual = Matrix4.identity()..scaleByDouble(1.2, 1.2, 1, 1);

      final destino = SilaboViewerController.calcularMatrizZoom(
        actual: actual,
        factor: 1 / 1.4, // 1.2 / 1.4 ≈ 0.86 → clamp a 1
        centro: centro,
        viewport: viewport,
      );

      expect(escalaDe(destino), closeTo(SilaboViewerController.zoomMinimo, 1e-9));
    });

    test('con factor neutro devuelve la misma transformación', () {
      final actual = Matrix4.identity()
        ..translateByDouble(-30, -200, 0, 1)
        ..scaleByDouble(2, 2, 1, 1);

      final destino = SilaboViewerController.calcularMatrizZoom(
        actual: actual,
        factor: 1,
        centro: centro,
        viewport: viewport,
      );

      expect(escalaDe(destino), closeTo(2, 1e-9));
      expect(traslacionDe(destino).dx, closeTo(-30, 1e-9));
      expect(traslacionDe(destino).dy, closeTo(-200, 1e-9));
    });

    test('al alejar cerca del borde corrige el encuadre (sin bandas vacías)',
        () {
      // 2x desplazado; documento de 400×800 a escala 1.
      final actual = Matrix4.identity()
        ..translateByDouble(-100, -500, 0, 1)
        ..scaleByDouble(2, 2, 1, 1);

      final destino = SilaboViewerController.calcularMatrizZoom(
        actual: actual,
        factor: 0.5, // vuelve a 1x
        centro: centro,
        viewport: viewport,
        documento: const Size(400, 800),
      );

      expect(escalaDe(destino), closeTo(1, 1e-9));
      final t = traslacionDe(destino);
      // Sin corrección la x quedaría en +50 (banda vacía a la izquierda).
      expect(t.dx, 0);
      // La y queda dentro del rango válido [600-800, 0].
      expect(t.dy, greaterThanOrEqualTo(-200));
      expect(t.dy, lessThanOrEqualTo(0));
    });

    test('documento más corto que el viewport queda alineado arriba', () {
      final actual = Matrix4.identity()
        ..translateByDouble(0, -50, 0, 1);

      final destino = SilaboViewerController.calcularMatrizZoom(
        actual: actual,
        factor: 1,
        centro: centro,
        viewport: viewport,
        documento: const Size(400, 300), // más corto que 600 de alto
      );

      expect(traslacionDe(destino).dy, 0);
    });
  });

  _testsWidgetAmpliacion();
}

// ── Parte 2: tests de widget de la ampliación ─────────────────────────────────

class _ServicioFalso extends SilaboService {
  _ServicioFalso(this._resultado);
  final Future<Uint8List> Function() _resultado;

  @override
  Future<Uint8List> obtenerPdf(
    SilaboLink link, {
    bool forzarDescarga = false,
  }) =>
      _resultado();

  @override
  Future<File> prepararCompartible(String titulo, Uint8List bytes) {
    // Sin I/O real: en el entorno FakeAsync de testWidgets la escritura a
    // disco no completa. Para el contrato del test basta la ruta con el
    // nombre presentable (XFile no lee el archivo con el share inyectado).
    final nombre = SilaboService.nombreArchivoPresentable(titulo);
    return Future.value(File('${Directory.systemTemp.path}/$nombre.pdf'));
  }
}

final Uint8List _bytesPdfValidos =
    Uint8List.fromList('%PDF-1.4\n1 0 obj\n<<>>\nendobj\n%%EOF'.codeUnits);

/// Monta la app, navega a '/silabo' con los argumentos reales del call-site
/// y bombea la transición (sin pumpAndSettle: hay animaciones infinitas).
Future<void> _abrirVisor(
  WidgetTester tester,
  SilaboService service, {
  CompartirArchivos? compartir,
}) async {
  await tester.pumpWidget(GetMaterialApp(
    initialRoute: '/',
    getPages: [
      GetPage(
        name: '/',
        page: () => Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => Get.toNamed<void>('/silabo', arguments: {
                'url':
                    'https://drive.google.com/file/d/1UOWW27UJ7x1Y4cRqmBUmTBuIIQZvUQXl/view',
                'titulo': 'Ingeniería de Software II',
              }),
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
      GetPage(
        name: '/silabo',
        page: () => const SilaboViewerPage(),
        binding: BindingsBuilder(() {
          Get.lazyPut(() => SilaboViewerController(
                service: service,
                compartirArchivos: compartir,
                crearPdfController: (_) => PdfControllerPinch(
                  document: Completer<PdfDocument>().future,
                ),
              ));
        }),
      ),
    ],
  ));
  await tester.tap(find.text('abrir'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void _testsWidgetAmpliacion() {
  tearDown(Get.reset);

  Finder botonCompartir() => find.ancestor(
        of: find.byTooltip('Descargar sílabo'),
        matching: find.byType(IconButton),
      );

  testWidgets('botón de compartir deshabilitado mientras el PDF carga',
      (tester) async {
    final service = _ServicioFalso(() => Completer<Uint8List>().future);
    await _abrirVisor(tester, service);

    final boton = tester.widget<IconButton>(botonCompartir());
    expect(boton.onPressed, isNull, reason: 'deshabilitado durante la carga');
  });

  testWidgets('botón de compartir oculto en estado de error', (tester) async {
    final service =
        _ServicioFalso(() => Future.error(const SilaboDescargaException()));
    await _abrirVisor(tester, service);
    await tester.pumpAndSettle();

    expect(find.byTooltip('Descargar sílabo'), findsNothing);
    expect(find.text('Reintentar'), findsOneWidget);
  });

  testWidgets(
      'estado listo: pill de zoom visible y compartir usa el nombre '
      'presentable del curso', (tester) async {
    ShareParams? capturado;
    final service = _ServicioFalso(() async => _bytesPdfValidos);
    await _abrirVisor(
      tester,
      service,
      compartir: (params) async {
        capturado = params;
        return const ShareResult('ok', ShareResultStatus.success);
      },
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byTooltip('Acercar'), findsOneWidget);
    expect(find.byTooltip('Alejar'), findsOneWidget);
    expect(find.byTooltip('Restablecer zoom'), findsOneWidget);

    final boton = tester.widget<IconButton>(botonCompartir());
    expect(boton.onPressed, isNotNull,
        reason: 'habilitado en estado listo (PDF cargado)');
    await tester.tap(botonCompartir());
    await tester.pump(const Duration(milliseconds: 300));

    expect(capturado, isNotNull);
    expect(capturado!.subject, 'Ingeniería de Software II');
    expect(
      capturado!.files!.single.path,
      endsWith('Ingeniería de Software II.pdf'),
    );
  });
}
