import 'dart:convert';
import 'package:http/http.dart' as http;

import 'api_client.dart';

/// Subida y borrado de la foto de perfil.
///
/// La imagen va **directo a Cloudinary**, no a través del backend: Vercel corta
/// los cuerpos de petición en 4.5 MB y una foto de cámara los pasa. El backend
/// solo firma la subida y después registra el resultado.
///
/// El flujo son tres pasos y el orden importa: si se confirmara antes de que
/// Cloudinary responda, la app mostraría una foto que no existe.
class AvatarService {
  AvatarService({ApiClient? api, http.Client? cliente})
    : _api = api ?? ApiClient(),
      _cliente = cliente ?? http.Client();

  final ApiClient _api;
  final http.Client _cliente;

  static const Duration _timeoutSubida = Duration(seconds: 60);

  /// Sube [bytes] y deja la foto lista. Devuelve la URL ya transformada para
  /// pintarla de inmediato, sin esperar a recargar el perfil.
  Future<void> subir({required List<int> bytes, required String nombreArchivo}) async {
    final firma = await _api.postJson('/avatar/signature', body: const {});

    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/${firma['cloudName']}/image/upload',
    );
    final peticion = http.MultipartRequest('POST', uri)
      ..fields['api_key'] = '${firma['apiKey']}'
      ..fields['timestamp'] = '${firma['timestamp']}'
      ..fields['signature'] = '${firma['signature']}'
      ..fields['public_id'] = '${firma['publicId']}'
      // Estos dos van firmados por el backend: si no se mandan idénticos,
      // Cloudinary rechaza la petición por firma inválida.
      ..fields['overwrite'] = 'true'
      ..fields['invalidate'] = 'true'
      ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: nombreArchivo));

    final respuesta = await _cliente
        .send(peticion)
        .timeout(_timeoutSubida)
        .then(http.Response.fromStream);

    if (respuesta.statusCode < 200 || respuesta.statusCode >= 300) {
      throw AvatarFailure('No se pudo subir la foto. Inténtalo de nuevo.');
    }

    final cuerpo = jsonDecode(respuesta.body) as Map<String, dynamic>;
    final version = cuerpo['version'];
    if (version == null) {
      throw AvatarFailure('Cloudinary no devolvió la versión de la imagen.');
    }

    // Recién ahora la foto es "oficial": la base es la fuente de verdad y sin
    // esta confirmación la app no la mostraría.
    await _api.postJson('/avatar', body: {'version': '$version'});
  }

  /// Quita la foto propia.
  Future<void> quitar() => _api.deleteJson('/avatar');

  /// Quita la foto de otra persona. Solo lo permite el backend a delegados,
  /// subdelegados, docentes y jefes de práctica de una sección compartida.
  Future<void> quitarDe(String userId) => _api.deleteJson('/avatar/$userId');
}

/// Fallo con un mensaje ya listo para mostrar.
class AvatarFailure implements Exception {
  const AvatarFailure(this.message);
  final String message;
  @override
  String toString() => message;
}
