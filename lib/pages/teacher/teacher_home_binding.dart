// lib/pages/teacher/teacher_home_binding.dart

import 'package:get/get.dart';

import 'teacher_home_controller.dart';

/// Binding por ruta de la pantalla del docente (regla del repo: nada de
/// Get.put en builds).
class TeacherHomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => TeacherHomeController());
  }
}
