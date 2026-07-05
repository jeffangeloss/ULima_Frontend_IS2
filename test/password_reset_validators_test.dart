// test/password_reset_validators_test.dart
// Validadores locales del flujo de recuperación de contraseña (HU20).

import 'package:flutter_test/flutter_test.dart';
import 'package:ulima_plus/pages/password_reset/password_reset_validators.dart';

void main() {
  group('validateResetCode', () {
    test('acepta un código de 6 dígitos numéricos', () {
      expect(validateResetCode('123456'), isNull);
    });

    test('acepta un código válido con espacios alrededor', () {
      expect(validateResetCode('  654321  '), isNull);
    });

    test('rechaza un código vacío', () {
      expect(validateResetCode(''), 'Ingresa el código de verificación.');
    });

    test('rechaza un código con menos de 6 dígitos', () {
      expect(
        validateResetCode('12345'),
        'El código debe tener 6 dígitos numéricos.',
      );
    });

    test('rechaza un código con más de 6 dígitos', () {
      expect(
        validateResetCode('1234567'),
        'El código debe tener 6 dígitos numéricos.',
      );
    });

    test('rechaza un código con caracteres no numéricos', () {
      expect(
        validateResetCode('12a456'),
        'El código debe tener 6 dígitos numéricos.',
      );
    });
  });

  group('validateNewPassword', () {
    test('acepta una contraseña de exactamente 8 caracteres', () {
      expect(validateNewPassword('abcd1234'), isNull);
    });

    test('acepta una contraseña larga', () {
      expect(validateNewPassword('unaClaveMuySegura!2026'), isNull);
    });

    test('rechaza una contraseña vacía', () {
      expect(validateNewPassword(''), 'Ingresa tu nueva contraseña.');
    });

    test('rechaza una contraseña de menos de 8 caracteres', () {
      expect(
        validateNewPassword('abc1234'),
        'La contraseña debe tener al menos 8 caracteres.',
      );
    });
  });

  group('validatePasswordConfirmation', () {
    test('acepta cuando la confirmación coincide', () {
      expect(validatePasswordConfirmation('abcd1234', 'abcd1234'), isNull);
    });

    test('rechaza una confirmación vacía', () {
      expect(
        validatePasswordConfirmation('abcd1234', ''),
        'Confirma tu nueva contraseña.',
      );
    });

    test('rechaza cuando la confirmación no coincide', () {
      expect(
        validatePasswordConfirmation('abcd1234', 'abcd1235'),
        'Las contraseñas no coinciden.',
      );
    });
  });

  group('validatePasswordResetForm', () {
    test('devuelve null cuando todo el formulario es válido', () {
      expect(
        validatePasswordResetForm(
          code: '123456',
          newPassword: 'abcd1234',
          confirmation: 'abcd1234',
        ),
        isNull,
      );
    });

    test('devuelve primero el error del código', () {
      expect(
        validatePasswordResetForm(
          code: 'abc',
          newPassword: 'corta',
          confirmation: 'otra',
        ),
        'El código debe tener 6 dígitos numéricos.',
      );
    });

    test('devuelve el error de contraseña si el código es válido', () {
      expect(
        validatePasswordResetForm(
          code: '123456',
          newPassword: 'corta',
          confirmation: 'corta',
        ),
        'La contraseña debe tener al menos 8 caracteres.',
      );
    });

    test('devuelve el error de confirmación al final', () {
      expect(
        validatePasswordResetForm(
          code: '123456',
          newPassword: 'abcd1234',
          confirmation: 'distinta1',
        ),
        'Las contraseñas no coinciden.',
      );
    });
  });
}
