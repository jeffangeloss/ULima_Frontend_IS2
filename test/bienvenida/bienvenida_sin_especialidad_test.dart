// test/bienvenida/bienvenida_sin_especialidad_test.dart
//
// UNITARIA + WIDGET · Bienvenida con Ulises
// (specs/features/bienvenida/bienvenida.spec.md).
// RF-BIEN-21 y B-10. Un alumno con sesión y la configuración a medias llega
// a la bienvenida y sigue en la conversación hasta el test, sin la pregunta
// ni los dos botones. Sin sesión, o con un motivo, la llegada es la de
// siempre aunque currentUser quede en memoria. Las Tareas 25 y 28 suman el
// test y el recibimiento.
// Archivo probado lib/pages/bienvenida/bienvenida_controller.dart.

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/domain/bienvenida/bienvenida_turnos.dart';
import 'package:ulima_plus/services/session_navigation.dart';

import 'apoyo_bienvenida.dart';

void main() {
  tearDown(Get.reset);

  group('la llegada con sesión (RF-BIEN-21)', () {
    test('con el token y un alumno sin especialidad, la visita es la llegada '
        'con sesión', () async {
      final b = Bienvenida(
        auth: AuthDeLaBienvenida(usuario: alumnaDePrueba(setupComplete: false)),
        token: 'jwt-de-prueba',
      );
      await b.visitar();
      expect(b.controlador.turno.value, TurnoDeLaBienvenida.llegadaConSesion);
      expect(b.controlador.conSesion, isTrue);
      expect(b.controlador.atrasSaleDeLaApp, isTrue);
    });

    test('al terminar el rebote de Ulises entra el primer grupo, sin '
        'respuesta del alumno', () async {
      final b = Bienvenida(
        auth: AuthDeLaBienvenida(usuario: alumnaDePrueba(setupComplete: false)),
        token: 'jwt-de-prueba',
      );
      await b.visitar();
      b.controlador.ulisesAterrizoConSesion();
      expect(b.deUlises.take(2), [
        TextosDeLaBienvenida.saludoConSesion,
        TextosDeLaBienvenida.faltaEspecialidad,
      ]);
      expect(b.delAlumno, isEmpty);
    });

    test('con el token y la configuración completa, o un docente, la visita '
        'se despide y pide el paso al horario (RF-BIEN-21)', () async {
      for (final usuario in [alumnaDePrueba(), docenteDePrueba()]) {
        final b = Bienvenida(
          auth: AuthDeLaBienvenida(usuario: usuario),
          token: 'jwt-de-prueba',
        );
        await b.visitar();
        expect(b.deUlises, [TextosDeLaBienvenida.e3]);
        expect(b.controlador.turno.value, TurnoDeLaBienvenida.pasoAlHorario);
        expect(b.controlador.conSesion, isTrue);
        expect(b.controlador.test, isNull);
        expect(b.rutas, isEmpty);
        Get.reset();
      }
    });

    test('sin token, o con un motivo, la llegada es la de siempre aunque '
        'currentUser quede en memoria', () async {
      final sinToken = Bienvenida(
        auth: AuthDeLaBienvenida(usuario: alumnaDePrueba(setupComplete: false)),
      );
      await sinToken.visitar();
      expect(
        sinToken.controlador.turno.value,
        TurnoDeLaBienvenida.recibimiento,
      );
      Get.reset();
      final conMotivo = Bienvenida(
        auth: AuthDeLaBienvenida(usuario: alumnaDePrueba(setupComplete: false)),
        token: 'jwt-de-prueba',
      );
      await conMotivo.visitar(motivo: MotivoDeLlegada.expirada);
      expect(conMotivo.controlador.turno.value, TurnoDeLaBienvenida.e1Codigo);
    });
  });

  group('hasta el horario (RF-BIEN-21)', () {
    test('la llegada con sesión sigue en T0 y termina en el paso al horario, '
        'nunca en /setup-carrera', () async {
      final b = Bienvenida(
        auth: AuthDeLaBienvenida(usuario: alumnaDePrueba(setupComplete: false)),
        token: 'jwt-de-prueba',
      );
      await b.visitar();
      final c = b.controlador..ulisesAterrizoConSesion();
      await pumpEventQueue();
      expect(c.turno.value, TurnoDeLaBienvenida.t0Invitacion);
      c
        ..saltarElTest()
        ..marcarPrincipal(1);
      await c.terminarLaSeleccion();
      expect(c.turno.value, TurnoDeLaBienvenida.pasoAlHorario);
      expect(b.rutas, isEmpty);
    });
  });
}
