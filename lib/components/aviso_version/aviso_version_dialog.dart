// lib/components/aviso_version/aviso_version_dialog.dart
// El diálogo del aviso de versión nueva (RF-AVV-3, RF-AVV-4 y RF-AVV-5 de
// specs/features/aviso-version/aviso-version.spec.md). Es un AlertDialog con
// el estilo de los demás diálogos de la app y dos botones. «Más tarde»
// pospone la versión publicada y «Descargar» abre su APK fuera de la app.
// Cerrarlo con un toque fuera o con atrás no hace ninguna de las dos cosas, y
// el aviso vuelve en el siguiente arranque.

import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../configs/themes.dart';
import '../../models/version_publicada_model.dart';

enum _Eleccion { masTarde, descargar }

/// Lo que hace «Descargar» si quien llama no da otra cosa (RF-AVV-5).
Future<bool> _abrirEnAplicacionExterna(Uri url) =>
    launchUrl(url, mode: LaunchMode.externalApplication);

/// Muestra el aviso de que [publicada] ya está disponible y resuelve lo que la
/// persona elige. [alPosponer] recibe la versión publicada cuando elige «Más
/// tarde», y [abrir] recibe la URL del APK cuando elige «Descargar». Sin
/// [abrir], la URL se abre con `url_launcher` en una aplicación externa.
///
/// El futuro termina cuando el diálogo se cerró y la acción elegida terminó. Si
/// esa acción falla, el error no sale (RF-AVV-6).
Future<void> mostrarAvisoVersion(
  BuildContext context, {
  required VersionPublicada publicada,
  required String instalada,
  required Future<void> Function(String version) alPosponer,
  Future<bool> Function(Uri url)? abrir,
}) async {
  final eleccion = await showDialog<_Eleccion>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Hay una versión nueva'),
      content: Text(
        'ULima++ ${publicada.version} ya está disponible. '
        'Tienes la $instalada.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(_Eleccion.masTarde),
          child: const Text('Más tarde'),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(_Eleccion.descargar),
          child: const Text(
            'Descargar',
            style: TextStyle(
              color: MaterialTheme.primaryColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
  // Cerrar el diálogo con el barrier o con atrás devuelve null: no hace nada.
  try {
    switch (eleccion) {
      case _Eleccion.masTarde:
        await alPosponer(publicada.version);
      case _Eleccion.descargar:
        await (abrir ?? _abrirEnAplicacionExterna)(publicada.url);
      case null:
        break;
    }
  } catch (error) {
    if (kDebugMode) debugPrint('Aviso de versión. La acción falló con $error');
  }
}
