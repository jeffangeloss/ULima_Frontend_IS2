// lib/domain/silabo/silabo_link.dart
// HU21: lógica pura (sin Flutter ni IO) para interpretar los enlaces de
// sílabo que llegan del backend. En BD el formato típico es
// https://drive.google.com/file/d/<FILE_ID>/view, pero se aceptan las
// variantes históricas de Google Drive (?id=..., /open?id=...).
//
// A partir del FILE_ID se derivan dos URLs:
//   - downloadUrl: descarga directa del binario (uc?export=download) que el
//     visor in-app usa para bajar el PDF.
//   - externalViewUrl: vista canónica en Drive, usada por el fallback
//     "Abrir en Drive" cuando el archivo no es accesible.

/// Enlace de sílabo de Google Drive ya interpretado.
class SilaboLink {
  const SilaboLink({required this.fileId, required this.originalUrl});

  /// FILE_ID de Google Drive (letras, dígitos, guiones y underscores).
  final String fileId;

  /// URL tal cual llegó de la BD (se conserva para el fallback externo).
  final String originalUrl;

  /// URL de descarga directa del binario del PDF.
  String get downloadUrl =>
      'https://drive.google.com/uc?export=download&id=$fileId';

  /// URL canónica de vista en Drive (fallback "Abrir en Drive").
  String get externalViewUrl => 'https://drive.google.com/file/d/$fileId/view';

  /// Interpreta [url] como enlace de Drive. Devuelve null si la URL está
  /// vacía, no es de Drive o no contiene un FILE_ID reconocible.
  ///
  /// Variantes soportadas:
  ///   - `https://drive.google.com/file/d/<ID>/view` (con o sin query)
  ///   - `https://drive.google.com/open?id=<ID>`
  ///   - `https://drive.google.com/uc?export=download&id=<ID>`
  static SilaboLink? tryParse(String? url) {
    if (url == null) return null;
    final trimmed = url.trim();
    if (trimmed.isEmpty) return null;

    final uri = Uri.tryParse(trimmed);
    if (uri == null) return null;
    if (uri.scheme != 'https' && uri.scheme != 'http') return null;

    final host = uri.host.toLowerCase();
    const driveHosts = {
      'drive.google.com',
      'drive.usercontent.google.com',
      'docs.google.com',
    };
    if (!driveHosts.contains(host)) return null;

    // Variante /file/d/<ID>/... (o /document/d/<ID>/... en docs).
    final segments = uri.pathSegments;
    final dIndex = segments.indexOf('d');
    if (dIndex != -1 && dIndex + 1 < segments.length) {
      final candidate = segments[dIndex + 1];
      if (_esFileIdValido(candidate)) {
        return SilaboLink(fileId: candidate, originalUrl: trimmed);
      }
    }

    // Variantes con query: /open?id=<ID>, /uc?export=download&id=<ID>, ?id=<ID>.
    final idParam = uri.queryParameters['id'];
    if (idParam != null && _esFileIdValido(idParam)) {
      return SilaboLink(fileId: idParam, originalUrl: trimmed);
    }

    return null;
  }

  /// Un FILE_ID de Drive: alfanumérico con guiones/underscores, y con una
  /// longitud mínima que descarta segmentos accidentales ("view", "edit"...).
  static bool _esFileIdValido(String candidate) {
    if (candidate.length < 10) return false;
    return RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(candidate);
  }

  @override
  String toString() => 'SilaboLink(fileId: $fileId)';
}
