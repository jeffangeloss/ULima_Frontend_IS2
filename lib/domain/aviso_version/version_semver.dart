// lib/domain/aviso_version/version_semver.dart
// El comparador de versiones del aviso de versión nueva (RF-AVV-2 de
// specs/features/aviso-version/aviso-version.spec.md). Una versión es X.Y.Z,
// con tres números y nada más, y se compara componente por componente y en
// número, así que 1.10.0 es mayor que 1.9.0. Es lógica pura, sin Flutter.

final RegExp _versionSemver = RegExp(r'^([0-9]+)\.([0-9]+)\.([0-9]+)$');

/// Devuelve [X, Y, Z], o null si [v] no es X.Y.Z con números. Un componente
/// que no cabe en un entero tampoco lo es.
List<int>? parsearVersion(String v) {
  final coincidencia = _versionSemver.firstMatch(v);
  if (coincidencia == null) return null;
  final partes = <int>[];
  for (var i = 1; i <= 3; i++) {
    final numero = int.tryParse(coincidencia.group(i)!);
    if (numero == null) return null;
    partes.add(numero);
  }
  return partes;
}

/// Un negativo, cero o un positivo según [a] sea menor, igual o mayor que [b],
/// o null si alguna de las dos no es una versión X.Y.Z.
int? compararVersiones(String a, String b) {
  final x = parsearVersion(a);
  final y = parsearVersion(b);
  if (x == null || y == null) return null;
  for (var i = 0; i < 3; i++) {
    final orden = x[i].compareTo(y[i]);
    if (orden != 0) return orden;
  }
  return 0;
}
