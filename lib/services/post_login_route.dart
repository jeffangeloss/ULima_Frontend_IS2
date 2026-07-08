// lib/services/post_login_route.dart
// Unica fuente de verdad de la ruta destino tras autenticar.

import '../models/user_model.dart';

/// Ruta inicial segun el rol y el estado de setup del usuario.
///
/// - Docente/JP (TT09): home shell con navegacion docente.
/// - Alumno con setup completo: home.
/// - Alumno sin setup: seleccion de carrera/especialidad.
String postLoginRoute(UserModel user) {
  if (user.isTeacher) return '/home';
  return user.setupComplete ? '/home' : '/setup-carrera';
}
