// test/bienvenida/bienvenida_registro_test.dart
//
// UNITARIA + WIDGET · Bienvenida con Ulises
// (specs/features/bienvenida/bienvenida.spec.md).
// RF-BIEN-7 y RF-BIEN-8. El registro de hoy repartido en turnos, con sus
// validadores sin red, el consentimiento que no se repite, el envío con su
// advertencia de hoy, cada desenlace y el paso al test. La Tarea 27 suma el
// compositor de cada turno.
// Archivo probado lib/pages/bienvenida/bienvenida_controller.dart.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/components/portal_consent/portal_consent_view.dart';
import 'package:ulima_plus/domain/bienvenida/bienvenida_turnos.dart';
import 'package:ulima_plus/models/registro_models.dart';
import 'package:ulima_plus/pages/bienvenida/bienvenida_controller.dart';
import 'package:ulima_plus/pages/bienvenida/conversacion.dart';
import 'package:ulima_plus/pages/bienvenida/widgets/compositor.dart';
import 'package:ulima_plus/pages/password_reset/password_reset_ui.dart';
import 'package:ulima_plus/services/session_navigation.dart';

import 'apoyo_bienvenida.dart';

typedef _T = TurnoDeLaBienvenida;

/// Llega hasta N5 con datos válidos inventados.
Future<Bienvenida> _enN5({
  RegistroFalso? registro,
  bool adoptarFalla = false,
}) async {
  final b = Bienvenida(registro: registro, adoptarFalla: adoptarFalla);
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
  return b;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(Get.reset);

  group('los datos de la cuenta (RF-BIEN-7)', () {
    test('N1 valida el código en local y sigue N2', () async {
      final b = Bienvenida();
      await b.visitar();
      final c = b.controlador..responderAlSaludo(yaUsa: false);
      c.registro!.codigoCtrl.text = '12ab';
      c.enviarCodigoDeAlumno();
      expect(
        c.errorLocal.value,
        'El código son entre 6 y 10 dígitos, sin espacios ni letras.',
      );
      expect(c.turno.value, _T.n1Codigo);
      c.registro!.codigoCtrl.text = ' 20230001 ';
      c.enviarCodigoDeAlumno();
      expect(b.delAlumno.last, '20230001');
      expect(b.deUlises.last, TextosDeLaBienvenida.n2);
      expect(c.turno.value, _T.n2Contrasena);
      expect(c.errorLocal.value, isNull);
    });

    test('N2 valida las dos contraseñas y responde con un candado', () async {
      final b = Bienvenida();
      await b.visitar();
      final c = b.controlador..responderAlSaludo(yaUsa: false);
      c.registro!.codigoCtrl.text = '20230001';
      c.enviarCodigoDeAlumno();
      c.registro!
        ..passwordCtrl.text = 'corta'
        ..confirmacionCtrl.text = 'corta';
      c.enviarContrasenas();
      expect(c.errorLocal.value, isNotNull);
      c.registro!
        ..passwordCtrl.text = 'Contrasena1'
        ..confirmacionCtrl.text = 'Contrasena2';
      c.enviarContrasenas();
      expect(c.errorLocal.value, isNotNull);
      c.registro!.confirmacionCtrl.text = 'Contrasena1';
      c.enviarContrasenas();
      final respuesta = c.entradas.whereType<RespuestaDelAlumno>().last;
      expect(respuesta.texto, TextosDeLaBienvenida.contrasenaUlimaLista);
      expect(respuesta.secreta, isTrue);
      final tarjeta = c.entradas.last as BurbujaDeUlises;
      expect(tarjeta.tipo, TipoDeBurbuja.consentimiento);
      expect(c.turno.value, _T.n3Consentimiento);
    });

    test(
      'aceptado una vez, el consentimiento no se repite al volver',
      () async {
        final b = await _enN5();
        final c = b.controlador..volver();
        expect(c.turno.value, _T.n4Portal);
        c.volver();
        expect(c.turno.value, _T.n2Contrasena);
        expect(b.delAlumno.last, TextosDeLaBienvenida.volver);
        expect(b.deUlises.last, TextosDeLaBienvenida.n2);
        expect(c.registro!.passwordCtrl.text, 'Contrasena1');
        c.enviarContrasenas();
        expect(c.turno.value, _T.n4Portal);
      },
    );

    test('ningún turno antes del envío llama al backend', () async {
      final b = await _enN5();
      expect(b.servicioDeRegistro.llamadas, 0);
    });

    test('«Ya tengo cuenta» cierra el registro y abre E1', () async {
      final b = await _enN5();
      final registro = b.controlador.registro!;
      b.controlador.yaTengoCuenta();
      expect(b.delAlumno.last, TextosDeLaBienvenida.yaTengoCuenta);
      expect(b.controlador.registro, isNull);
      expect(registro.cerrado, isTrue);
      expect(b.controlador.turno.value, _T.e1Codigo);
    });
  });

  group('el envío y sus desenlaces (RF-BIEN-8)', () {
    test('mientras se envía, la advertencia de hoy, la píldora y el pulso, sin '
        'compositor', () async {
      final pendiente = Completer<RegistroResult>();
      final b = await _enN5(registro: RegistroFalso(pendiente: pendiente));
      final c = b.controlador;
      unawaited(c.crearCuenta());
      await Future<void>.delayed(Duration.zero);
      expect(b.delAlumno.last, TextosDeLaBienvenida.authenticatorListo);
      expect(b.deUlises.sublist(b.deUlises.length - 2), [
        TextosDeLaBienvenida.creando,
        TextosDeLaBienvenida.advertencia,
      ]);
      expect(c.pildora.value, EstadoDeLaPildora.creando);
      expect(c.enviando.value, isTrue);
      expect(c.turno.value, isNull);
      expect(c.ultimoTurno.value, _T.envio);
      // El atrás no sale y avisa abajo (BR-REG-F-09).
      c.atras();
      expect(b.avisos, [TextosDeLaBienvenida.avisoEnvioTitulo]);
      pendiente.complete(resultadoDelRegistro());
      await Future<void>.delayed(Duration.zero);
      expect(c.enviando.value, isFalse);
    });

    test('un 201 dice la cuenta y el conteo en una burbuja, cierra el registro '
        'y sigue el test', () async {
      final b = await _enN5();
      final registro = b.controlador.registro!;
      await b.controlador.crearCuenta();
      expect(b.controlador.pildora.value, EstadoDeLaPildora.creada);
      expect(
        b.deUlises,
        contains(
          '¡Craa! Tu cuenta ya está lista. Traje tus 5 cursos del ciclo.',
        ),
      );
      expect(registro.cerrado, isTrue);
      expect(b.controlador.registro, isNull);
      expect(b.controlador.conSesion, isTrue);
      expect(b.controlador.ultimoTurno.value, _T.t0Invitacion);
    });

    test('con 0 cursos no hay frase del conteo, y los avisos van en otra '
        'burbuja', () async {
      final b = await _enN5(
        registro: RegistroFalso(
          resultado: resultadoDelRegistro(cursos: 0, avisos: ['Sílabo caído.']),
        ),
      );
      await b.controlador.crearCuenta();
      expect(b.deUlises, contains('¡Craa! Tu cuenta ya está lista.'));
      final avisos = b.controlador.entradas
          .whereType<BurbujaDeUlises>()
          .firstWhere((e) => e.tipo == TipoDeBurbuja.avisos);
      expect(avisos.titulo, 'Algunas cosas que notamos');
      expect(avisos.lineas, ['Sílabo caído.']);
    });

    test('una cuenta que ya existe vuelve a N1 con el texto de hoy y el código '
        'del authenticator borrado', () async {
      final b = await _enN5(
        registro: RegistroFalso(
          fallo: const RegistroFailure(
            'Ya existe una cuenta con ese código. Inicia sesión o recupera tu '
            'contraseña.',
            code: 'USER_ALREADY_EXISTS',
          ),
        ),
      );
      await b.controlador.crearCuenta();
      expect(
        b.deUlises.last,
        startsWith('Ya existe una cuenta con ese código.'),
      );
      expect(b.controlador.turno.value, _T.n1Codigo);
      expect(b.controlador.registro!.passcodeCtrl.text, '');
      expect(
        b.controlador.registro!.portalPasswordCtrl.text,
        'clave-de-prueba',
      );
      expect(b.controlador.pildora.value, isNull);
    });

    test(
      'sin conexión vuelve a N5, como hoy vuelve a verificar (B-32)',
      () async {
        final b = await _enN5(
          registro: RegistroFalso(
            fallo: const RegistroFailure(
              'No hay conexión. Revisa tu internet e inténtalo de nuevo.',
              code: 'SIN_CONEXION',
            ),
          ),
        );
        await b.controlador.crearCuenta();
        expect(b.deUlises.last, TextosDeLaBienvenida.sinConexion);
        expect(b.controlador.turno.value, _T.n5Authenticator);
      },
    );

    test(
      'con el plazo vencido queda en la duda, con los dos títulos de hoy',
      () async {
        final b = await _enN5(
          registro: RegistroFalso(
            fallo: const RegistroFailure(
              'No pudimos confirmar si tu cuenta se creó.',
              code: 'TIEMPO_AGOTADO',
            ),
          ),
        );
        await b.controlador.crearCuenta();
        expect(b.deUlises.sublist(b.deUlises.length - 2), [
          TextosDeLaBienvenida.inciertoTitulo,
          TextosDeLaBienvenida.inciertoTexto,
        ]);
        expect(b.controlador.turno.value, _T.incierto);
      },
    );

    test(
      'con el 201 y sin sesión, la cuenta está creada y suma el mensaje',
      () async {
        final b = await _enN5(adoptarFalla: true);
        await b.controlador.crearCuenta();
        expect(
          b.deUlises,
          containsAllInOrder([
            TextosDeLaBienvenida.creadaTitulo,
            TextosDeLaBienvenida.creadaTexto,
            'Tu cuenta se creó, pero no pudimos dejarte la sesión iniciada.',
          ]),
        );
        expect(b.controlador.turno.value, _T.incierto);
      },
    );

    test('«Iniciar sesión» desde incierto sigue el test si entra, o dice que '
        'sigue sin poder confirmarlo', () async {
      final b = await _enN5(
        registro: RegistroFalso(
          fallo: const RegistroFailure('x', code: 'TIEMPO_AGOTADO'),
        ),
      );
      await b.controlador.crearCuenta();
      b.auth.errorDeLogin = 'Código o contraseña incorrectos.';
      await b.controlador.iniciarSesionDesdeIncierto();
      expect(b.deUlises.last, startsWith('Seguimos sin poder confirmarlo.'));
      expect(b.deUlises.last, endsWith('con “Ya tengo cuenta”.'));
      expect(b.controlador.turno.value, _T.incierto);
      b.auth
        ..errorDeLogin = null
        ..alEntrar = alumnaDePrueba(setupComplete: false);
      await b.controlador.iniciarSesionDesdeIncierto();
      expect(b.controlador.registro, isNull);
      expect(b.controlador.ultimoTurno.value, _T.t0Invitacion);
    });

    test('«Volver a intentar el registro» vuelve a N5 con el código del '
        'authenticator borrado', () async {
      final b = await _enN5(
        registro: RegistroFalso(
          fallo: const RegistroFailure('x', code: 'TIEMPO_AGOTADO'),
        ),
      );
      await b.controlador.crearCuenta();
      b.controlador.volverAIntentarElRegistro();
      expect(b.delAlumno.last, TextosDeLaBienvenida.volverAIntentar);
      expect(b.deUlises.last, TextosDeLaBienvenida.n5);
      expect(b.controlador.turno.value, _T.n5Authenticator);
      expect(b.controlador.registro!.passcodeCtrl.text, '');
      expect(
        b.controlador.registro!.portalPasswordCtrl.text,
        'clave-de-prueba',
      );
    });
  });

  group('el compositor del registro (RF-BIEN-7 y RF-BIEN-9)', () {
    Future<Bienvenida> enN1(WidgetTester tester) async {
      final b = Bienvenida();
      await montarLaBienvenida(
        tester,
        b,
        argumentos: const {argumentoDeMotivo: MotivoDeLlegada.expirada},
      );
      await avanzar(tester, 1500);
      await tester.tap(find.text(TextosDeLaBienvenida.soyNuevo));
      await avanzar(tester, 3000);
      return b;
    }

    Future<void> escribir(WidgetTester tester, int campo, String texto) async {
      await tester.enterText(find.byType(TextField).at(campo), texto);
      await tester.pump();
    }

    testWidgets('N1 pide el código con teclado numérico y trae «Ya tengo '
        'cuenta»', (tester) async {
      await enN1(tester);
      expect(
        find.text(TextosDeLaBienvenida.rotuloCodigoDeAlumno),
        findsOneWidget,
      );
      final campo = tester.widget<TextField>(find.byType(TextField));
      expect(campo.keyboardType, TextInputType.number);
      expect(find.text(TextosDeLaBienvenida.yaTengoCuenta), findsOneWidget);
    });

    testWidgets('las dos contraseñas nunca están a la vez en el compositor', (
      tester,
    ) async {
      await enN1(tester);
      await escribir(tester, 0, '20230001');
      await tester.tap(find.byType(BotonDeEnvio));
      await avanzar(tester, 2500);
      expect(find.text(TextosDeLaBienvenida.pistaNueva), findsOneWidget);
      expect(find.text(TextosDeLaBienvenida.pistaPortal), findsNothing);
      await escribir(tester, 0, 'Contrasena1');
      await escribir(tester, 1, 'Contrasena1');
      await tester.tap(find.byType(BotonDeEnvio));
      await avanzar(tester, 3000);
      // N3, la tarjeta del consentimiento con sus textos literales.
      expect(find.text(PortalConsentView.titulo), findsOneWidget);
      expect(find.text(TextosDeLaBienvenida.acepto), findsOneWidget);
      await tester.tap(find.text(TextosDeLaBienvenida.acepto));
      await avanzar(tester, 2500);
      expect(find.text(TextosDeLaBienvenida.pistaPortal), findsOneWidget);
      expect(find.text(TextosDeLaBienvenida.pistaNueva), findsNothing);
      expect(find.text(TextosDeLaBienvenida.yaTengoCuenta), findsOneWidget);
      expect(find.text(TextosDeLaBienvenida.volver), findsOneWidget);
    });

    testWidgets('N5 trae las seis casillas y solo envía con «Crear mi '
        'cuenta» (B-5)', (tester) async {
      final b = await enN1(tester);
      await escribir(tester, 0, '20230001');
      await tester.tap(find.byType(BotonDeEnvio));
      await avanzar(tester, 2500);
      await escribir(tester, 0, 'Contrasena1');
      await escribir(tester, 1, 'Contrasena1');
      await tester.tap(find.byType(BotonDeEnvio));
      await avanzar(tester, 3000);
      await tester.tap(find.text(TextosDeLaBienvenida.acepto));
      await avanzar(tester, 2500);
      await escribir(tester, 0, 'clave-de-prueba');
      await tester.tap(find.byType(BotonDeEnvio));
      await avanzar(tester, 2500);
      expect(find.byType(PasswordResetOtpField), findsOneWidget);
      expect(find.text(TextosDeLaBienvenida.notaAuthenticator), findsOneWidget);
      b.controlador.registro!.passcodeCtrl.text = '123456';
      await tester.pump();
      expect(b.servicioDeRegistro.llamadas, 0, reason: 'no envía solo');
      await tester.tap(find.text(TextosDeLaBienvenida.crearMiCuenta));
      await tester.pump();
      expect(b.servicioDeRegistro.llamadas, 1);
      await avanzar(tester, 4000);
    });
  });
}
