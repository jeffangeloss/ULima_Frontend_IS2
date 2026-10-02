// test/modo_estatico/alertas_estaticas_test.dart
//
// UNITARIA + WIDGET · Versión estática del front (specs/features/
// modo-estatico/modo-estatico.spec.md), RF-EST-10 y RF-EST-13.
// Las alertas «Alerta de inasistencias - <curso>» salen de la asistencia leída
// de miUlima. En modo estático no llegan a la campana, al contador ni al
// buzón, aunque el servidor las siga guardando. Con el modo apagado, el buzón
// es el de la 1.2.0.
// Archivos probados lib/services/alert_service.dart y
// lib/pages/alertas/alertas_page.dart.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/configs/modo_estatico.dart';
import 'package:ulima_plus/configs/themes.dart';
import 'package:ulima_plus/pages/alertas/alertas_page.dart';
import 'package:ulima_plus/services/alert_service.dart';
import 'package:ulima_plus/services/storage_service.dart';

import '../HU36_jeff/dobles_de_red.dart';
import '../HU37_jeff/recarga_dobles.dart';
import 'apoyo_estatico.dart';

const String _tituloDeInasistencias =
    'Alerta de inasistencias - CURSO DE PRUEBA A';
const String _tituloDeCarga = 'Semana de alta carga';
const String _tituloDePromedio = 'Riesgo por promedio';

Map<String, Object> _alerta(
  int id,
  String tipo,
  String titulo, {
  bool leida = false,
}) => <String, Object>{
  'id': id,
  'studentId': 1,
  'type': tipo,
  'title': titulo,
  'message': titulo.startsWith('Alerta de inasistencias')
      ? 'Has superado el límite. Tu porcentaje actual es de 22%.'
      : 'Mensaje de prueba $id.',
  'isRead': leida,
  'createdAt': '2026-09-30T12:00:00.000Z',
};

/// Una respuesta de `GET /alerts/me` con dos alertas de inasistencias, una de
/// ellas ya leída, mezcladas con las que no dependen de la ULima.
Map<String, Object> get _respuesta => <String, Object>{
  'alerts': <Object>[
    _alerta(1, 'academic_risk', _tituloDeInasistencias),
    _alerta(2, 'high_load', _tituloDeCarga),
    _alerta(3, 'academic_risk', _tituloDePromedio),
    _alerta(
      4,
      'academic_risk',
      'Alerta de inasistencias - CURSO DE PRUEBA B',
      leida: true,
    ),
  ],
};

Future<void> _montarBuzon(WidgetTester tester) async {
  tester.view.physicalSize = const Size(800, 2800);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    GetMaterialApp(
      theme: MaterialTheme(ThemeData().textTheme).light(),
      home: const AlertasPage(),
    ),
  );
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    Get.testMode = true;
    Get.reset();
    Get.put<StorageService>(AlmacenDePrueba());
    loguear(alumna());
  });
  tearDown(() {
    ModoEstatico.activo = false;
    Get.reset();
  });

  group('RF-EST-10 · AlertService', () {
    test('modo estático: descarta las alertas de inasistencias y no las '
        'cuenta como sin leer', () async {
      ModoEstatico.activo = true;
      final servicio = Get.put<AlertService>(AlertService());
      final espia = EspiaDeRed(
        respuestas: <String, Object>{'GET /alerts/me': _respuesta},
      );
      await espia.correr(servicio.fetchAlerts);
      expect(servicio.hasError, isFalse);
      expect(servicio.alerts.map((a) => a.title).toList(), <String>[
        _tituloDeCarga,
        _tituloDePromedio,
      ]);
      expect(servicio.unreadCount, 2);
    });

    test('modo apagado: conserva todas las alertas como en la 1.2.0', () async {
      final servicio = Get.put<AlertService>(AlertService());
      final espia = EspiaDeRed(
        respuestas: <String, Object>{'GET /alerts/me': _respuesta},
      );
      await espia.correr(servicio.fetchAlerts);
      expect(servicio.alerts, hasLength(4));
      expect(servicio.unreadCount, 3);
    });
  });

  group('RF-EST-10 · el buzón de alertas', () {
    testWidgets('modo estático: no pinta las alertas de inasistencias', (
      tester,
    ) async {
      ModoEstatico.activo = true;
      Get.put<AlertService>(AlertService());
      final espia = EspiaDeRed(
        respuestas: <String, Object>{'GET /alerts/me': _respuesta},
      );
      await espia.correr(() async => _montarBuzon(tester));
      expect(find.textContaining('Alerta de inasistencias'), findsNothing);
      expect(find.textContaining('Tu porcentaje actual'), findsNothing);
      expect(find.text(_tituloDeCarga), findsOneWidget);
      expect(find.text(_tituloDePromedio), findsOneWidget);
    });

    testWidgets('modo apagado: el buzón muestra las de inasistencias', (
      tester,
    ) async {
      Get.put<AlertService>(AlertService());
      final espia = EspiaDeRed(
        respuestas: <String, Object>{'GET /alerts/me': _respuesta},
      );
      await espia.correr(() async => _montarBuzon(tester));
      expect(find.text(_tituloDeInasistencias), findsOneWidget);
      expect(find.text(_tituloDeCarga), findsOneWidget);
    });
  });
}
