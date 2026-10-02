// test/modo_estatico/ficha_y_calculadora_estaticas_test.dart
//
// WIDGET · Versión estática del front (specs/features/modo-estatico/
// modo-estatico.spec.md), RF-EST-10 y RF-EST-13.
// En modo estático la ficha del curso no muestra el bloque de asistencia (ni
// el pie con la última lectura ni el botón de actualizar desde miUlima), la
// calculadora queda en modo simulado sin la fila «Notas oficiales» ni pedir
// `/grades/me/ulima`, y /mis-notas no resuelve `RecargaUlimaService`. Con el
// modo apagado todo sigue como en la 1.2.0.
// Archivos probados lib/pages/descripcion_cursos/descrip_cursos.dart,
// lib/pages/calculadora/**, lib/pages/mis_notas/mis_notas_controller.dart.
//
// La sección es la 301, código 801, del CURSO DE PRUEBA A.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/components/recarga_ulima/fila_notas_oficiales.dart';
import 'package:ulima_plus/components/recarga_ulima/pie_asistencia.dart';
import 'package:ulima_plus/configs/modo_estatico.dart';
import 'package:ulima_plus/configs/themes.dart';
import 'package:ulima_plus/models/seccion_model.dart';
import 'package:ulima_plus/pages/calculadora/calculadora_controller.dart';
import 'package:ulima_plus/pages/calculadora/calculadora_page.dart';
import 'package:ulima_plus/pages/descripcion_cursos/descrip_cursos.dart';
import 'package:ulima_plus/pages/descripcion_cursos/descrip_cursos_controller.dart';
import 'package:ulima_plus/pages/mis_notas/mis_notas_controller.dart';
import 'package:ulima_plus/services/recarga_ulima_service.dart';
import 'package:ulima_plus/services/seccion_service.dart';

import '../HU37_jeff/recarga_dobles.dart';

Map<String, dynamic> _seccionJson({bool conDatos = true}) => <String, dynamic>{
  'idSeccion': '301',
  'codigoSeccion': '801',
  'curso': 'CURSO DE PRUEBA A',
  'asistido': conDatos ? 12 : 0,
  'inasistencia': conDatos ? 2 : 0,
  'total': conDatos ? 30 : 0,
  'asistenciaDisponible': conDatos,
  'horasTranscurridas': conDatos ? 14 : 0,
  'asistenciaLeidaEn': '2025-09-22T15:42:10.000Z',
};

/// La ficha con la sección fija y sin red en las pestañas.
class _Ficha extends DescripCursosController {
  _Ficha(this._inicial) : super(seccionService: SeccionService());

  final Seccion _inicial;

  @override
  Future<void> cargarDatosCurso(String idSeccion) async {
    seccionActual.value = _inicial;
    secciones.value = <Seccion>[_inicial];
  }

  @override
  Future<void> fetchAnuncios(String idSeccion) async {}

  @override
  Future<void> fetchAsesorias(String idSeccion) async {}

  @override
  Future<void> fetchContactos(String idSeccion) async {}
}

