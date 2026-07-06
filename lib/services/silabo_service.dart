// lib/services/silabo_service.dart
// HU21: descarga (y cachea) el PDF del sílabo desde Google Drive para el
// visor in-app. Es la frontera HTTP: los widgets nunca descargan directo.
//
// DATO VERIFICADO (2026-07-06): los permisos de Drive de los sílabos reales
// son MIXTOS. Algunos archivos devuelven el binario (empieza con %PDF) y
// otros devuelven 200 con el HTML de login de Google. Por eso la validación
// clave es la FIRMA %PDF del contenido, no el status code: cualquier
// respuesta que no empiece con %PDF se trata como "sílabo no accesible" y la
// UI degrada al fallback "Abrir en Drive".

import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../domain/silabo/silabo_link.dart';

/// Error base de la descarga de sílabos, con mensaje presentable en UI.
sealed class SilaboException implements Exception {
  const SilaboException(this.message);
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// El archivo existe pero Drive no entrega el PDF (login/confirmación/HTML
/// o cualquier contenido sin firma %PDF): no es visualizable in-app.
class SilaboNoAccesibleException extends SilaboException {
  const SilaboNoAccesibleException()
      : super('El sílabo no está disponible para verlo dentro de la app.');
}

/// El PDF supera el límite de descarga in-app (25 MB).
class SilaboDemasiadoGrandeException extends SilaboException {
  const SilaboDemasiadoGrandeException()
      : super('El sílabo es demasiado pesado para abrirlo en la app.');
}

/// Falla de red o respuesta HTTP no exitosa.
class SilaboDescargaException extends SilaboException {
  const SilaboDescargaException([super.message = 'No se pudo descargar el sílabo.']);
}

class SilaboService {
  SilaboService({
    http.Client Function()? httpClientFactory,
    Future<Directory> Function()? cacheDirProvider,
  })  : _httpClientFactory = httpClientFactory ?? http.Client.new,
        _cacheDirProvider = cacheDirProvider ?? getTemporaryDirectory;

  /// Fábrica del cliente HTTP; inyectable para tests (MockClient).
  final http.Client Function() _httpClientFactory;

  /// Directorio base de caché; inyectable para tests (sin platform channels).
  final Future<Directory> Function() _cacheDirProvider;

  /// Límite de descarga: un sílabo real pesa cientos de KB; >25MB se aborta.
  static const int maxPdfBytes = 25 * 1024 * 1024;

  static const List<int> _firmaPdf = [0x25, 0x50, 0x44, 0x46]; // '%PDF'

  /// True si [bytes] empieza con la firma %PDF.
  static bool esFirmaPdf(List<int> bytes) {
    if (bytes.length < _firmaPdf.length) return false;
    for (var i = 0; i < _firmaPdf.length; i++) {
      if (bytes[i] != _firmaPdf[i]) return false;
    }
    return true;
  }

  /// Devuelve los bytes del PDF del sílabo, usando la caché en disco
  /// (keyed por fileId) para reaperturas instantáneas. Con [forzarDescarga]
  /// se ignora la caché (botón "Reintentar").
  ///
  /// Lanza [SilaboNoAccesibleException], [SilaboDemasiadoGrandeException] o
  /// [SilaboDescargaException].
  Future<Uint8List> obtenerPdf(
    SilaboLink link, {
    bool forzarDescarga = false,
  }) async {
    final cacheFile = await _archivoCache(link.fileId);

    if (!forzarDescarga && cacheFile != null && cacheFile.existsSync()) {
      try {
        final cached = await cacheFile.readAsBytes();
        if (esFirmaPdf(cached)) return cached;
      } catch (_) {
        // Caché corrupta/ilegible: se ignora y se vuelve a descargar.
      }
    }

    final bytes = await _descargar(link);

    if (cacheFile != null) {
      try {
        await cacheFile.writeAsBytes(bytes, flush: true);
      } catch (_) {
        // La caché es best-effort: si no se puede escribir, no es fatal.
      }
    }
    return bytes;
  }

