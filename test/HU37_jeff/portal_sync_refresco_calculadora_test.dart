// test/HU37_jeff/portal_sync_refresco_calculadora_test.dart
//
// UNITARIA · Recarga desde la ULima (specs/features/recarga-portal/
// recarga-portal.spec.md), RF-RCG-11, la importación recarga la calculadora
// en vez de borrarla.
// Archivo probado lib/pages/portal_sync/portal_sync_controller.dart.

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/pages/calculadora/calculadora_controller.dart';
import 'package:ulima_plus/pages/portal_sync/portal_sync_controller.dart';
import 'package:ulima_plus/services/portal_sync_service.dart';

import 'recarga_dobles.dart';

/// La calculadora sin carga remota, que cuenta sus recargas.
class _CalculadoraEspia extends CalculadoraController {
  int recargas = 0;

  @override
  // ignore: must_call_super
  void onInit() {}

  @override
  Future<void> recargarTodo() async => recargas++;
}

/// Una importación que sale bien, sin token. Todo inventado.
Map<String, dynamic> _importOk() => <String, dynamic>{
  'period': {'id': 2, 'code': '2026-2'},
  'identity': {
    'portalCode': '20230001',
    'fullName': 'Alumna De Prueba',
    'career': 'CARRERA DE PRUEBA',
  },
  'summary': {'enrollmentsUpserted': 5},
  'warnings': <dynamic>[],
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.testMode = true;
    Get.reset();
  });
  tearDown(Get.reset);

  test('tras una importación exitosa, CalculadoraController sigue registrado '
      'y su recargarTodo() corre una vez', () async {
    loguear(alumna());
    final calculadora =
        Get.put<CalculadoraController>(_CalculadoraEspia())
            as _CalculadoraEspia;
    final api = ApiRecargaFalsa()
      ..responder('POST /portal-sync/import', _importOk());
    final c = PortalSyncController(service: PortalSyncService(apiClient: api));
    c.aceptarConsentimiento();
    c.passwordCtrl.text = 'clave-de-prueba';
    c.passcodeCtrl.text = '482913';

    await c.submit();

    expect(c.step.value, PortalSyncStep.done);
    expect(Get.isRegistered<CalculadoraController>(), isTrue);
    expect(Get.find<CalculadoraController>(), same(calculadora));
    expect(calculadora.recargas, 1);
  });

  test('sin la calculadora registrada, la importación no la crea', () async {
    loguear(alumna());
    final api = ApiRecargaFalsa()
      ..responder('POST /portal-sync/import', _importOk());
    final c = PortalSyncController(service: PortalSyncService(apiClient: api));
    c.aceptarConsentimiento();
    c.passwordCtrl.text = 'clave-de-prueba';
    c.passcodeCtrl.text = '482913';

    await c.submit();

    expect(c.step.value, PortalSyncStep.done);
    expect(Get.isRegistered<CalculadoraController>(), isFalse);
  });
}
