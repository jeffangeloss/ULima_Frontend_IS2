// lib/pages/teacher/teacher_home_controller.dart

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../models/advising_models.dart';
import '../../services/advising_service.dart';
import '../../services/auth_service.dart';
import '../../services/session_navigation.dart';

class TeacherHomeController extends GetxController {
  final AdvisingService _service = AdvisingService();

  final sessions = <AdvisingSession>[].obs;
  final isLoading = false.obs;
  final loadError = RxnString();

  /// Etiqueta del docente para el header ("Profesor" / "Jefe de Práctica").
  String get roleLabel => AuthService.to.currentUser?.teacherLabel ?? 'Docente';
  String get displayName => AuthService.to.currentUser?.fullName ?? '';

  @override
  void onInit() {
    super.onInit();
    loadSessions();
  }

  Future<void> loadSessions() async {
    isLoading.value = true;
    loadError.value = null;
    try {
      sessions.assignAll(await _service.fetchSessions());
    } catch (e) {
      loadError.value = 'No se pudieron cargar tus asesorías.';
      debugPrint('Error cargando asesorías del docente: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Abre el formulario de creación y recarga si se creó una asesoría.
  Future<void> openCreate() async {
    final created = await Get.toNamed('/teacher-advising-create');
    if (created == true) await loadSessions();
  }

  Future<void> deleteSession(AdvisingSession session) async {
    try {
      await _service.deleteSession(session.id);
      sessions.removeWhere((s) => s.id == session.id);
      Get.snackbar('Listo', 'Asesoría eliminada.');
    } catch (e) {
      debugPrint('Error eliminando asesoría: $e');
      Get.snackbar('No se pudo eliminar', 'Vuelve a intentarlo.');
    }
  }

  void openAttendees(AdvisingSession session) {
    Get.toNamed('/teacher-advising-attendees', arguments: {
      'sessionId': session.id,
      'title': session.courseName,
    });
  }

  Future<void> logout() async {
    await AuthService.to.logout();
    offAllToLogin();
  }
}