  Future<Uint8List> _descargar(SilaboLink link) async {
    final client = _httpClientFactory();
    try {
      final request = http.Request('GET', Uri.parse(link.downloadUrl))
        ..followRedirects = true
        ..maxRedirects = 8;

      final response = await client.send(request);
      if (response.statusCode != 200) {
        throw SilaboDescargaException(
          'No se pudo descargar el sílabo (HTTP ${response.statusCode}).',
        );
      }

      final contentLength = response.contentLength;
      if (contentLength != null && contentLength > maxPdfBytes) {
        throw const SilaboDemasiadoGrandeException();
      }

      final builder = BytesBuilder(copy: false);
      await for (final chunk in response.stream) {
        builder.add(chunk);
        if (builder.length > maxPdfBytes) {
          throw const SilaboDemasiadoGrandeException();
        }
      }
      final bytes = builder.takeBytes();

      // Permisos mixtos en Drive: 200 + HTML de login/confirmación es el
      // caso "no accesible"; solo un binario %PDF pasa al visor.
      if (!esFirmaPdf(bytes)) {
        throw const SilaboNoAccesibleException();
      }
      return bytes;
    } on SilaboException {
      rethrow;
    } on http.ClientException catch (e) {
      throw SilaboDescargaException('No se pudo descargar el sílabo: ${e.message}');
    } on SocketException {
      throw const SilaboDescargaException(
        'No se pudo descargar el sílabo. Revisa tu conexión.',
      );
    } finally {
      client.close();
    }
  }

  /// Nombre de archivo presentable (sin extensión) derivado de [titulo],
  /// para que la hoja de compartir no muestre el fileId de la caché
  /// ("abc123.pdf"). Sustituye caracteres inválidos en nombres de archivo,
  /// colapsa espacios, evita nombres ocultos (punto inicial) y recorta a un
  /// largo razonable. Si no queda nada usable devuelve 'Silabo'.
  static String nombreArchivoPresentable(String titulo) {
    var nombre = titulo
        // Inválidos en iOS/Android/Windows + separadores de ruta.
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), ' ')
        // Caracteres de control.
        .replaceAll(RegExp(r'[\x00-\x1F\x7F]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    // Recorte por puntos de código (runes) para no partir un surrogate pair
    // (p. ej. emojis) a la mitad, y DESPUÉS limpiar extremos: el recorte
    // puede reintroducir un punto/espacio final inválido.
    if (nombre.runes.length > 80) {
      nombre = String.fromCharCodes(nombre.runes.take(80));
    }
    // Sin punto inicial (archivo oculto) ni puntos/espacios finales
    // (inválido en Windows y confunde la extensión).
    nombre = nombre.replaceAll(RegExp(r'^[.\s]+|[.\s]+$'), '');
    return nombre.isEmpty ? 'Silabo' : nombre;
  }

  /// Escribe [bytes] en un archivo temporal con nombre presentable derivado
  /// de [titulo] (p. ej. "Ingeniería de Software II.pdf") y lo devuelve,
  /// listo para la hoja de compartir del sistema. A diferencia de la caché
  /// por fileId, aquí el nombre SÍ es visible para el usuario.
  ///
  /// Lanza [SilaboDescargaException] si el archivo no se puede escribir.
  Future<File> prepararCompartible(String titulo, Uint8List bytes) async {
    try {
      final base = await _cacheDirProvider();
      final sep = Platform.pathSeparator;
      final dir = Directory('${base.path}${sep}silabos${sep}compartir');
      if (!dir.existsSync()) dir.createSync(recursive: true);
      final file =
          File('${dir.path}$sep${nombreArchivoPresentable(titulo)}.pdf');
      await file.writeAsBytes(bytes, flush: true);
      return file;
    } on SilaboException {
      rethrow;
    } catch (_) {
      throw const SilaboDescargaException('No se pudo preparar el sílabo.');
    }
  }

  /// Archivo de caché para [fileId], o null si el directorio no está
  /// disponible (p. ej. plataformas sin path_provider).
  Future<File?> _archivoCache(String fileId) async {
    try {
      final base = await _cacheDirProvider();
      final dir = Directory('${base.path}${Platform.pathSeparator}silabos');
      if (!dir.existsSync()) dir.createSync(recursive: true);
      return File('${dir.path}${Platform.pathSeparator}$fileId.pdf');
    } catch (_) {
      return null;
    }
  }
}
