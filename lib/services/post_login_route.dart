// lib/services/post_login_route.dart
// Única fuente de verdad de la ruta destino tras autenticar. La usan los 4
// caminos que deciden a dónde ir después del login (arranque en main.dart y
// los tres flujos del LoginController: código, Google móvil y Google web).

import '../models/user_model.dart';

/// Ruta inicial según el rol y el estado de setup del usuario.
///
/// - Docente (HU18): pantalla de docente (no aplica el setup de carrera).
/// - Alumno con setup completo: home.
/// - Alumno sin setup: selección de carrera/especialidad.
String postLoginRoute(UserModel user) {
  if (user.isTeacher) return '/teacher-home';
  return user.setupComplete ? '/home' : '/setup-carrera';
}
