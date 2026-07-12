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

  // HU17: ¿el alumno autenticado ya confirmó su asistencia a esta asesoría?
  final bool myRsvp;

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
    this.myRsvp = false,
  });

  bool get esExtra => kind == 'extra';

  // HU17: copia inmutable para la actualización optimista del contador/estado.
  Asesoria copyWith({int? asistentes, bool? myRsvp}) {
    return Asesoria(
      id: id,
      courseId: courseId,
      docenteCode: docenteCode,
      docente: docente,
      dia: dia,
      inicio: inicio,
      fin: fin,
      aula: aula,
      zoom: zoom,
      kind: kind,
      fecha: fecha,
      dictanteRol: dictanteRol,
      asistentes: asistentes ?? this.asistentes,
      myRsvp: myRsvp ?? this.myRsvp,
    );
  }

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
      myRsvp: json['myRsvp'] == true,
    );
  }
}
