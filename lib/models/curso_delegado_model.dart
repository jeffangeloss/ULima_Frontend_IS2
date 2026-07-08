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
    return CursoDelegado(
      idCurso:
          json['idCurso']?.toString() ?? json['courseId']?.toString() ?? '',
      nombreCurso:
          json['nombreCurso']?.toString() ??
          json['courseName']?.toString() ??
          '',
      idSeccion:
          json['idSeccion']?.toString() ?? json['sectionId']?.toString() ?? '',
      codigoSeccion:
          json['codigoSeccion']?.toString() ??
          json['sectionCode']?.toString() ??
          '',
      rol: json['rol']?.toString() ?? json['role']?.toString() ?? 'delegado',
      alumnosMatriculados:
          (json['alumnosMatriculados'] as num?)?.toInt() ??
          (json['enrolledStudents'] as num?)?.toInt() ??
          0,
    );
  }
}
