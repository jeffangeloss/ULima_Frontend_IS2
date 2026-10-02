// test/aviso_version/aviso_version_workflow_test.dart
//
// UNITARIA · Aviso de versión nueva (specs/features/aviso-version/aviso-version.spec.md).
// RF-AVV-8 fija que build-apk.yml compila con --dart-define=APP_VERSION=X.Y.Z,
// tomado del paso que lee la versión de pubspec.yaml. RF-AVV-7 fija que, al
// crear el release vX.Y.Z, sube al release latest un version.json con la forma
// que lee la app, y que un build sin cambio de versión no lo toca.
// Archivo probado .github/workflows/build-apk.yml. Se lee como texto, y el paso
// que publica el release se corre con bash y un gh falso, con valores de
// ejemplo, porque el workflow solo corre en producción.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ulima_plus/models/version_publicada_model.dart';

const String _rutaDelWorkflow = '.github/workflows/build-apk.yml';
const String _pasoDeLaVersion = 'Leer la versión de pubspec.yaml';
const String _pasoDeLaCompilacion = 'Compilar APK';
const String _pasoDelRelease =
    'Publicar el release de la versión si todavía no existe';

/// Las líneas del workflow, una vez.
final List<String> _lineas = File(_rutaDelWorkflow).readAsLinesSync();

bool _esInicioDePaso(String linea) => linea.trimLeft().startsWith('- name:');

/// Dónde empieza y dónde termina el paso [nombre], desde su `- name:` hasta el
/// paso siguiente.
({int inicio, int fin}) _rango(String nombre) {
  final inicio = _lineas.indexWhere((l) => l.trim() == '- name: $nombre');
  expect(inicio, isNonNegative, reason: 'el paso «$nombre» existe');
  var fin = inicio + 1;
  while (fin < _lineas.length && !_esInicioDePaso(_lineas[fin])) {
    fin++;
  }
  return (inicio: inicio, fin: fin);
}

/// Las líneas del paso [nombre].
List<String> _paso(String nombre) {
  final r = _rango(nombre);
  return _lineas.sublist(r.inicio, r.fin);
}

/// El script del `run: |` de [paso], sin la sangría del YAML.
String _script(List<String> paso) {
  final marca = paso.indexWhere((l) => l.trim() == 'run: |');
  expect(marca, isNonNegative, reason: 'el paso tiene un run: |');
  final sangria = paso[marca].indexOf('run:') + 2;
  return paso
      .sublist(marca + 1)
      .map((l) => l.length >= sangria ? l.substring(sangria) : l.trim())
      .join('\n');
}

/// Lo que Actions reemplaza antes de que corra el shell.
String _conExpresiones(
  String script, {
  String nombre = '1.2.0',
  int run = 78,
}) => script
    .replaceAll(
      RegExp(r'\$\{\{\s*steps\.version\.outputs\.nombre\s*\}\}'),
      nombre,
    )
    .replaceAll(RegExp(r'\$\{\{\s*github\.run_number\s*\}\}'), '$run');

bool _hayBash() {
  try {
    return Process.runSync('bash', <String>['--version']).exitCode == 0;
  } on ProcessException {
    return false;
  }
}

final bool _bashDisponible = _hayBash();
const String _sinBash = 'este equipo no tiene bash';

/// Corre el paso que publica el release con un `gh` falso que anota sus
/// llamadas. [existeElRelease] dice si `gh release view` lo encuentra.
class _Corrida {
  _Corrida._(this.carpeta, this.llamadas, this.resultado);

  final Directory carpeta;
  final List<String> llamadas;
  final ProcessResult resultado;

  File get versionJson => File('${carpeta.path}/version.json');

  static Future<_Corrida> correr({required bool existeElRelease}) async {
    final carpeta = await Directory.systemTemp.createTemp('build_apk_paso');
    addTearDown(() => carpeta.delete(recursive: true));
    final bin = Directory('${carpeta.path}/bin')..createSync();
    final registro = File('${carpeta.path}/gh.log');
    final gh = File('${bin.path}/gh')
      ..writeAsStringSync(
        '#!/bin/bash\n'
        'echo "\$@" >> "\$GH_REGISTRO"\n'
        'if [ "\$1" = "release" ] && [ "\$2" = "view" ]; then\n'
        '  exit "\$GH_VIEW_SALIDA"\n'
        'fi\n'
        'exit 0\n',
      );
    await Process.run('bash', <String>['-c', 'chmod +x "\$0"', gh.path]);
    final script = File('${carpeta.path}/paso.sh')
      ..writeAsStringSync(_conExpresiones(_script(_paso(_pasoDelRelease))));
    final resultado = await Process.run(
      'bash',
      <String>['-e', script.path],
      workingDirectory: carpeta.path,
      environment: <String, String>{
        'PATH': '${bin.path}:${Platform.environment['PATH'] ?? ''}',
        'GH_REGISTRO': registro.path,
        'GH_VIEW_SALIDA': existeElRelease ? '0' : '1',
        'GH_TOKEN': 'token-de-prueba',
        'TAG': 'v1.2.0',
        'GITHUB_SHA': '0123456789abcdef0123456789abcdef01234567',
        'GITHUB_REPOSITORY': 'meltiruiz/ULima_Frontend_IS2',
      },
    );
    final llamadas = registro.existsSync()
        ? registro.readAsLinesSync()
        : <String>[];
    return _Corrida._(carpeta, llamadas, resultado);
  }
}

