// test/aviso_version/aviso_version_service_test.dart
//
// UNITARIA · Aviso de versión nueva (specs/features/aviso-version/aviso-version.spec.md).
// RF-AVV-1 fija la fuente, el tope de 5 s y que sin APP_VERSION no se pide
// nada. RF-AVV-3 decide cuándo avisar a partir de la versión instalada y de la
// pospuesta, RF-AVV-4 guarda la pospuesta y RF-AVV-6 que cualquier falla deja
// la app en silencio. Todo con package:http/testing y shared_preferences
// simulado, sin tocar la red.
// Archivo probado lib/services/aviso_version_service.dart.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ulima_plus/services/aviso_version_service.dart';

const String _fuenteReal =
    'https://github.com/meltiruiz/ULima_Frontend_IS2/releases/download/'
    'latest/version.json';

String _apk(String version, int build) =>
    'https://github.com/meltiruiz/ULima_Frontend_IS2/releases/download/'
    'v$version/ULimaPlus-build-$build.apk';

/// El cuerpo que publica build-apk.yml para [version].
String _json(String version, {int build = 78, Object? url}) =>
    jsonEncode(<String, Object?>{
      'version': version,
      'build': build,
      'url': url ?? _apk(version, build),
    });

/// Un cliente que anota cada petición y responde con [respuesta].
class _Servidor {
  _Servidor(this.respuesta) {
    cliente = MockClient((peticion) async {
      peticiones.add(peticion);
      return respuesta(peticion);
    });
  }

  final http.Response Function(http.Request) respuesta;
  final List<http.Request> peticiones = <http.Request>[];
  late final MockClient cliente;

  factory _Servidor.publica(String version, {int build = 78}) =>
      _Servidor((_) => http.Response(_json(version, build: build), 200));

  factory _Servidor.con(int estado, [String cuerpo = '']) =>
      _Servidor((_) => http.Response(cuerpo, estado));
}

