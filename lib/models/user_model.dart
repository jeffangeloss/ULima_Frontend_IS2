// lib/models/user_model.dart
// Modelo del alumno autenticado en la app.

import 'malla_models.dart';

class UserModel {
  final String code;
  final String firstName;
  final String lastName;
  final String email;

  /// student/delegate/subdelegate/teacher o legado estudiante/delegado/subdelegado.
  final String role;

  /// HU18: etiqueta docente ("Profesor"/"Jefe de Práctica"); null para alumnos.
  final String? teacherLabel;
  int? careerId;

  /// Especialidad elegida como mención principal (diploma).
  int? especialidadPrincipal;

  /// Especialidades marcadas como interés adicional.
  List<int> especialidadesInteres;

  final String currentCycle;
  bool setupComplete;
  CourseProgress? courseProgress;

  UserModel({
    required this.code,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
    this.teacherLabel,
    this.careerId,
    this.especialidadPrincipal,
    List<int>? especialidadesInteres,
    required this.currentCycle,
    required this.setupComplete,
    this.courseProgress,
  }) : especialidadesInteres = especialidadesInteres ?? <int>[];

  String get fullName => '$firstName $lastName';

  String get roleLabel {
    final normalized = role.trim().toLowerCase();
    if (teacherLabel != null && teacherLabel!.trim().isNotEmpty) {
      return teacherLabel!;
    }

    switch (normalized) {
      case 'delegate':
      case 'delegado':
        return 'Delegado';
      case 'subdelegate':
      case 'subdelegado':
        return 'Subdelegado';
      case 'teacher':
      case 'docente':
      case 'profesor':
        return 'Profesor';
      case 'jp':
      case 'jefe de practica':
      case 'jefe de práctica':
        return 'Jefe de Práctica';
      case 'student':
      case 'estudiante':
      case 'alumno':
        return 'Alumno';
    }

    if (normalized.isEmpty) return '';
    return '${normalized[0].toUpperCase()}${normalized.substring(1)}';
  }

  bool get isDelegate =>
      role == 'delegado' ||
      role == 'subdelegado' ||
      role == 'delegate' ||
      role == 'subdelegate';

  /// HU18: cuenta docente (profesor o JP). Incluye variante legado en español.
  bool get isTeacher => role == 'teacher' || role == 'docente';

  /// Lista combinada para código que no distingue principal/interés (MallaService, etc.).
  List<int> get especialidades => [
    ?especialidadPrincipal,
    ...especialidadesInteres.where((id) => id != especialidadPrincipal),
  ];

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final fullName = json['fullName']?.toString();
    final nameParts = (fullName ?? '').trim().split(RegExp(r'\s+'));
    final firstNameFromFullName = nameParts.length > 1
        ? nameParts.sublist(0, nameParts.length - 1).join(' ')
        : fullName;
    final lastNameFromFullName = nameParts.length > 1 ? nameParts.last : '';

    final specialtyRows = (json['specialties'] as List?) ?? const [];
    final primaryFromSpecialties = specialtyRows
        .whereType<Map>()
        .where((s) => s['selectionType']?.toString() == 'primary')
        .map((s) => _parseInt(s['specialtyId']))
        .whereType<int>()
        .firstOrNull;
    final interestFromSpecialties = specialtyRows
        .whereType<Map>()
        .where((s) => s['selectionType']?.toString() == 'interest')
        .map((s) => _parseInt(s['specialtyId']))
        .whereType<int>()
        .toList();

    // Migración: si viene lista plana antigua, se mantiene como interés.
    final legacyList = _parseIntList(json['especialidades']);
    final interest = _parseIntList(json['especialidades_interes']);

    return UserModel(
      code: json['code'].toString(),
      firstName:
          json['firstName']?.toString() ?? firstNameFromFullName ?? 'Alumno',
      lastName: json['lastName']?.toString() ?? lastNameFromFullName,
      email:
          json['email']?.toString() ??
          json['institutionalEmail']?.toString() ??
          '',
      role: json['role'] as String? ?? 'estudiante',
      teacherLabel: json['teacherLabel']?.toString(),
      careerId: _parseInt(json['career_id'] ?? json['careerId']),
      especialidadPrincipal:
          _parseInt(json['especialidad_principal']) ?? primaryFromSpecialties,
      especialidadesInteres: interest.isNotEmpty
          ? interest
          : (interestFromSpecialties.isNotEmpty
                ? interestFromSpecialties
                : legacyList),
      currentCycle: json['currentCycle'] as String? ?? '2026-1',
      setupComplete:
          json['setupComplete'] as bool? ??
          json['specialtySetupCompleted'] as bool? ??
          false,
      courseProgress: CourseProgress.fromJson(
        json['courseProgress'] as Map<String, dynamic>?,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'code': code,
    'firstName': firstName,
    'lastName': lastName,
    'email': email,
    'role': role,
    'teacherLabel': teacherLabel,
    'career_id': careerId,
    'especialidad_principal': especialidadPrincipal,
    'especialidades_interes': especialidadesInteres,
    'currentCycle': currentCycle,
    'setupComplete': setupComplete,
  };

  static int? _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static List<int> _parseIntList(dynamic value) {
    if (value is! List) return const [];
    return value.map(_parseInt).whereType<int>().toList();
  }
}
