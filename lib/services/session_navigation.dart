// lib/services/session_navigation.dart
// Navegación idempotente hacia la pantalla de login.
//
// TODOS los caminos que terminan la sesión (logout del Perfil, interceptor
// 401 del ApiClient, éxito del reset de contraseña) deben navegar por aquí,
// nunca con Get.offAllNamed('/login') directo.
//
// Motivo: si dos de esos caminos coinciden (p. ej. el POST /auth/logout
// responde 401 y el interceptor navega mientras el handler del botón de
// logout también va a hacerlo), un doble Get.offAllNamed('/login') apila DOS
// rutas /login. El binding de la segunda ruta no re-registra el
// LoginController (GetX ignora lazyPut si la instancia de la primera ruta
// sigue registrada), así que la página visible reutiliza ese controller; al
// desecharse la primera ruta, GetX lo elimina y dispone sus
// TextEditingControllers MIENTRAS la página visible los sigue usando. En
// release un ChangeNotifier disposed deja de notificar: el campo recibe cada
// tecla pero no repinta ("tipeo fantasma") hasta que otro evento (perder el
// foco) fuerza el rebuild; en debug revienta con "A TextEditingController
// was used after being disposed".
//
// Get.currentRoute se actualiza de forma síncrona en el didPush del
// observer, por lo que la guarda no tiene ventana de carrera entre dos
// llamadas consecutivas.

import 'package:get/get.dart';

/// Limpia el stack y navega a /login una sola vez.
///
/// Devuelve `true` si efectivamente navegó; `false` si no había navegador
/// montado todavía (arranque de la app) o si /login ya es la ruta actual
/// (incluida una navegación a /login aún en transición).
bool offAllToLogin() {
  if (Get.context == null) return false;
  final alreadyOnLogin =
      Get.currentRoute == '/login' || Get.currentRoute == '/LoginPage';
  if (alreadyOnLogin) return false;
  Get.offAllNamed('/login');
  return true;
}
