// test/HU01_jeff/login_error_mapping_test.dart
//
// PRUEBA UNITARIA — HU01 (Iniciar sesión), lado CLIENTE.
// Método: AuthService.loginErrorMessage(code, backendMessage)
//   lib/services/auth_service.dart
//
// Complementa la caja blanca de HU01 del backend (AuthService.login): aquí se
// valida cómo el cliente Flutter traduce el CÓDIGO de error del backend al
// mensaje que ve el usuario. Era un hueco de cobertura real (nadie probaba el
// mapeo de errores del login en el frontend). Función pura → sin red ni GetX.

import 'package:flutter_test/flutter_test.dart';
import 'package:ulima_plus/services/auth_service.dart';

void main() {
  group('UNITARIA · AuthService.loginErrorMessage (HU01)', () {
    test('caso 1: USER_NOT_FOUND → mensaje genérico (no revela si la cuenta existe)', () {
      expect(
        AuthService.loginErrorMessage('USER_NOT_FOUND', 'Código no encontrado.'),
        AuthService.invalidCredentialsMessage,
      );
    });

    test('caso 2: INVALID_PASSWORD → el MISMO mensaje genérico que USER_NOT_FOUND', () {
      expect(
        AuthService.loginErrorMessage('INVALID_PASSWORD', 'Contraseña incorrecta.'),
        AuthService.invalidCredentialsMessage,
      );
    });

    test('caso 3: NOT_ENROLLED → mensaje específico de matrícula', () {
      expect(
        AuthService.loginErrorMessage('NOT_ENROLLED', 'El estudiante no tiene matrícula activa.'),
        'No tienes una matrícula activa.',
      );
    });

    test('caso 4: código desconocido → propaga el mensaje del backend', () {
      expect(
        AuthService.loginErrorMessage('RATE_LIMITED', 'Demasiados intentos, espera un momento.'),
        'Demasiados intentos, espera un momento.',
      );
    });

  });
}
