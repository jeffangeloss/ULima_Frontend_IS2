// test/interruptor_remoto/senal_del_modo_test.dart
//
// UNITARIA + WIDGET · Interruptor remoto (specs/features/interruptor-remoto/
// interruptor-remoto.spec.md). La decisión D-2 fija que ModoEstatico.fijar
// cambia el modo que rige y avanza ModoEstatico.cambios solo si el modo
// cambia, que ModoEstatico.activoObservado suscribe al Obx que lo lee y que
// el interruptor avanza la señal con una respuesta distinta y no con una
// igual ni con una desconocida. Sin red y con datos inventados.
// Archivos probados lib/configs/modo_estatico.dart y
// lib/pages/splash/interruptor_remoto.dart.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ulima_plus/configs/modo_estatico.dart';
import 'package:ulima_plus/pages/splash/interruptor_remoto.dart';

import 'apoyo_interruptor.dart';

/// El interruptor recibe lo que responde [backend], sin navegador.
Future<void> _responde(BackendDelModo backend) => InterruptorRemoto(
  servicio: backend.servicio(),
  capaCubre: ValueNotifier<bool>(false),
).consultar();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    Get.testMode = true;
    Get.reset();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    ModoEstatico.activo = false;
  });
  tearDown(() {
    ModoEstatico.activo = false;
    InterruptorRemoto.reiniciar();
    Get.reset();
  });

  group('D-2 · la señal del cambio de modo', () {
    test('fijar el modo que rige no avanza cambios', () {
      final antes = ModoEstatico.cambios.value;
      expect(ModoEstatico.fijar(false), isFalse);
      expect(ModoEstatico.activo, isFalse);
      expect(ModoEstatico.cambios.value, antes);
    });

    test('fijar otro modo lo fija y avanza cambios una vez por cambio', () {
      final antes = ModoEstatico.cambios.value;
      expect(ModoEstatico.fijar(true), isTrue);
      expect(ModoEstatico.activo, isTrue);
      expect(ModoEstatico.cambios.value, antes + 1);
      expect(ModoEstatico.fijar(true), isFalse);
      expect(ModoEstatico.cambios.value, antes + 1);
      expect(ModoEstatico.fijar(false), isTrue);
      expect(ModoEstatico.activo, isFalse);
      expect(ModoEstatico.cambios.value, antes + 2);
    });

    test('activoObservado devuelve el modo que rige, también el que fijan '
        'las pruebas', () {
      ModoEstatico.activo = true;
      expect(ModoEstatico.activoObservado, isTrue);
      ModoEstatico.activo = false;
      expect(ModoEstatico.activoObservado, isFalse);
    });

    testWidgets('un Obx que lee activoObservado se reconstruye cuando fijar '
        'cambia el modo', (tester) async {
      var construcciones = 0;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Obx(() {
            construcciones++;
            return Text(
              ModoEstatico.activoObservado ? 'ESTÁTICA' : 'DINÁMICA',
            );
          }),
        ),
      );
      expect(find.text('DINÁMICA'), findsOneWidget);
      ModoEstatico.fijar(true);
      await tester.pump();
      expect(find.text('ESTÁTICA'), findsOneWidget);
      expect(construcciones, 2);
      ModoEstatico.fijar(true);
      await tester.pump();
      expect(construcciones, 2);
    });

    test('el interruptor avanza cambios con una respuesta distinta y no con '
        'una igual ni con una desconocida', () async {
      final antes = ModoEstatico.cambios.value;
      await _responde(BackendDelModo(cuerpo: '{"modoEstatico":false}'));
      expect(ModoEstatico.cambios.value, antes);
      await _responde(BackendDelModo(estado: 500));
      expect(ModoEstatico.cambios.value, antes);
      await _responde(BackendDelModo(cuerpo: '{"modoEstatico":true}'));
      expect(ModoEstatico.activo, isTrue);
      expect(ModoEstatico.cambios.value, antes + 1);
    });
  });
}
