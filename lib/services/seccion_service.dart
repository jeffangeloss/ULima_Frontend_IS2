import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:ulima_plus/models/seccion_model.dart';
import 'package:ulima_plus/services/docente_service.dart';

class SeccionService {
  final DocenteService _docenteService = DocenteService();

  Future<List<Seccion>> fetchSecciones() async {
    try {
      final String response = await rootBundle.loadString(
        'assets/data/secciones.json',
      );
      final data = json.decode(response);

      final List<dynamic> sectionsRaw = data['secciones'] ?? [];

      final List<Seccion> secciones = [];

      for (final s in sectionsRaw) {
        final seccionJson = Map<String, dynamic>.from(s as Map);
        final docenteCode = seccionJson['docenteCode']?.toString();

        if (docenteCode != null && docenteCode.isNotEmpty) {
          final docente = await _docenteService.findDocenteByCode(docenteCode);
          if (docente != null) {
            seccionJson['docente'] = {
              'code': docente.code,
              'firstName': docente.firstName,
              'lastName': docente.lastName,
            };
          }
        }

        secciones.add(Seccion.fromJson(seccionJson));
      }

      return secciones;
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
