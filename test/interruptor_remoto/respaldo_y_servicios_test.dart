// test/interruptor_remoto/respaldo_y_servicios_test.dart
//
// UNITARIA · Interruptor remoto (specs/features/interruptor-remoto/
// interruptor-remoto.spec.md). RF-IRM-12 fija que MODO_ESTATICO es el
// respaldo de fábrica y el valor con que arranca ModoEstatico.activo.
// RF-IRM-11 fija que el arranque registra siempre AcademicRecordService y
// RecargaUlimaService, sin peticiones, de modo que el paso de estático a
// normal no deja ningún Get.find sin servicio.
// Archivos probados lib/configs/modo_estatico.dart y
// lib/pages/splash/carga_del_arranque.dart.

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ulima_plus/configs/modo_estatico.dart';
import 'package:ulima_plus/pages/splash/carga_del_arranque.dart';
import 'package:ulima_plus/services/academic_record_service.dart';
import 'package:ulima_plus/services/recarga_ulima_service.dart';

import '../modo_estatico/apoyo_estatico.dart';

/// Lo primero que se lee del modo en este isolate, antes de que ninguna
/// prueba lo toque.
final bool _valorInicial = ModoEstatico.activo;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    Get.testMode = true;
    Get.reset();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
  });
  tearDown(() {
    ModoEstatico.activo = false;
    Get.reset();
  });

  group('RF-IRM-12 · MODO_ESTATICO es el respaldo de fábrica', () {
    test('sin --dart-define el respaldo es false y el modo arranca en él', () {
      expect(_valorInicial, ModoEstatico.deCompilacion);
      expect(ModoEstatico.deCompilacion, isFalse);
    });
  });

  group('RF-IRM-11 · el récord y la recarga se registran siempre', () {
    for (final estatico in <bool>[true, false]) {
      final modo = estatico ? 'modo estático' : 'modo normal';
      test('$modo: se registran sin pedir nada', () async {
        ModoEstatico.activo = estatico;
        final espia = EspiaDeRed();
        await espia.correr(() async {
          registrarLosServicios();
        });
        expect(Get.isRegistered<AcademicRecordService>(), isTrue);
        expect(Get.isRegistered<RecargaUlimaService>(), isTrue);
        expect(espia.peticiones, isEmpty);
      });
    }

    test('pasar de estático a normal no deja ningún Get.find sin servicio', () {
      ModoEstatico.activo = true;
      registrarLosServicios();
      ModoEstatico.activo = false;
      expect(() => AcademicRecordService.to, returnsNormally);
      expect(() => RecargaUlimaService.to, returnsNormally);
    });
  });
}
