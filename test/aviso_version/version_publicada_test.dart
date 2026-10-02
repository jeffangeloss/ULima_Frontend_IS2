// test/aviso_version/version_publicada_test.dart
//
// UNITARIA · Aviso de versión nueva (specs/features/aviso-version/aviso-version.spec.md).
// RF-AVV-7 fija el formato de version.json y RF-AVV-6 que una versión inválida
// no muestra nada, así que VersionPublicada.desdeJson devuelve null ante un
// campo faltante o inválido.
// Archivo probado lib/models/version_publicada_model.dart.

import 'package:flutter_test/flutter_test.dart';
import 'package:ulima_plus/models/version_publicada_model.dart';

const String _apk =
    'https://github.com/meltiruiz/ULima_Frontend_IS2/releases/download/'
    'v1.2.0/ULimaPlus-build-78.apk';

Map<String, dynamic> _valido() => <String, dynamic>{
  'version': '1.2.0',
  'build': 78,
  'url': _apk,
};

void main() {
  group('VersionPublicada.desdeJson (RF-AVV-6 y RF-AVV-7)', () {
    test('lee el formato que publica build-apk.yml', () {
      final v = VersionPublicada.desdeJson(_valido());
      expect(v, isNotNull);
      expect(v!.version, '1.2.0');
      expect(v.build, 78);
      expect(v.url, Uri.parse(_apk));
    });

    test('ignora los campos que no conoce', () {
      final v = VersionPublicada.desdeJson(<String, dynamic>{
        ..._valido(),
        'notas': 'otra cosa',
      });
      expect(v?.version, '1.2.0');
    });

    test('devuelve null si falta cualquiera de los tres campos', () {
      for (final campo in <String>['version', 'build', 'url']) {
        final json = _valido()..remove(campo);
        expect(
          VersionPublicada.desdeJson(json),
          isNull,
          reason: 'sin «$campo»',
        );
      }
      expect(VersionPublicada.desdeJson(<String, dynamic>{}), isNull);
    });

    test('devuelve null si la versión no es una cadena X.Y.Z', () {
      const invalidas = <Object?>[
        '',
        '1.2',
        'v1.2.0',
        '1.2.0+3',
        'a.b.c',
        120,
        1.2,
        null,
        <String>['1.2.0'],
      ];
      for (final version in invalidas) {
        final json = _valido()..['version'] = version;
        expect(
          VersionPublicada.desdeJson(json),
          isNull,
          reason: 'version «$version»',
        );
      }
    });

    test('devuelve null si build no es un entero que no sea negativo', () {
      const invalidos = <Object?>['78', 78.5, -1, true, null];
      for (final build in invalidos) {
        final json = _valido()..['build'] = build;
        expect(
          VersionPublicada.desdeJson(json),
          isNull,
          reason: 'build «$build»',
        );
      }
      expect(
        VersionPublicada.desdeJson(_valido()..['build'] = 0)?.build,
        0,
        reason: 'el cero es un entero que no es negativo',
      );
    });

    test('devuelve null si la url no es https, absoluta y con servidor', () {
      const invalidas = <Object?>[
        '',
        'ULimaPlus-build-78.apk',
        '/releases/download/v1.2.0/ULimaPlus-build-78.apk',
        'http://github.com/meltiruiz/ULima_Frontend_IS2/releases/x.apk',
        'ftp://github.com/x.apk',
        'intent://scan/#Intent;scheme=zxing;end',
        'javascript:alert(1)',
        'https:///ULimaPlus-build-78.apk',
        'https://',
        'https://[::1',
        78,
        null,
        <String>[_apk],
      ];
      for (final url in invalidas) {
        final json = _valido()..['url'] = url;
        expect(VersionPublicada.desdeJson(json), isNull, reason: 'url «$url»');
      }
    });
  });
}
