import 'package:flutter/foundation.dart';
import 'package:ulima_plus/models/contacto_model.dart';
import 'package:ulima_plus/models/docente_model.dart';
import 'package:ulima_plus/models/user_model.dart';

import 'api_client.dart';

class ContactoService {
  final ApiClient _api = ApiClient();

  Future<Map<String, dynamic>> fetchContactos(String idSeccion) async {
    try {
      final data = await _api.getJson(
        '/course-detail/sections/$idSeccion/contacts',
      );
      final docenteRaw = data['docente'];
      final docente = docenteRaw == null
          ? null
          : Docente.fromJson(Map<String, dynamic>.from(docenteRaw as Map));
      // HU18: jefe de práctica de la sección (0 o 1).
      final jpRaw = data['jefePractica'];
      final jefePractica = jpRaw == null
          ? null
          : Docente.fromJson(Map<String, dynamic>.from(jpRaw as Map));
      final List<dynamic> alumnosRaw = data['alumnos'] ?? [];
      final contactos = alumnosRaw.map((raw) {
        final json = Map<String, dynamic>.from(raw as Map);
        return ContactoCurso(
          user: UserModel.fromJson(
            Map<String, dynamic>.from(json['user'] as Map),
          ),
          roleInSection: json['roleInSection']?.toString() ?? 'estudiante',
        );
      }).toList();

      contactos.sort((a, b) {
        final compare = _rolePriority(
          a.roleInSection,
        ).compareTo(_rolePriority(b.roleInSection));

        if (compare == 0) {
          return a.user.lastName.compareTo(b.user.lastName);
        }

        return compare;
      });

      return {'docente': docente, 'jefePractica': jefePractica, 'alumnos': contactos};
    } catch (e) {
      debugPrint('Error cargando contactos: $e');

      return {'docente': null, 'jefePractica': null, 'alumnos': <ContactoCurso>[]};
    }
  }

  int _rolePriority(String role) {
    switch (role) {
      case 'delegado':
        return 0;
      case 'subdelegado':
        return 1;
      default:
        return 2;
    }
  }
}