void main() {
  group('APP_VERSION en la compilación (RF-AVV-8)', () {
    test('el paso de la versión publica nombre y viene antes de compilar', () {
      final paso = _paso(_pasoDeLaVersion);
      expect(paso.any((l) => l.trim() == 'id: version'), isTrue);
      expect(paso.join('\n'), contains('nombre='));
      expect(
        _rango(_pasoDeLaVersion).inicio,
        lessThan(_rango(_pasoDeLaCompilacion).inicio),
      );
    });

    test('flutter build apk pasa APP_VERSION con la versión de ese paso', () {
      final comando = _paso(_pasoDeLaCompilacion).join('\n');
      expect(comando, contains('flutter build apk'));
      expect(
        comando,
        contains(
          '--dart-define=APP_VERSION=\${{ steps.version.outputs.nombre }}',
        ),
      );
      expect('--dart-define=APP_VERSION='.allMatches(comando), hasLength(1));
    });

    test('la compilación conserva el nombre, el número de build y la URL del '
        'backend', () {
      final comando = _paso(_pasoDeLaCompilacion).join('\n');
      expect(
        comando,
        contains('--build-name=\${{ steps.version.outputs.nombre }}'),
      );
      expect(comando, contains('--build-number=\${{ github.run_number }}'));
      expect(comando, contains('--dart-define=API_BASE_URL='));
    });
  });

  group('version.json en cada versión nueva (RF-AVV-7)', () {
    test('solo el paso que crea el release de la versión menciona '
        'version.json', () {
      final release = _rango(_pasoDelRelease);
      var menciones = 0;
      for (var i = 0; i < _lineas.length; i++) {
        if (!_lineas[i].contains('version.json')) continue;
        menciones++;
        expect(
          i >= release.inicio && i < release.fin,
          isTrue,
          reason: 'línea ${i + 1}: ${_lineas[i].trim()}',
        );
      }
      expect(menciones, isPositive);
    });

    test('se publica después de gh release create y dentro de la rama que '
        'crea el release', () {
      final script = _script(_paso(_pasoDelRelease)).split('\n');
      final iElse = script.indexWhere((l) => l.trim() == 'else');
      final iFi = script.lastIndexWhere((l) => l.trim() == 'fi');
      final iCrear = script.indexWhere((l) => l.contains('gh release create'));
      final iJson = script.indexWhere((l) => l.contains('> version.json'));
      final iSubir = script.indexWhere(
        (l) => l.trim() == 'gh release upload latest version.json --clobber',
      );
      expect(iElse, isNonNegative);
      expect(iFi, greaterThan(iElse));
      expect(iCrear, greaterThan(iElse));
      expect(iJson, greaterThan(iCrear));
      expect(iSubir, greaterThan(iJson));
      expect(iSubir, lessThan(iFi));
      expect(
        script.sublist(0, iElse).join('\n'),
        isNot(contains('version.json')),
        reason: 'con el release ya creado no se toca el archivo',
      );
    });

    test('sin release, crea el de la versión y sube un version.json que la app '
        'lee', () async {
      final corrida = await _Corrida.correr(existeElRelease: false);
      expect(
        corrida.resultado.exitCode,
        0,
        reason: '${corrida.resultado.stderr}',
      );
      expect(corrida.llamadas, hasLength(3));
      expect(corrida.llamadas[0], 'release view v1.2.0');
      expect(corrida.llamadas[1], startsWith('release create v1.2.0 '));
      expect(
        corrida.llamadas[2],
        'release upload latest version.json --clobber',
      );

      expect(corrida.versionJson.existsSync(), isTrue);
      final json =
          jsonDecode(corrida.versionJson.readAsStringSync())
              as Map<String, dynamic>;
      expect(json, <String, Object>{
        'version': '1.2.0',
        'build': 78,
        'url':
            'https://github.com/meltiruiz/ULima_Frontend_IS2/releases/'
            'download/v1.2.0/ULimaPlus-build-78.apk',
      });
      final publicada = VersionPublicada.desdeJson(json);
      expect(publicada, isNotNull);
      expect(publicada!.version, '1.2.0');
      expect(publicada.build, 78);
      expect(
        publicada.url.toString(),
        'https://github.com/meltiruiz/ULima_Frontend_IS2/releases/download/'
        'v1.2.0/ULimaPlus-build-78.apk',
      );
    }, skip: _bashDisponible ? false : _sinBash);

    test(
      'con el release ya creado no crea otro ni toca version.json',
      () async {
        final corrida = await _Corrida.correr(existeElRelease: true);
        expect(
          corrida.resultado.exitCode,
          0,
          reason: '${corrida.resultado.stderr}',
        );
        expect(corrida.llamadas, <String>['release view v1.2.0']);
        expect(corrida.versionJson.existsSync(), isFalse);
      },
      skip: _bashDisponible ? false : _sinBash,
    );
  });
}
