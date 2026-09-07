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
    int? transcurridas,
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
        'horasTranscurridas': transcurridas ?? (asistido + inasistencia),
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

    test('un denominador negativo tampoco produce porcentaje', () {
      // RS-BE-16 movió el denominador de `total` a `horasTranscurridas`; la
      // guarda contra un valor absurdo sigue siendo la misma idea.
      final s = Seccion.fromJson(json(asistido: 5, total: 64, transcurridas: -1));
      expect(s.porcentajeAsistencia, isNull);
    });
  });

  group('RS-BE-16: el porcentaje va sobre lo TRANSCURRIDO', () {
    test('semana 2: 8 asistidas de 8 dictadas es 100%, no 12.5% del ciclo', () {
      // El caso real del portal: 8 asistidas, 0 faltas, 64 programadas.
      // Dividir por el ciclo entero diría "asististe al 12.5%", que es la misma
      // deshonestidad que arreglo RS-BE-10, invertida.
      final s = Seccion.fromJson(json(asistido: 8, inasistencia: 0, total: 64));
      expect(s.horasTranscurridas, 8);
      expect(s.porcentajeAsistencia, closeTo(1.0, 1e-9));
    });

    test('con faltas reales el porcentaje baja', () {
      final s = Seccion.fromJson(json(asistido: 6, inasistencia: 2, total: 64));
      expect(s.porcentajeAsistencia, closeTo(0.75, 1e-9));
    });

    test('sin horas dictadas todavia no hay porcentaje, aunque haya programadas', () {
      final s = Seccion.fromJson(json(asistido: 0, inasistencia: 0, total: 64));
      expect(s.horasTranscurridas, 0);
      expect(s.porcentajeAsistencia, isNull);
    });

    test('con backend viejo, sin el campo, cae a asistido + inasistencia', () {
      // Se QUITA la clave: pasar `transcurridas: null` no servía, porque el
      // helper la rellena igual y el test no probaba el fallback.
      final m = json(asistido: 8, inasistencia: 2, total: 64)
        ..remove('horasTranscurridas');
      expect(Seccion.fromJson(m).horasTranscurridas, 10);
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
