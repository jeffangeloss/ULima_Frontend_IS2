// lib/pages/password_reset/reset_password_page.dart
// Paso 2 de la recuperación de contraseña (HU20): código + nueva contraseña.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'password_reset_ui.dart';
import 'password_reset_validators.dart';
import 'reset_password_controller.dart';

class ResetPasswordPage extends StatelessWidget {
  const ResetPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ResetPasswordController());
    final palette = PasswordResetPalette.from(context);

    return PasswordResetScaffold(
      palette: palette,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Restablecer contraseña',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: palette.fieldText,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            controller.maskedEmail != null
                ? 'Enviamos un código de verificación a '
                      '${controller.maskedEmail}.'
                : 'Ingresa el código de $passwordResetCodeLength dígitos '
                      'que enviamos a tu correo institucional.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: palette.fieldHint,
              fontSize: 12.5,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 26),
          PasswordResetField(
            controller: controller.codeController,
            palette: palette,
            hint: 'Código de $passwordResetCodeLength dígitos',
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(passwordResetCodeLength),
            ],
          ),
          const SizedBox(height: 18),
          Obx(
            () => PasswordResetField(
              controller: controller.passwordController,
              palette: palette,
              hint: 'Nueva contraseña',
              obscureText: !controller.passwordVisible.value,
              textInputAction: TextInputAction.next,
              suffixIcon: _VisibilityToggle(
                palette: palette,
                visible: controller.passwordVisible.value,
                onPressed: () => controller.passwordVisible.toggle(),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Obx(
            () => PasswordResetField(
              controller: controller.confirmController,
              palette: palette,
              hint: 'Confirmar contraseña',
              obscureText: !controller.confirmVisible.value,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => controller.submit(),
              suffixIcon: _VisibilityToggle(
                palette: palette,
                visible: controller.confirmVisible.value,
                onPressed: () => controller.confirmVisible.toggle(),
              ),
            ),
          ),
          Obx(
            () => PasswordResetErrorMessage(
              palette: palette,
              message: controller.errorMessage.value,
            ),
          ),
          const SizedBox(height: 28),
          Obx(
            () => PasswordResetPrimaryButton(
              palette: palette,
              label: 'Confirmar',
              loading: controller.submitting.value,
              onPressed: controller.submit,
            ),
          ),
          const SizedBox(height: 10),
          _ResendLink(controller: controller, palette: palette),
        ],
      ),
    );
  }
}

class _VisibilityToggle extends StatelessWidget {
  const _VisibilityToggle({
    required this.palette,
    required this.visible,
    required this.onPressed,
  });

  final PasswordResetPalette palette;
  final bool visible;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        size: 20,
        color: palette.fieldHint,
      ),
      onPressed: onPressed,
      splashRadius: 18,
    );
  }
}

class _ResendLink extends StatelessWidget {
  const _ResendLink({required this.controller, required this.palette});

  final ResetPasswordController controller;
  final PasswordResetPalette palette;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final cooldown = controller.resendCooldown.value;
      final resending = controller.resending.value;
      final enabled = cooldown == 0 && !resending;
      final label = resending
          ? 'Reenviando...'
          : cooldown > 0
          ? 'Reenviar código (${cooldown}s)'
          : 'Reenviar código';

      return Center(
        child: TextButton(
          onPressed: enabled ? controller.resendCode : null,
          style: TextButton.styleFrom(
            foregroundColor: palette.fieldText,
            disabledForegroundColor: palette.fieldHint,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    });
  }
}