AvisoVersionService _servicio(
  _Servidor servidor, {
  String instalada = '1.1.0',
  Duration tope = const Duration(seconds: 5),
}) => AvisoVersionService(
  cliente: servidor.cliente,
  versionInstalada: instalada,
  tope: tope,
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  group('cuándo avisar (RF-AVV-3)', () {
    test('instalada 1.1.0, publicada 1.2.0 y sin pospuesta devuelve la '
        'publicada', () async {
      final servidor = _Servidor.publica('1.2.0', build: 78);
      final v = await _servicio(servidor).versionParaAvisar();
      expect(v, isNotNull);
      expect(v!.version, '1.2.0');
      expect(v.build, 78);
      expect(v.url, Uri.parse(_apk('1.2.0', 78)));
    });

    test('con la publicada igual a la instalada no avisa', () async {
      final v = await _servicio(
        _Servidor.publica('1.2.0'),
        instalada: '1.2.0',
      ).versionParaAvisar();
      expect(v, isNull);
    });

    test('con la publicada menor que la instalada no avisa', () async {
      final v = await _servicio(
        _Servidor.publica('1.2.0'),
        instalada: '1.3.0',
      ).versionParaAvisar();
      expect(v, isNull);
    });

    test('compara en número, así que 1.10.0 avisa a quien tiene 1.9.0 y 1.9.0 '
        'no avisa a quien tiene 1.10.0', () async {
      expect(
        (await _servicio(
          _Servidor.publica('1.10.0'),
          instalada: '1.9.0',
        ).versionParaAvisar())?.version,
        '1.10.0',
      );
      expect(
        await _servicio(
          _Servidor.publica('1.9.0'),
          instalada: '1.10.0',
        ).versionParaAvisar(),
        isNull,
      );
    });

    test('con la pospuesta igual a la publicada no avisa', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'aviso_version_pospuesta': '1.2.0',
      });
      final v = await _servicio(_Servidor.publica('1.2.0')).versionParaAvisar();
      expect(v, isNull);
    });

    test('con la pospuesta mayor que la publicada tampoco avisa', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'aviso_version_pospuesta': '1.3.0',
      });
      final v = await _servicio(_Servidor.publica('1.2.0')).versionParaAvisar();
      expect(v, isNull);
    });

    test('con una publicada mayor que la pospuesta vuelve a avisar', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'aviso_version_pospuesta': '1.2.0',
      });
      final v = await _servicio(_Servidor.publica('1.3.0')).versionParaAvisar();
      expect(v?.version, '1.3.0');
    });

    test('una pospuesta que no es una versión se ignora', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'aviso_version_pospuesta': 'cualquier cosa',
      });
      final v = await _servicio(_Servidor.publica('1.2.0')).versionParaAvisar();
      expect(v?.version, '1.2.0');
    });
  });

  group('la consulta (RF-AVV-1)', () {
    test(
      'pide version.json del release latest, con GET y una sola vez',
      () async {
        final servidor = _Servidor.publica('1.2.0');
        await _servicio(servidor).versionParaAvisar();
        expect(servidor.peticiones, hasLength(1));
        expect(servidor.peticiones.single.method, 'GET');
        expect(servidor.peticiones.single.url, Uri.parse(_fuenteReal));
      },
    );

    test('la fuente se puede cambiar al construir el servicio', () async {
      final servidor = _Servidor.publica('1.2.0');
      final otra = Uri.parse('https://ejemplo.test/otra/version.json');
      await AvisoVersionService(
        cliente: servidor.cliente,
        versionInstalada: '1.1.0',
        fuente: otra,
      ).versionParaAvisar();
      expect(servidor.peticiones.single.url, otra);
    });

    test('con la versión instalada vacía no hace ninguna petición', () async {
      final servidor = _Servidor.publica('1.2.0');
      final v = await _servicio(servidor, instalada: '').versionParaAvisar();
      expect(v, isNull);
      expect(servidor.peticiones, isEmpty);
    });

    test(
      'con una versión instalada que no es X.Y.Z tampoco pide nada',
      () async {
        for (final instalada in <String>['dev', '1.2', 'v1.2.0', '1.2.0+3']) {
          final servidor = _Servidor.publica('9.9.9');
          final v = await _servicio(
            servidor,
            instalada: instalada,
          ).versionParaAvisar();
          expect(v, isNull, reason: 'instalada «$instalada»');
          expect(
            servidor.peticiones,
            isEmpty,
            reason: 'instalada «$instalada»',
          );
        }
      },
    );

    test('sin APP_VERSION en la compilación, la versión instalada queda vacía '
        'y no se pide nada', () async {
      // Estas pruebas corren sin --dart-define=APP_VERSION.
      expect(const String.fromEnvironment('APP_VERSION'), isEmpty);
      final servidor = _Servidor.publica('9.9.9');
      final servicio = AvisoVersionService(cliente: servidor.cliente);
      expect(servicio.versionInstalada, isEmpty);
      expect(await servicio.versionParaAvisar(), isNull);
      expect(servidor.peticiones, isEmpty);
    });

    test('el tope por defecto es de 5 s', () {
      expect(AvisoVersionService().tope, const Duration(seconds: 5));
    });

    test(
      'cierra el cliente que crea él mismo y no el que le inyectan',
      () async {
        final propio = _ClienteQueAnotaElCierre(
          (_) async => http.Response(_json('1.2.0'), 200),
        );
        final v = await http.runWithClient(
          () => AvisoVersionService(
            versionInstalada: '1.1.0',
          ).versionParaAvisar(),
          () => propio,
        );
        expect(v?.version, '1.2.0');
        expect(propio.cerrado, isTrue);

        final inyectado = _ClienteQueAnotaElCierre(
          (_) async => http.Response(_json('1.2.0'), 200),
        );
        await AvisoVersionService(
          cliente: inyectado,
          versionInstalada: '1.1.0',
        ).versionParaAvisar();
        expect(inyectado.cerrado, isFalse);
      },
    );
  });

  group('las fallas dejan la app en silencio (RF-AVV-6)', () {
    test('un 404 devuelve null', () async {
      expect(await _servicio(_Servidor.con(404)).versionParaAvisar(), isNull);
    });

    test('otra respuesta distinta de 200 devuelve null, aunque traiga un '
        'cuerpo válido', () async {
      for (final estado in <int>[201, 204, 301, 403, 429, 500, 503]) {
        final servidor = _Servidor.con(estado, _json('1.2.0'));
        expect(
          await _servicio(servidor).versionParaAvisar(),
          isNull,
          reason: 'estado $estado',
        );
      }
    });

    test('un JSON roto devuelve null', () async {
      for (final cuerpo in <String>[
        '',
        '{"version": "1.2.0", ',
        'no es json',
        '<html>404</html>',
      ]) {
        expect(
          await _servicio(_Servidor.con(200, cuerpo)).versionParaAvisar(),
          isNull,
          reason: 'cuerpo «$cuerpo»',
        );
      }
    });

    test('un JSON que no es un objeto devuelve null', () async {
      for (final cuerpo in <String>['[]', '"1.2.0"', '12', 'null', 'true']) {
        expect(
          await _servicio(_Servidor.con(200, cuerpo)).versionParaAvisar(),
          isNull,
          reason: 'cuerpo «$cuerpo»',
        );
      }
    });

    test('una versión inválida devuelve null', () async {
      for (final version in <String>['', '1.2', 'v1.2.0', '1.2.0+3', 'a.b.c']) {
        final servidor = _Servidor.con(200, _json(version));
        expect(
          await _servicio(servidor).versionParaAvisar(),
          isNull,
          reason: 'version «$version»',
        );
      }
    });

    test('una url ausente devuelve null', () async {
      final cuerpo = jsonEncode(<String, Object?>{
        'version': '1.2.0',
        'build': 78,
      });
      expect(
        await _servicio(_Servidor.con(200, cuerpo)).versionParaAvisar(),
        isNull,
      );
    });

    test('una url que no es https devuelve null', () async {
      final cuerpo = _json('1.2.0', url: 'http://ejemplo.test/ULimaPlus.apk');
      expect(
        await _servicio(_Servidor.con(200, cuerpo)).versionParaAvisar(),
        isNull,
      );
    });

    test('una respuesta más lenta que el tope devuelve null', () async {
      // La respuesta llega con una versión nueva y válida, así que solo el
      // tope puede impedir que el aviso salga.
      final servidor = _Servidor((_) => http.Response(_json('1.2.0'), 200));
      final lenta = MockClient((peticion) async {
        await Future<void>.delayed(const Duration(milliseconds: 400));
        return servidor.respuesta(peticion);
      });
      final v = await AvisoVersionService(
        cliente: lenta,
        versionInstalada: '1.1.0',
        tope: const Duration(milliseconds: 40),
      ).versionParaAvisar();
      expect(v, isNull);
    });

    test('una falla de red devuelve null en lugar de lanzar', () async {
      for (final error in <Object>[
        http.ClientException('sin red'),
        const FormatException('mal formado'),
        StateError('cualquier cosa'),
      ]) {
        final cliente = MockClient((_) async => throw error);
        final v = await AvisoVersionService(
          cliente: cliente,
          versionInstalada: '1.1.0',
        ).versionParaAvisar();
        expect(v, isNull, reason: 'error $error');
      }
    });

    test(
      'una falla de shared_preferences devuelve null en lugar de lanzar',
      () async {
        final v = await AvisoVersionService(
          cliente: _Servidor.publica('1.2.0').cliente,
          versionInstalada: '1.1.0',
          preferencias: () async => throw StateError('sin almacén'),
        ).versionParaAvisar();
        expect(v, isNull);
      },
    );
  });

  group('posponer (RF-AVV-4)', () {
    test("posponer('1.2.0') guarda aviso_version_pospuesta = 1.2.0", () async {
      final servicio = _servicio(_Servidor.publica('1.2.0'));
      await servicio.posponer('1.2.0');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('aviso_version_pospuesta'), '1.2.0');
    });

    test('lo pospuesto hace que la misma versión no vuelva a avisar', () async {
      final servicio = _servicio(_Servidor.publica('1.2.0'));
      expect((await servicio.versionParaAvisar())?.version, '1.2.0');
      await servicio.posponer('1.2.0');
      expect(await servicio.versionParaAvisar(), isNull);
    });

    test('una versión mayor que la pospuesta vuelve a avisar', () async {
      await _servicio(_Servidor.publica('1.2.0')).posponer('1.2.0');
      final v = await _servicio(_Servidor.publica('1.3.0')).versionParaAvisar();
      expect(v?.version, '1.3.0');
    });

    test('una falla de shared_preferences no lanza', () async {
      final servicio = AvisoVersionService(
        cliente: _Servidor.publica('1.2.0').cliente,
        versionInstalada: '1.1.0',
        preferencias: () async => throw StateError('sin almacén'),
      );
      await servicio.posponer('1.2.0');
    });
  });
}

/// Un cliente que deja constancia de que lo cerraron.
class _ClienteQueAnotaElCierre extends MockClient {
  _ClienteQueAnotaElCierre(super.fn);

  bool cerrado = false;

  @override
  void close() {
    cerrado = true;
    super.close();
  }
}
