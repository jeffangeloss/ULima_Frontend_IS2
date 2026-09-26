// test/bienvenida/bienvenida_entrar_test.dart
//
// UNITARIA + WIDGET · Bienvenida con Ulises
// (specs/features/bienvenida/bienvenida.spec.md).
// RF-BIEN-6. LoginController deja de navegar y devuelve el desenlace, atrapa
// el fallo crudo de la red y apaga `submitting`, y vacía sus campos al
// salir. Las Tareas 23 y 27 suman los turnos E1, E2 y E3.
// Archivo probado lib/pages/login/login_controller.dart.

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/models/user_model.dart';
import 'package:ulima_plus/pages/login/login_controller.dart';
import 'package:ulima_plus/services/auth_service.dart';

UserModel _alumna() => UserModel(
  code: '20230001',
  firstName: 'Alumna',
  lastName: 'De Prueba',
  email: 'test@aloe.ulima.edu.pe',
  role: 'student',
  currentCycle: '2026-2',
  setupComplete: true,
);

/// Lo que `AuthService.login` no atrapa, como un socket caído.
class _RedCaida implements Exception {
  const _RedCaida();
}

class _AuthDePrueba extends AuthService {
  _AuthDePrueba({this.error, this.redCaida = false, this.google});

  final String? error;
  final bool redCaida;

  /// Lo que devuelve Google, con 'cancelar' para el selector cerrado.
  final String? google;
  UserModel? _usuario;
  int logins = 0;

  @override
  UserModel? get currentUser => _usuario;

  @override
  Future<String?> login({
    required String code,
    required String password,
  }) async {
    logins++;
    if (redCaida) throw const _RedCaida();
    if (error != null) return error;
    _usuario = _alumna();
    return null;
  }

  @override
  Future<String?> loginWithGoogle() async {
    if (google == 'cancelar') return null;
    if (google != null) return google;
    _usuario = _alumna();
    return null;
  }
}

LoginController _controlador(_AuthDePrueba auth) {
  Get.testMode = true;
  Get.reset();
  Get.put<AuthService>(auth);
  return LoginController()
    ..codeController.text = '20230001'
    ..passwordController.text = 'secreta-de-prueba';
}

void main() {
  group('LoginController devuelve el desenlace (RF-BIEN-6)', () {
    tearDown(Get.reset);

    test('con la sesión puesta devuelve sesionPuesta y no navega', () async {
      final c = _controlador(_AuthDePrueba());
      final d = await c.entrar();
      expect(d.tipo, TipoDeDesenlace.sesionPuesta);
      expect(c.submitting.value, isFalse);
      expect(Get.currentRoute, isNot('/home'));
    });

    test('un login rechazado devuelve el mensaje de hoy', () async {
      final c = _controlador(
        _AuthDePrueba(error: 'Código o contraseña incorrectos.'),
      );
      final d = await c.entrar();
      expect(d.tipo, TipoDeDesenlace.error);
      expect(d.mensaje, 'Código o contraseña incorrectos.');
    });

    test(
      'un fallo crudo de la red devuelve sinConexion y apaga submitting',
      () async {
        final c = _controlador(_AuthDePrueba(redCaida: true));
        final d = await c.entrar();
        expect(d.tipo, TipoDeDesenlace.sinConexion);
        expect(c.submitting.value, isFalse);
      },
    );

    test('con un campo vacío no llama al backend', () async {
      final auth = _AuthDePrueba();
      final c = _controlador(auth)..passwordController.text = '';
      final d = await c.entrar();
      expect(d.tipo, TipoDeDesenlace.error);
      expect(d.mensaje, 'Ingresa tu código y contraseña.');
      expect(auth.logins, 0);
    });

    test('Google cancelado no hace nada, un error trae su mensaje', () async {
      final cancelado = _controlador(_AuthDePrueba(google: 'cancelar'));
      expect(
        (await cancelado.entrarConGoogle()).tipo,
        TipoDeDesenlace.cancelado,
      );
      final conError = _controlador(
        _AuthDePrueba(google: 'Tu correo no está registrado en el sistema.'),
      );
      final d = await conError.entrarConGoogle();
      expect(d.tipo, TipoDeDesenlace.error);
      expect(d.mensaje, 'Tu correo no está registrado en el sistema.');
      final bien = _controlador(_AuthDePrueba());
      expect((await bien.entrarConGoogle()).tipo, TipoDeDesenlace.sesionPuesta);
    });

    test('vaciarCampos borra el código y la contraseña', () {
      final c = _controlador(_AuthDePrueba())..vaciarCampos();
      expect(c.codeController.text, '');
      expect(c.passwordController.text, '');
      expect(c.passwordVisible.value, isFalse);
    });
  });
}
