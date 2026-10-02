// test/modo_estatico/arranque_estatico_test.dart
//
// UNITARIA · Versión estática del front (specs/features/modo-estatico/
// modo-estatico.spec.md), RF-EST-9 y RF-EST-13, con la enmienda de RF-IRM-11
// (specs/features/interruptor-remoto). El arranque registra los servicios
// del récord y de la recarga en los dos modos, sin pedir nada al portal, y
// con el modo apagado registra los mismos que la 1.2.0. El aviso de versión
// sigue programado en los dos modos.
// Archivos probados lib/pages/splash/carga_del_arranque.dart y lib/main.dart.

import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ulima_plus/configs/modo_estatico.dart';
import 'package:ulima_plus/pages/splash/carga_del_arranque.dart';
import 'package:ulima_plus/pages/splash/interruptor_remoto.dart';
import 'package:ulima_plus/services/academic_record_service.dart';
import 'package:ulima_plus/services/alert_service.dart';
import 'package:ulima_plus/services/auth_service.dart';
import 'package:ulima_plus/services/malla_service.dart';
import 'package:ulima_plus/services/modo_remoto_service.dart';
import 'package:ulima_plus/services/recarga_ulima_service.dart';
import 'package:ulima_plus/services/specialty_test_service.dart';
import 'package:ulima_plus/services/storage_service.dart';
import 'package:ulima_plus/services/time_blocks_service.dart';

import '../HU36_jeff/dobles_de_red.dart';
import 'apoyo_estatico.dart';

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
    InterruptorRemoto.reiniciar();
    Get.reset();
  });

  group('RF-EST-9 y RF-IRM-11 · los servicios del arranque', () {
    test('modo estático: registra también el récord y la recarga, sin pedir '
        'nada al portal', () async {
      ModoEstatico.activo = true;
      final espia = EspiaDeRed();
      await espia.correr(() async {
        registrarLosServicios();
      });
      expect(espia.peticiones, isEmpty);
      expect(Get.isRegistered<AcademicRecordService>(), isTrue);
      expect(Get.isRegistered<RecargaUlimaService>(), isTrue);
      expect(Get.isRegistered<AuthService>(), isTrue);
      expect(Get.isRegistered<AlertService>(), isTrue);
      expect(Get.isRegistered<MallaService>(), isTrue);
      expect(Get.isRegistered<TimeBlocksService>(), isTrue);
      expect(Get.isRegistered<SpecialtyTestService>(), isTrue);
    });

    test('modo apagado: los mismos servicios que la 1.2.0', () {
      registrarLosServicios();
      expect(Get.isRegistered<AcademicRecordService>(), isTrue);
      expect(Get.isRegistered<RecargaUlimaService>(), isTrue);
      expect(Get.isRegistered<AuthService>(), isTrue);
      expect(Get.isRegistered<MallaService>(), isTrue);
    });

    test('modo estático guardado: cargar el arranque sin sesión no pide nada '
        'al portal, conserva el modo y termina en /login', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        ModoRemotoService.claveConocido: true,
      });
      final espia = EspiaDeRed();
      final ruta = await espia.correr(
        () => cargarElArranque(iniciarFirebase: () async {}),
      );
      expect(ruta, '/login');
      expect(ModoEstatico.activo, isTrue);
      expect(espia.peticiones, contains('GET /config'));
      expect(espia.alPortal, isEmpty);
      expect(Get.isRegistered<StorageService>(), isTrue);
      expect(Get.isRegistered<RecargaUlimaService>(), isTrue);
      expect(Get.isRegistered<AcademicRecordService>(), isTrue);
    });

    test('el cierre de sesión en modo estático no pide nada al '
        'portal', () async {
      ModoEstatico.activo = true;
      registrarLosServicios();
      Get.put<StorageService>(AlmacenDePrueba());
      final auth = AuthService.to;
      final espia = EspiaDeRed();
      await expectLater(espia.correr(auth.logout), completes);
      expect(espia.alPortal, isEmpty);
    });
  });

  group('RF-EST-13 · el aviso de versión funciona en los dos modos', () {
    test('main() programa AvisoVersionArranque sin mirar el modo', () {
      final main = File('lib/main.dart').readAsStringSync();
      expect(main, contains('AvisoVersionArranque().programar()'));
      final aviso = File(
        'lib/pages/splash/aviso_version_arranque.dart',
      ).readAsStringSync();
      expect(aviso, isNot(contains('ModoEstatico')));
      final servicio = File(
        'lib/services/aviso_version_service.dart',
      ).readAsStringSync();
      expect(servicio, isNot(contains('ModoEstatico')));
    });
  });
}
