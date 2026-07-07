import 'package:ulima_plus/models/docente_model.dart';

class Asesoria {
  final String id;
  final String courseId;
  final String docenteCode;
  final Docente docente;
  final String dia;
  final String inicio;
  final String fin;
  final String aula;
  final String zoom;

  // HU18: campos nuevos (opcionales para compatibilidad con backends viejos).
  final String kind; // 'recurring' | 'extra'
  final String? fecha; // 'YYYY-MM-DD' (solo extras)
  final String dictanteRol; // 'Profesor' | 'JP'
  final int asistentes;

  Asesoria({
    required this.id,
    required this.courseId,
    required this.docenteCode,
    required this.docente,
    required this.dia,
    required this.inicio,
    required this.fin,
    required this.aula,
    required this.zoom,
    this.kind = 'recurring',
    this.fecha,
    this.dictanteRol = 'Profesor',
    this.asistentes = 0,
  });

  bool get esExtra => kind == 'extra';

  factory Asesoria.fromJson(
    Map<String, dynamic> json, {
    required Docente docente,
  }) {
    return Asesoria(
      //Asesoria segun docente y curso
      id: json['id'].toString(),
      courseId: json['courseId'].toString(),
      docenteCode: json['docenteCode'].toString(),
      docente: docente,
      dia: json['dia'].toString(),
      inicio: json['inicio'].toString(),
      fin: json['fin'].toString(),
      aula: json['aula'].toString(),
      zoom: json['zoom'].toString(),
      kind: json['kind']?.toString() ?? 'recurring',
      fecha: json['fecha']?.toString(),
      dictanteRol: json['dictanteRol']?.toString() ?? 'Profesor',
      asistentes: json['asistentes'] is int
          ? json['asistentes'] as int
          : int.tryParse(json['asistentes']?.toString() ?? '') ?? 0,
    );
  }
}
