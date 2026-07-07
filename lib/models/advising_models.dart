// lib/models/advising_models.dart
// Modelos del lado docente para HU18 (asesorías del profesor/JP).

class AdvisingSession {
  final int id;
  final int? sectionId;
  final String courseName;
  final String? sectionCode;
  final String kind; // 'recurring' | 'extra'
  final String dia;
  final String? fecha; // 'YYYY-MM-DD' (solo extras)
  final String inicio;
  final String fin;
  final String modality; // classroom | virtual | hybrid
  final String aula;
  final String zoom;
  final String nota;
  final int? cupo;
  final int asistentes;
  final String rol; // 'Profesor' | 'JP'

  AdvisingSession({
    required this.id,
    required this.sectionId,
    required this.courseName,
    required this.sectionCode,
    required this.kind,
    required this.dia,
    required this.fecha,
    required this.inicio,
    required this.fin,
    required this.modality,
    required this.aula,
    required this.zoom,
    required this.nota,
    required this.cupo,
    required this.asistentes,
    required this.rol,
  });

  bool get esExtra => kind == 'extra';

  factory AdvisingSession.fromJson(Map<String, dynamic> json) {
    int? asInt(dynamic v) => v is int ? v : int.tryParse(v?.toString() ?? '');
    return AdvisingSession(
      id: asInt(json['id']) ?? 0,
      sectionId: asInt(json['sectionId']),
      courseName: json['courseName']?.toString() ?? '',
      sectionCode: json['sectionCode']?.toString(),
      kind: json['kind']?.toString() ?? 'recurring',
      dia: json['dia']?.toString() ?? '',
      fecha: json['fecha']?.toString(),
      inicio: json['inicio']?.toString() ?? '',
      fin: json['fin']?.toString() ?? '',
      modality: json['modality']?.toString() ?? 'hybrid',
      aula: json['aula']?.toString() ?? '',
      zoom: json['zoom']?.toString() ?? '',
      nota: json['nota']?.toString() ?? '',
      cupo: asInt(json['cupo']),
      asistentes: asInt(json['asistentes']) ?? 0,
      rol: json['rol']?.toString() ?? 'Profesor',
    );
  }
}

/// Opción de sección para el formulario de creación.
class TeacherSectionOption {
  final int sectionId;
  final String courseName;
  final String sectionCode;
  final String rol; // 'Profesor' | 'JP'

  TeacherSectionOption({
    required this.sectionId,
    required this.courseName,
    required this.sectionCode,
    required this.rol,
  });

  String get label => '$courseName · $sectionCode';

  factory TeacherSectionOption.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic v) => v is int ? v : int.tryParse(v?.toString() ?? '') ?? 0;
    return TeacherSectionOption(
      sectionId: asInt(json['sectionId']),
      courseName: json['courseName']?.toString() ?? '',
      sectionCode: json['sectionCode']?.toString() ?? '',
      rol: json['rol']?.toString() ?? 'Profesor',
    );
  }
}

/// Alumno confirmado a una asesoría.
class Attendee {
  final String code;
  final String firstName;
  final String lastName;

  Attendee({required this.code, required this.firstName, required this.lastName});

  String get fullName => '$firstName $lastName'.trim();

  factory Attendee.fromJson(Map<String, dynamic> json) => Attendee(
        code: json['code']?.toString() ?? '',
        firstName: json['firstName']?.toString() ?? '',
        lastName: json['lastName']?.toString() ?? '',
      );
}
