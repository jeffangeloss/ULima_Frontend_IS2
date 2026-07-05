// lib/pages/password_reset/reset_password_controller.dart
// Paso 2 de la recuperación de contraseña: confirmar el código y definir
// la nueva contraseña. Funciona tanto desde el login (paso 1 previo) como
// desde el Perfil (modo autenticado, con correo enmascarado).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../services/password_reset_service.dart';
import '../../services/storage_service.dart';
import 'password_reset_validators.dart';

class ResetPasswordController extends GetxController {
  static const int resendCooldownSeconds = 60;

  final codeController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  final errorMessage = RxnString();
  final submitting = false.obs;
  final resending = false.obs;
  final passwordVisible = false.obs;
  final confirmVisible = false.obs;

  /// Segundos restantes del cooldown de "Reenviar código" (0 = habilitado).
  final resendCooldown = 0.obs;
  Timer? _cooldownTimer;

  /// Código de alumno o correo con el que se solicitó el código.
  String identifier = '';

  /// Correo enmascarado (solo en el flujo autenticado desde Perfil).
  String? maskedEmail;

  final PasswordResetService _service = PasswordResetService();

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map) {
      identifier = args['identifier']?.toString() ?? '';
      final masked = args['maskedEmail']?.toString();
      maskedEmail = (masked == null || masked.isEmpty) ? null : masked;
    }
    if (identifier.isEmpty) {
      // Llegada sin argumentos (p. ej. refresh del navegador en web o URL
      // directa): sin identifier no se puede confirmar, se vuelve al paso 1.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.offNamed('/forgot-password');
      });
    }
  }

  Future<void> submit() async {
    final code = codeController.text.trim();
    final newPassword = passwordController.text;
    final confirmation = confirmController.text;

    final localError = validatePasswordResetForm(
      code: code,
      newPassword: newPassword,
      confirmation: confirmation,
    );
    if (localError != null) {
      errorMessage.value = localError;
      return;
    }
    if (identifier.isEmpty) {
      errorMessage.value =
          'No se pudo restablecer la contraseña. Vuelve a solicitar el código.';
      return;
    }

    errorMessage.value = null;
    submitting.value = true;

    try {
      await _service.confirm(
        identifier: identifier,
        code: code,
        newPassword: newPassword,
      );
      // La contraseña cambió: se invalida cualquier sesión local y se vuelve
      // al login. Se limpia el token antes para que logout() no llame al
      // backend con credenciales ya inválidas.
      await StorageService.to.clearToken();
      await AuthService.to.logout();
      Get.offAllNamed('/login');
      Get.snackbar(
        'Contraseña actualizada',
        'Inicia sesión con tu nueva contraseña.',
      );
    } on ApiException catch (e) {
      errorMessage.value = e.message;
    } catch (_) {
      errorMessage.value =
          'No se pudo restablecer la contraseña. Intenta de nuevo.';
    } finally {
      submitting.value = false;
    }
  }

  Future<void> resendCode() async {
    if (resendCooldown.value > 0 || resending.value || submitting.value) {
      return;
    }
    if (identifier.isEmpty) {
      errorMessage.value = 'No se pudo reenviar el código. Vuelve a empezar.';
      return;
    }

    errorMessage.value = null;
    resending.value = true;

    try {
      final message = await _service.request(identifier);
      _startCooldown();
      Get.snackbar('Código reenviado', message);
    } on ApiException catch (e) {
      errorMessage.value = e.message;
    } catch (_) {
      errorMessage.value = 'No se pudo reenviar el código. Intenta de nuevo.';
    } finally {
      resending.value = false;
    }
  }

  void _startCooldown() {
    resendCooldown.value = resendCooldownSeconds;
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (resendCooldown.value <= 1) {
        resendCooldown.value = 0;
        timer.cancel();
      } else {
        resendCooldown.value--;
      }
    });
  }

  @override
  void onClose() {
    _cooldownTimer?.cancel();
    codeController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.onClose();
  }
}
