// lib/pages/password_reset/password_reset_validators.dart
// Validadores locales puros del flujo de recuperación de contraseña (HU20).
// Devuelven null si el valor es válido, o el mensaje de error en español.

const int passwordResetCodeLength = 6;
const int passwordResetMinPasswordLength = 8;

final RegExp _codeRegExp = RegExp(r'^\d{6}$');

/// El código debe tener exactamente 6 dígitos numéricos.
String? validateResetCode(String code) {
  final trimmed = code.trim();
  if (trimmed.isEmpty) {
    return 'Ingresa el código de verificación.';
  }
  if (!_codeRegExp.hasMatch(trimmed)) {
    return 'El código debe tener $passwordResetCodeLength dígitos numéricos.';
  }
  return null;
}

/// La nueva contraseña debe tener al menos 8 caracteres.
String? validateNewPassword(String password) {
  if (password.isEmpty) {
    return 'Ingresa tu nueva contraseña.';
  }
  if (password.length < passwordResetMinPasswordLength) {
    return 'La contraseña debe tener al menos '
        '$passwordResetMinPasswordLength caracteres.';
  }
  return null;
}

/// La confirmación debe coincidir con la nueva contraseña.
String? validatePasswordConfirmation(String password, String confirmation) {
  if (confirmation.isEmpty) {
    return 'Confirma tu nueva contraseña.';
  }
  if (password != confirmation) {
    return 'Las contraseñas no coinciden.';
  }
  return null;
}

/// Valida el formulario completo del paso 2 y devuelve el primer error, o null.
String? validatePasswordResetForm({
  required String code,
  required String newPassword,
  required String confirmation,
}) {
  return validateResetCode(code) ??
      validateNewPassword(newPassword) ??
      validatePasswordConfirmation(newPassword, confirmation);
}
