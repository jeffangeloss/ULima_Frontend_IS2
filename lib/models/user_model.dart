// lib/models/user_model.dart
// Modelo del alumno autenticado en la app.

import 'malla_models.dart';

class UserModel {
  final String code;
  final String firstName;
  final String lastName;
  final String email;
  final String role; // estudiante | delegado | subdelegado
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
    this.careerId,
    this.especialidadPrincipal,
    List<int>? especialidadesInteres,
    required this.currentCycle,
    required this.setupComplete,
    this.courseProgress,
  }) : especialidadesInteres = especialidadesInteres ?? <int>[];

  String get fullName => '$firstName $lastName';

  bool get isDelegate => role == 'delegado' || role == 'subdelegado';

  /// Lista combinada para código que no distingue principal/interés (MallaService, etc.).
  List<int> get especialidades => [
    ?especialidadPrincipal,
    ...especialidadesInteres.where((id) => id != especialidadPrincipal),
  ];

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Migración: si vienen como lista plana antigua, el primero pasa a interés.
    final legacyList =
        (json['especialidades'] as List?)?.cast<int>() ?? <int>[];

    return UserModel(
      code: json['code'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      email: json['email'] as String,
      role: json['role'] as String? ?? 'estudiante',
      careerId: json['career_id'] as int?,
      especialidadPrincipal: json['especialidad_principal'] as int?,
      especialidadesInteres:
          (json['especialidades_interes'] as List?)?.cast<int>() ?? legacyList,
      currentCycle: json['currentCycle'] as String? ?? '2026-1',
      setupComplete: json['setupComplete'] as bool? ?? false,
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
    'career_id': careerId,
    'especialidad_principal': especialidadPrincipal,
    'especialidades_interes': especialidadesInteres,
    'currentCycle': currentCycle,
    'setupComplete': setupComplete,
  };
}
