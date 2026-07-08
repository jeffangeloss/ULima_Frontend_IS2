class CursoDelegado {
  final String idCurso;
  final String nombreCurso;
  final String idSeccion;
  final String codigoSeccion;
  final String rol;
  final int alumnosMatriculados;

  const CursoDelegado({
    required this.idCurso,
    required this.nombreCurso,
    required this.idSeccion,
    required this.codigoSeccion,
    required this.rol,
    required this.alumnosMatriculados,
  });

  String get rolTexto =>
      rol == 'subdelegado' || rol == 'subdelegate' ? 'Subdelegado' : 'Delegado';

  factory CursoDelegado.fromJson(Map<String, dynamic> json) {
    final sectionId =
        json['idSeccion']?.toString() ?? json['sectionId']?.toString() ?? '';
    final sectionCode =
        json['codigoSeccion']?.toString() ??
        json['sectionCode']?.toString() ??
        json['section_code']?.toString() ??
        '';

    return CursoDelegado(
      idCurso:
          json['idCurso']?.toString() ??
          json['courseId']?.toString() ??
          json['course_id']?.toString() ??
          '',
      nombreCurso:
          json['nombreCurso']?.toString() ??
          json['courseName']?.toString() ??
          json['course_name']?.toString() ??
          '',
      idSeccion: sectionId,
      codigoSeccion: sectionCode.isNotEmpty
          ? sectionCode
          : 'Sección $sectionId',
      rol:
          json['rol']?.toString() ??
          json['role']?.toString() ??
          json['position']?.toString() ??
          'delegado',
      alumnosMatriculados:
          (json['alumnosMatriculados'] as num?)?.toInt() ??
          (json['enrolledStudents'] as num?)?.toInt() ??
          (json['enrolled_students'] as num?)?.toInt() ??
          0,
    );
  }
}
