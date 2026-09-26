// test/bienvenida/bienvenida_credenciales_test.dart
//
// UNITARIA + WIDGET · Bienvenida con Ulises
// (specs/features/bienvenida/bienvenida.spec.md).
// RF-BIEN-9 y B-20. La bienvenida cierra el controlador del registro sin
// GetX. Cerrarlo borra los cinco campos enseguida y los desecha después del
// cuadro en que el campo del compositor sale del árbol. La Tarea 24 suma los
// turnos y el oráculo de cuentas.
// Archivo probado lib/pages/registro/registro_controller.dart.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ulima_plus/pages/registro/registro_controller.dart';

void main() {
  group('el cierre propio del registro (RF-BIEN-9 y B-20)', () {
    testWidgets('cerrar borra los cinco campos enseguida y los desecha '
        'después del cuadro, sin error de un campo desechado', (tester) async {
      final c = RegistroController(
        adoptarSesion: ({required token, required user}) async {},
        iniciarSesion: ({required code, required password}) async => null,
      );
      final campos = [
        c.codigoCtrl,
        c.passwordCtrl,
        c.confirmacionCtrl,
        c.portalPasswordCtrl,
        c.passcodeCtrl,
      ];
      for (final campo in campos) {
        campo.text = 'dato-de-prueba';
      }
      final mostrar = ValueNotifier<bool>(true);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValueListenableBuilder<bool>(
              valueListenable: mostrar,
              builder: (_, visible, _) => visible
                  ? TextField(controller: c.passwordCtrl)
                  : const SizedBox.shrink(),
            ),
          ),
        ),
      );
      // Como la bienvenida, primero saca el campo y en el mismo cuadro cierra.
      mostrar.value = false;
      c.cerrar();
      expect(c.cerrado, isTrue);
      for (final campo in campos) {
        expect(campo.text, '', reason: 'se borra enseguida');
      }
      await tester.pump();
      await tester.pump();
      expect(tester.takeException(), isNull);
      for (final campo in campos) {
        expect(() => campo.addListener(() {}), throwsFlutterError);
      }
      // Cerrar dos veces no hace nada.
      c.cerrar();
    });

    test('el texto de «Iniciar sesión» desde incierto nombra «Ya tengo '
        'cuenta» (B-30)', () async {
      final c = RegistroController(
        adoptarSesion: ({required token, required user}) async {},
        iniciarSesion: ({required code, required password}) async =>
            'Código o contraseña incorrectos.',
      )..paso.value = RegistroPaso.incierto;
      expect(await c.intentarIniciarSesion(), isFalse);
      expect(
        c.errorMessage.value,
        'Seguimos sin poder confirmarlo. Puedes volver a intentar el '
        'registro: si te dice que ya existe una cuenta con ese código, es que '
        'sí se creó y puedes recuperar la contraseña con “Ya tengo cuenta”.',
      );
    });
  });
}
