import 'package:flutter_test/flutter_test.dart';
import 'package:ulima_plus/models/seccion_model.dart';

/// La dona de asistencia de `descrip_cursos.dart` calculaba `asistido / total`
/// sin guarda. Con `total = 0` (que es el estado real de TODO el período activo:
/// nadie escribe nunca `enrollment.total_hours`) eso da `0/0 = NaN`, y
/// `clampDouble` de Flutter devuelve el MÁXIMO ante un NaN
/// (`sky_engine/lib/ui/math.dart`: `if (x.isNaN) return max;`).
///
/// Resultado: el `CircularProgressIndicator` se pintaba lleno y verde, o sea la
/// app le afirmaba a cada alumno, en cada curso, que había asistido al 100%.
/// "Sin datos" nunca debe poder disfrazarse de asistencia perfecta.
void main() {
  Map<String, dynamic> json({
    int asistido = 0,
    int inasistencia = 0,
    int total = 0,
    bool? disponible,
  }) => {
        'idSeccion': '1',
        'codigoSeccion': '751',
        'docenteCode': 'D1',
        'promedioSeccion': 0,
        'idCurso': '650065',
        'curso': 'CIBERSEGURIDAD',
        'asistido': asistido,
        'inasistencia': inasistencia,
        'total': total,
        'asistenciaDisponible': ?disponible,
      };

  group('Seccion.porcentajeAsistencia', () {
    test('sin horas cargadas devuelve null, no NaN ni 1.0', () {
      final s = Seccion.fromJson(json(total: 0));
      expect(s.porcentajeAsistencia, isNull);
    });

    test('con horas reales calcula la fraccion asistida', () {
      final s = Seccion.fromJson(json(asistido: 60, inasistencia: 20, total: 80));
      expect(s.porcentajeAsistencia, closeTo(0.75, 1e-9));
    });

    test('un total negativo tampoco produce porcentaje', () {
      final s = Seccion.fromJson(json(asistido: 5, total: -1));
      expect(s.porcentajeAsistencia, isNull);
    });
  });

  group('Seccion.asistenciaDisponible', () {
    test('sin horas cargadas es false', () {
      expect(Seccion.fromJson(json(total: 0)).asistenciaDisponible, isFalse);
    });

    test('con horas cargadas es true', () {
      expect(Seccion.fromJson(json(total: 80)).asistenciaDisponible, isTrue);
    });

    test('respeta la bandera explicita del backend cuando llega', () {
      // El backend puede saber que el dato no es confiable aunque total > 0.
      expect(
        Seccion.fromJson(json(total: 80, disponible: false)).asistenciaDisponible,
        isFalse,
      );
    });

    test('si el backend todavia no manda la bandera, cae a total > 0', () {
      // Degradación con un backend viejo: no se asume disponible por omisión.
      expect(Seccion.fromJson(json(total: 80)).asistenciaDisponible, isTrue);
      expect(Seccion.fromJson(json(total: 0)).asistenciaDisponible, isFalse);
    });
  });
}
