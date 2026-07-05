// lib/pages/password_reset/password_reset_ui.dart
// Paleta y widgets compartidos por las pantallas del flujo de recuperación
// de contraseña. Replica el estilo visual de la pantalla de login
// (card centrada, campos underline y soporte de dark mode).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show TextInputFormatter;

import '../../configs/themes.dart';

class PasswordResetPalette {
  const PasswordResetPalette({
    required this.background,
    required this.card,
    required this.cardBorder,
    required this.cardShadow,
    required this.fieldText,
    required this.fieldHint,
    required this.fieldLine,
    required this.focusedFieldLine,
    required this.cursor,
    required this.error,
    required this.buttonBackground,
    required this.buttonForeground,
    required this.disabledButtonBackground,
    required this.disabledButtonForeground,
    required this.buttonSide,
    required this.backIcon,
  });

  factory PasswordResetPalette.from(BuildContext context) {
    final isDark = Theme.brightnessOf(context) == Brightness.dark;

    if (isDark) {
      return const PasswordResetPalette(
        background: Color(0xFF262626),
        card: Color(0xFF050505),
        cardBorder: Color(0xFF262626),
        cardShadow: Color(0x99000000),
        fieldText: Color(0xFFF4F4F4),
        fieldHint: Color(0xFFEDEDED),
        fieldLine: Color(0xFFE7E7E7),
        focusedFieldLine: Color(0xFFFA7525),
        cursor: Color(0xFFFA7525),
        error: Color(0xFFFA7525),
        buttonBackground: Color(0x00000000),
        buttonForeground: Color(0xFFF4F4F4),
        disabledButtonBackground: Color(0x00000000),
        disabledButtonForeground: Color(0xFF8F8F8F),
        buttonSide: BorderSide(color: Color(0xFFE7E7E7), width: 1.5),
        backIcon: Color(0xFFF4F4F4),
      );
    }

    return const PasswordResetPalette(
      background: MaterialTheme.primaryColor,
      card: Colors.white,
      cardBorder: Colors.transparent,
      cardShadow: Color(0x33000000),
      fieldText: Color(0xFF1A1A1A),
      fieldHint: Color(0xFF9B9B9B),
      fieldLine: Color(0xFFCFCFCF),
      focusedFieldLine: MaterialTheme.primaryColor,
      cursor: MaterialTheme.primaryColor,
      error: MaterialTheme.primaryDark,
      buttonBackground: MaterialTheme.primaryColor,
      buttonForeground: Colors.white,
      disabledButtonBackground: Color(0x99FF6600),
      disabledButtonForeground: Colors.white,
      buttonSide: BorderSide.none,
      backIcon: Colors.white,
    );
  }

  final Color background;
  final Color card;
  final Color cardBorder;
  final Color cardShadow;
  final Color fieldText;
  final Color fieldHint;
  final Color fieldLine;
  final Color focusedFieldLine;
  final Color cursor;
  final Color error;
  final Color buttonBackground;
  final Color buttonForeground;
  final Color disabledButtonBackground;
  final Color disabledButtonForeground;
  final BorderSide buttonSide;
  final Color backIcon;
}

/// Scaffold común del flujo: fondo, flecha de retorno y card centrada.
class PasswordResetScaffold extends StatelessWidget {
  const PasswordResetScaffold({
    super.key,
    required this.palette,
    required this.child,
  });

  final PasswordResetPalette palette;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: palette.background,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 24,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 340),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: palette.card,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: palette.cardBorder),
                      boxShadow: [
                        BoxShadow(
                          color: palette.cardShadow,
                          blurRadius: 32,
                          offset: const Offset(0, 18),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(32, 36, 32, 32),
                      child: child,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 4,
              left: 4,
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: palette.backIcon),
                tooltip: 'Volver',
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Campo de texto underline con el mismo estilo del login.
class PasswordResetField extends StatelessWidget {
  const PasswordResetField({
    super.key,
    required this.controller,
    required this.palette,
    required this.hint,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.obscureText = false,
    this.onSubmitted,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final PasswordResetPalette palette;
  final String hint;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final bool obscureText;
  final ValueChanged<String>? onSubmitted;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      inputFormatters: inputFormatters,
      onSubmitted: onSubmitted,
      cursorColor: palette.cursor,
      style: TextStyle(
        color: palette.fieldText,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: palette.fieldHint,
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
        suffixIcon: suffixIcon,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        isDense: true,
        border: UnderlineInputBorder(
          borderSide: BorderSide(color: palette.fieldLine),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: palette.fieldLine),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: palette.focusedFieldLine, width: 1.5),
        ),
      ),
    );
  }
}

/// Botón principal del flujo, con spinner mientras se envía la solicitud.
class PasswordResetPrimaryButton extends StatelessWidget {
  const PasswordResetPrimaryButton({
    super.key,
    required this.palette,
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  final PasswordResetPalette palette;
  final String label;
  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: palette.buttonBackground,
          foregroundColor: palette.buttonForeground,
          disabledBackgroundColor: palette.disabledButtonBackground,
          disabledForegroundColor: palette.disabledButtonForeground,
          elevation: 0,
          padding: EdgeInsets.zero,
          side: palette.buttonSide,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: loading
            ? SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  color: palette.buttonForeground,
                  strokeWidth: 2.2,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
      ),
    );
  }
}

/// Mensaje de error centrado bajo los campos, estilo login.
class PasswordResetErrorMessage extends StatelessWidget {
  const PasswordResetErrorMessage({
    super.key,
    required this.palette,
    required this.message,
  });

  final PasswordResetPalette palette;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final msg = message;
    if (msg == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Text(
        msg,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: palette.error,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
