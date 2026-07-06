// Guard estático: toda navegación al login debe pasar por offAllToLogin()
// (lib/services/session_navigation.dart). Una llamada directa a
// Get.offAllNamed('/login') puede apilar dos rutas /login (p. ej. el 401 del
// propio logout + el handler del botón), lo que destruye el LoginController
// de la página visible y produce "tipeo fantasma" en los campos (texto que
// no repinta al escribir). Ver el fix original y su análisis en el historial.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ninguna navegación directa a /login fuera de session_navigation.dart',
      () {
    final ofensores = <String>[];
    final directo = RegExp('''offAll(Named)?\\(\\s*['"]/login['"]''');

    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      if (entity.path.endsWith('session_navigation.dart')) continue;
      final contenido = entity.readAsStringSync();
      if (directo.hasMatch(contenido)) ofensores.add(entity.path);
    }

    expect(
      ofensores,
      isEmpty,
      reason: 'Usa offAllToLogin() de session_navigation.dart en vez de '
          'Get.offAllNamed(\'/login\') directo: la navegación doble al login '
          'rompe los campos (tipeo fantasma). Ofensores: $ofensores',
    );
  });
}
