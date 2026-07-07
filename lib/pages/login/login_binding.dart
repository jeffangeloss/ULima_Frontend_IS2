// lib/pages/login/login_binding.dart
// Binding de la ruta /login.
//
// Registra el LoginController como PERMANENTE. Motivo (bug del "tipeo
// fantasma"): con un binding normal (`lazyPut`), cuando se navega a /login con
// offAllToLogin() y ya había otra ruta /login enterrada en el stack, al
// eliminarse esa ruta vieja GetX dispone el LoginController (y sus
// TextEditingController) que su RouterReportManager tiene asociado a ese tag —
// incluso si la pantalla visible los está usando. En release un ChangeNotifier
// disposed deja de notificar: el campo recibe la tecla pero repinta tarde
// ("se demora en presentarse lo tecleado").
//
// Al ser permanente, GetX NO lo dispone por cambios de ruta, así que sus
// TextEditingController nunca mueren bajo la pantalla visible. El fix es
// general: cubre todos los caminos a /login (logout, 401, reset desde el login
// o desde el Perfil), sin importar el estado del stack. Al reingresar se
// limpian los campos (resetFields) para no arrastrar lo tecleado por una
// sesión/usuario anterior.

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import 'login_controller.dart';

class LoginBinding extends Bindings {
  @override
  void dependencies() {
    if (Get.isRegistered<LoginController>()) {
      // Reusar la instancia permanente. Se limpian los campos DESPUÉS del frame
      // actual: hacerlo durante el binding (que corre en pleno build de la
      // ruta) dispararía "setState() called during build" al notificar al
      // TextField todavía montado de la /login anterior.
      final controller = Get.find<LoginController>();
      WidgetsBinding.instance.addPostFrameCallback((_) => controller.resetFields());
    } else {
      Get.put(LoginController(), permanent: true);
    }
  }
}
