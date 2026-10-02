// lib/models/version_publicada_model.dart
// Lo que publica version.json en el release latest (RF-AVV-7 de
// specs/features/aviso-version/aviso-version.spec.md), que es la última
// versión del APK, su número de build y la dirección de su descarga.

import '../domain/aviso_version/version_semver.dart';

class VersionPublicada {
  const VersionPublicada({
    required this.version,
    required this.build,
    required this.url,
  });

  /// X.Y.Z, la versión de la que sale el APK.
  final String version;

  /// El número de ejecución del workflow que compiló el APK.
  final int build;

  /// La dirección de descarga del APK de [version].
  final Uri url;

  /// Lee el objeto de version.json. Devuelve null si falta un campo o si
  /// alguno es inválido (RF-AVV-6), es decir, si `version` no es una cadena
  /// X.Y.Z, `build` no es un entero que no sea negativo o `url` no es una
  /// dirección https absoluta y con servidor, porque el botón «Descargar» la
  /// abre fuera de la app.
  static VersionPublicada? desdeJson(Map<String, dynamic> json) {
    final version = json['version'];
    final build = json['build'];
    final url = json['url'];
    if (version is! String || parsearVersion(version) == null) return null;
    if (build is! int || build < 0) return null;
    if (url is! String) return null;
    final direccion = Uri.tryParse(url);
    if (direccion == null ||
        direccion.scheme != 'https' ||
        direccion.host.isEmpty) {
      return null;
    }
    return VersionPublicada(version: version, build: build, url: direccion);
  }
}
