// test/bienvenida/bienvenida_atras_test.dart
//
// UNITARIA · Bienvenida con Ulises (specs/features/bienvenida/bienvenida.spec.md).
// RF-BIEN-13. El atrás del sistema hace lo mismo que el enlace secundario de
// cada turno. La Tarea 25 suma los turnos del test.
// Archivo probado lib/pages/bienvenida/bienvenida_controller.dart.

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/domain/bienvenida/bienvenida_turnos.dart';
import 'package:ulima_plus/models/registro_models.dart';

import 'apoyo_bienvenida.dart';

typedef _T = TurnoDeLaBienvenida;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(Get.reset);

  group('el atrás en el registro (RF-BIEN-13)', () {
    test('N1 es «Ya tengo cuenta» y N2 es «Volver»', () async {
      final b = Bienvenida();
      await b.visitar();
      final c = b.controlador..responderAlSaludo(yaUsa: false);
      c.registro!.codigoCtrl.text = '20230001';
      c.enviarCodigoDeAlumno();
      c.atras();
      expect(c.turno.value, _T.n1Codigo);
      c.atras();
      expect(c.turno.value, _T.e1Codigo);
      expect(c.registro, isNull);
    });

    test('incierto es «Volver a intentar el registro»', () async {
      final b = Bienvenida(
        registro: RegistroFalso(
          fallo: const RegistroFailure('x', code: 'TIEMPO_AGOTADO'),
        ),
      );
      await b.visitar();
      final c = b.controlador..responderAlSaludo(yaUsa: false);
      c.registro!.codigoCtrl.text = '20230001';
      c.enviarCodigoDeAlumno();
      c.registro!
        ..passwordCtrl.text = 'Contrasena1'
        ..confirmacionCtrl.text = 'Contrasena1';
      c.enviarContrasenas();
      c.aceptarConsentimiento();
      c.registro!.portalPasswordCtrl.text = 'clave-de-prueba';
      c.enviarPortal();
      c.registro!.passcodeCtrl.text = '123456';
      await c.crearCuenta();
      expect(c.turno.value, _T.incierto);
      c.atras();
      expect(c.turno.value, _T.n5Authenticator);
    });
  });
}
