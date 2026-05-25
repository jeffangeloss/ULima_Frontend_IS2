class Seccion {
  final String idSeccion;
  final String codigoSeccion;
  final String docenteCode;
  final double promedioSeccion;
  final String idCurso;
  final String curso;
  final int asistido;
  final int inasistencia;
  final int total;

  Seccion({
    required this.idSeccion,
    required this.codigoSeccion,
    required this.docenteCode,
    required this.promedioSeccion,
    required this.idCurso,
    required this.curso,
    required this.asistido,
    required this.inasistencia,
    required this.total,
  });

  factory Seccion.fromJson(Map<String, dynamic> json) {
    return Seccion(
      idSeccion: json['idSeccion']?.toString() ?? '',
      codigoSeccion: json['codigoSeccion']?.toString() ?? '',
      docenteCode: json['docenteCode']?.toString() ?? '',
      promedioSeccion: (json['promedioSeccion'] as num?)?.toDouble() ?? 0.0,
      idCurso: json['idCurso']?.toString() ?? '',
      curso: json['curso']?.toString() ?? 'Sin curso',
      asistido: (json['asistido'] as num?)?.toInt() ?? 0,
      inasistencia: (json['inasistencia'] as num?)?.toInt() ?? 0,
      total: (json['total'] as num?)?.toInt() ?? 0,
    );
  }
}
