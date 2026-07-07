// lib/pages/login/login_controller.dart

import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../services/auth_service.dart';
import '../../services/post_login_route.dart';

class LoginController extends GetxController {
  final codeController = TextEditingController();
  final passwordController = TextEditingController();
  final errorMessage = RxnString();
  final submitting = false.obs;
  final passwordVisible = false.obs;

  AuthService get _auth => AuthService.to;

  StreamSubscription<GoogleSignInAccount?>? _googleSub;

  @override
  void onInit() {
    super.onInit();
    // En web el login con Google se hace con el botón oficial (renderButton):
    // la cuenta llega por este stream, no por un Future.
    if (kIsWeb) {
      _googleSub =
          _auth.googleSignIn.onCurrentUserChanged.listen(_onGoogleUserChanged);
    }
  }

  Future<void> _onGoogleUserChanged(GoogleSignInAccount? account) async {
    if (account == null || submitting.value) return;
    errorMessage.value = null;
    submitting.value = true;
    final error = await _auth.finishGoogleLogin(account);
    submitting.value = false;
    if (error != null) {
      errorMessage.value = error;
      return;
    }
    final user = _auth.currentUser!;
    Get.offAllNamed(postLoginRoute(user));
  }

  Future<void> submit() async {
    final code = codeController.text.trim();
    final password = passwordController.text;

    if (code.isEmpty || password.isEmpty) {
      errorMessage.value = 'Ingresa tu código y contraseña.';
      return;
    }

    errorMessage.value = null;
    submitting.value = true;

    final error = await _auth.login(code: code, password: password);

    submitting.value = false;

    if (error != null) {
      errorMessage.value = error;
      return;
    }

    final user = _auth.currentUser!;
    Get.offAllNamed(postLoginRoute(user));
  }

  Future<void> loginWithGoogle() async {
    errorMessage.value = null;
    submitting.value = true;

    final error = await _auth.loginWithGoogle();

    submitting.value = false;

    if (error != null) {
      errorMessage.value = error;
      return;
    }

    final user = _auth.currentUser!;
    Get.offAllNamed(postLoginRoute(user));
  }

  @override
  void onClose() {
    _googleSub?.cancel();
    codeController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