Future<void> _abrirFicha(
  WidgetTester tester, {
  required bool conDatos,
  required ApiRecargaFalsa api,
}) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);
  loguear(alumna());
  // Con el modo apagado, el arranque registra este servicio. Con el modo
  // estático no, y la ficha tiene que bastarse sin él.
  if (!ModoEstatico.activo) {
    Get.put<RecargaUlimaService>(RecargaUlimaService(apiClient: api));
  }
  Get.put<DescripCursosController>(
    _Ficha(Seccion.fromJson(_seccionJson(conDatos: conDatos))),
  );
  await tester.pumpWidget(
    GetMaterialApp(
      theme: const MaterialTheme(TextTheme()).light(),
      home: DescripCursosPage(idSeccion: '301'),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

/// La calculadora con un curso sembrado y sin la carga remota.
class _CalculadoraDePrueba extends CalculadoraController {
  _CalculadoraDePrueba(ApiRecargaFalsa api) : super(apiClient: api);

  @override
  // ignore: must_call_super
  void onInit() {
    cursos.add({
      'id': '81',
      'nombre': 'TALLER DE PROTOTIPADO',
      'ciclo': '2026-2',
      'codigoSeccion': '812',
      'notas': <Map<String, dynamic>>[
        {'titulo': 'Práctica', 'peso': 25, 'valor': 14.0, 'evaluacionId': '1'},
      ].obs,
      '_promedio': 0.0,
      '_sumaPesos': 0.0,
    });
    conectarUlima();
  }
}

Future<void> _abrirCalculadora(
  WidgetTester tester, {
  required bool registrarServicio,
  required ApiRecargaFalsa api,
}) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);
  loguear(alumna());
  if (registrarServicio) {
    Get.put<RecargaUlimaService>(RecargaUlimaService(apiClient: api));
  }
  Get.put<CalculadoraController>(_CalculadoraDePrueba(api));
  await tester.pumpWidget(
    GetMaterialApp(
      theme: const MaterialTheme(TextTheme()).light(),
      home: const CalculadoraPage(),
    ),
  );
  await tester.pump();
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    Get.testMode = true;
    Get.reset();
  });
  tearDown(() {
    ModoEstatico.activo = false;
    Get.reset();
  });

  group('RF-EST-10 · la ficha del curso', () {
    for (final conDatos in <bool>[true, false]) {
      final caso = conDatos ? 'con asistencia cargada' : 'sin asistencia';
      testWidgets('modo estático, $caso: no hay bloque de asistencia', (
        tester,
      ) async {
        ModoEstatico.activo = true;
        final api = ApiRecargaFalsa();
        await _abrirFicha(tester, conDatos: conDatos, api: api);
        expect(find.text('Asistencia'), findsNothing);
        expect(find.byType(PieAsistencia), findsNothing);
        expect(find.textContaining('miUlima'), findsNothing);
        expect(find.textContaining('Sin datos de asistencia'), findsNothing);
        expect(find.textContaining('horas'), findsNothing);
        // El resto de la ficha sigue.
        expect(find.text('Anuncios'), findsOneWidget);
        expect(api.llamadas, isEmpty);
      });
    }

    testWidgets('modo apagado: el bloque de asistencia sigue con su pie', (
      tester,
    ) async {
      final api = ApiRecargaFalsa();
      await _abrirFicha(tester, conDatos: true, api: api);
      expect(find.text('Asistencia'), findsWidgets);
      expect(find.byType(PieAsistencia), findsOneWidget);
    });

    testWidgets('modo apagado, sin datos: «Sin datos de asistencia» y el '
        'botón de miUlima', (tester) async {
      final api = ApiRecargaFalsa();
      await _abrirFicha(tester, conDatos: false, api: api);
      expect(find.textContaining('Sin datos de asistencia'), findsOneWidget);
    });
  });

  group('RF-EST-10 · la calculadora', () {
    testWidgets('modo estático: simulada, sin «Notas oficiales» y sin pedir '
        '/grades/me/ulima, aunque el servicio estuviera registrado', (
      tester,
    ) async {
      ModoEstatico.activo = true;
      final api = ApiRecargaFalsa();
      await _abrirCalculadora(tester, registrarServicio: true, api: api);
      expect(find.byType(FilaNotasOficiales), findsNothing);
      expect(find.text('Notas oficiales'), findsNothing);
      expect(find.text('Calculadora de Notas'), findsOneWidget);
      expect(find.text('TALLER DE PROTOTIPADO'), findsWidgets);
      expect(api.veces('GET /grades/me/ulima'), 0);
      final c = Get.find<CalculadoraController>();
      expect(c.hayVistaUlima.value, isFalse);
      await c.recargarTodo();
      expect(api.veces('GET /grades/me/ulima'), 0);
    });

    testWidgets('modo estático sin el servicio registrado: la calculadora '
        'abre igual', (tester) async {
      ModoEstatico.activo = true;
      final api = ApiRecargaFalsa();
      await _abrirCalculadora(tester, registrarServicio: false, api: api);
      expect(find.byType(FilaNotasOficiales), findsNothing);
      expect(find.text('TALLER DE PROTOTIPADO'), findsWidgets);
    });

    testWidgets('modo apagado: la fila «Notas oficiales» sigue y la vista '
        'se pide', (tester) async {
      final api = ApiRecargaFalsa();
      await _abrirCalculadora(tester, registrarServicio: true, api: api);
      expect(find.byType(FilaNotasOficiales), findsOneWidget);
      expect(api.veces('GET /grades/me/ulima'), greaterThanOrEqualTo(1));
    });
  });

  group('RF-EST-9 · /mis-notas sin servicio', () {
    test('modo estático: el controlador no resuelve RecargaUlimaService y no '
        'pide nada', () async {
      ModoEstatico.activo = true;
      loguear(alumna());
      expect(Get.isRegistered<RecargaUlimaService>(), isFalse);
      final c = MisNotasController();
      expect(c.vista, isNull);
      expect(c.aviso, isNull);
      expect(c.errorCarga, isFalse);
      await c.load();
      expect(Get.isRegistered<RecargaUlimaService>(), isFalse);
    });
  });
}
