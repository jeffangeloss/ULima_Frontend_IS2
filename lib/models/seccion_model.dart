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

  /// ¿Hay asistencia cargada para esta sección? Es una bandera POSITIVA a
  /// propósito: los `?? 0` de este archivo vuelven invisible cualquier `null`
  /// del backend, así que la ausencia de dato tiene que ser explícita.
  final bool asistenciaDisponible;

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
    required this.asistenciaDisponible,
  });

  /// Fracción asistida (0..1), o `null` cuando no hay horas cargadas.
  ///
  /// NUNCA devolver `asistido / total` sin esta guarda: con `total = 0` da
  /// `0/0 = NaN`, y `clampDouble` de Flutter resuelve NaN al MÁXIMO
  /// (`sky_engine/lib/ui/math.dart`: `if (x.isNaN) return max;`). El
  /// `CircularProgressIndicator` terminaba pintado lleno y verde, afirmándole
  /// al alumno que asistió al 100% justo cuando no se sabe nada.
  double? get porcentajeAsistencia {
    if (total <= 0) return null;
    return asistido / total;
  }

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
      // El backend manda `asistenciaDisponible` desde RS-BE-10. Con un backend
      // viejo que todavía no lo emite se cae a la MISMA regla que usa el
      // servidor (`total > 0`), nunca a `true`.
      asistenciaDisponible: (json['asistenciaDisponible'] as bool?) ??
          (((json['total'] as num?)?.toInt() ?? 0) > 0),
    );
  }
}
