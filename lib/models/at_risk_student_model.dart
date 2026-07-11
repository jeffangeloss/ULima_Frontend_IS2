class AtRiskStudent {
  final String code;
  final String firstName;
  final String lastName;
  final int? currentLevel;
  final int absentHours;
  final int totalHours;
  final double absencePercentage;
  final String status;
  final int? missingFaltas;

  AtRiskStudent({
    required this.code,
    required this.firstName,
    required this.lastName,
    this.currentLevel,
    required this.absentHours,
    required this.totalHours,
    required this.absencePercentage,
    required this.status,
    this.missingFaltas,
  });

  bool get isImpedido => status == 'impedido';

  bool get isEnRiesgo => status == 'en_riesgo';

  String get statusLabel {
    if (isImpedido) return 'Impedido';
    if (isEnRiesgo && missingFaltas != null) {
      return 'En Riesgo: a $missingFaltas faltas';
    }
    return status;
  }

  String get fullName => '$firstName $lastName';

  factory AtRiskStudent.fromJson(Map<String, dynamic> json) {
    return AtRiskStudent(
      code: json['code']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      currentLevel: (json['currentLevel'] as num?)?.toInt(),
      absentHours: (json['absentHours'] as num?)?.toInt() ?? 0,
      totalHours: (json['totalHours'] as num?)?.toInt() ?? 0,
      absencePercentage: (json['absencePercentage'] as num?)?.toDouble() ?? 0,
      status: json['status']?.toString() ?? '',
      missingFaltas: (json['missingFaltas'] as num?)?.toInt(),
    );
  }
}
