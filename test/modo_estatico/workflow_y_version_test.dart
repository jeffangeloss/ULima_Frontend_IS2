// test/modo_estatico/workflow_y_version_test.dart
//
// UNITARIA · Versión estática del front (specs/features/modo-estatico/
// modo-estatico.spec.md), RF-EST-14.
// `build-apk.yml` compila con --dart-define=MODO_ESTATICO=true sin tocar el
// resto del comando, y la versión pasa a 2.0.0 en pubspec.yaml y en
// CHANGELOG.md. El workflow se lee como texto, como en
// test/aviso_version/aviso_version_workflow_test.dart.
// Archivos probados .github/workflows/build-apk.yml, pubspec.yaml y
// CHANGELOG.md.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _comandoDeCompilacion() {
  final lineas = File('.github/workflows/build-apk.yml').readAsLinesSync();
  final comando = lineas.where((l) => l.contains('flutter build apk'));
  expect(comando, hasLength(1));
  return comando.single;
}

void main() {
  group('RF-EST-14 · build-apk.yml', () {
    test('compila con --dart-define=MODO_ESTATICO=true, una sola vez', () {
      final comando = _comandoDeCompilacion();
      expect('--dart-define=MODO_ESTATICO=true'.allMatches(comando), hasLength(1));
      expect(comando, contains('MODO_ESTATICO=true'));
    });

    test('conserva el resto del comando', () {
      final comando = _comandoDeCompilacion();
      expect(comando, contains('flutter build apk --release'));
      expect(
        comando,
        contains('--build-name=\${{ steps.version.outputs.nombre }}'),
      );
      expect(comando, contains('--build-number=\${{ github.run_number }}'));
      expect(comando, contains('--dart-define=API_BASE_URL='));
      expect(
        comando,
        contains(
          '--dart-define=APP_VERSION=\${{ steps.version.outputs.nombre }}',
        ),
      );
    });

    test('es YAML válido en lo que importa: sigue en el job y el paso de '
        'compilar', () {
      final texto = File('.github/workflows/build-apk.yml').readAsStringSync();
      expect(texto, contains('name: Build and Release APK'));
      expect(texto, contains('- name: Compilar APK'));
      expect(texto.contains('\t'), isFalse);
    });
  });

  group('RF-EST-14 · la versión 2.0.0', () {
    test('pubspec.yaml dice 2.0.0+1', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      expect(RegExp(r'^version: 2\.0\.0\+1$', multiLine: true).hasMatch(pubspec),
          isTrue);
    });

    test('CHANGELOG.md abre con la sección 2.0.0 y enlaza la comparación', () {
      final cambios = File('CHANGELOG.md').readAsStringSync();
      expect(cambios, contains('## [2.0.0] - 2026-10-02'));
      expect(
        cambios.indexOf('## [2.0.0]'),
        lessThan(cambios.indexOf('## [1.2.0]')),
      );
      expect(cambios, contains('MODO_ESTATICO'));
      expect(cambios, contains('[2.0.0]: '));
      expect(cambios, contains('v1.2.0...v2.0.0'));
    });
  });
}
