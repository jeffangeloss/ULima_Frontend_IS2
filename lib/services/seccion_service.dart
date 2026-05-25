import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:ulima_plus/models/seccion_model.dart';

class SeccionService {
  Future<List<Seccion>> fetchSecciones() async {
    try {
      final String response = await rootBundle.loadString(
        'assets/data/secciones.json',
      );
      final data = json.decode(response);

      final List<dynamic> sectionsRaw = data['secciones'] ?? [];

      return sectionsRaw
          .map((s) => Seccion.fromJson(s as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error cargando secciones: $e');
      return [];
    }
  }

  Future<Seccion?> findSectionById(String id) async {
    final sections = await fetchSecciones();

    try {
      return sections.firstWhere((s) => s.idSeccion == id);
    } catch (e) {
      debugPrint('No existe seccion con id $id');
      return null;
    }
  }
}
