// test/HU26_sam/export_csv_cajanegra_test.dart
//
// CAJA NEGRA — HU26: exportación de la lista de impedidos a CSV.
// Método: AttendanceRiskService.exportCsv()  — lib/services/attendance_risk_service.dart
//
// Se valida la SALIDA observable por el docente al tocar "Exportar CSV":
//   · nombre del archivo compartido: Ausencias_<Curso>_S<sección>.csv
//   · encabezado de 8 columnas
//   · una fila por alumno con % (1 decimal) y la etiqueta de estado
//   · el diálogo de compartir recibe ese mismo archivo y el texto del reporte
//
// DOBLES DE PRUEBA (plataformas nativas, no lógica):
//   · PathProviderPlatform -> carpeta temporal del test (sin canal nativo)
//   · SharePlatform        -> espía que captura qué se compartió
// La generación del CSV (StringBuffer + formato) es 100% real.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:share_plus_platform_interface/share_plus_platform_interface.dart';
import 'package:ulima_plus/models/at_risk_student_model.dart';
import 'package:ulima_plus/services/attendance_risk_service.dart';

class _FakePathProvider extends PathProviderPlatform {
  _FakePathProvider(this.tempPath);

  final String tempPath;

  @override
  Future<String?> getTemporaryPath() async => tempPath;
}

class _SpyShare extends SharePlatform {
  ShareParams? ultimo;

  @override
  Future<ShareResult> share(ShareParams params) async {
    ultimo = params;
    return ShareResult('ok', ShareResultStatus.success);
  }
}

AtRiskStudent alumno({
  required String code,
  required String firstName,
  required String lastName,
  required int currentLevel,
  required int absent,
  required double pct,
  required String status,
  int? faltas,
}) =>
    AtRiskStudent(
      code: code,
      firstName: firstName,
      lastName: lastName,
      currentLevel: currentLevel,
      cycle: 3,
      absentHours: absent,
      totalHours: 100,
      absencePercentage: pct,
      status: status,
      missingFaltas: faltas,
    );

void main() {
  // Un ÚNICO spy compartido: share_plus cachea la plataforma en el primer uso,
  // por lo que instalar un spy nuevo por test dejaría ciegos a los siguientes.
  final share = _SpyShare();
  setUpAll(() {
    SharePlatform.instance = share;
  });
  setUp(() {
    share.ultimo = null;
  });

  test('CN1: genera Ausencias_<Curso>_S<sección>.csv con encabezado y una fila por alumno', () async {
    final tmp = await Directory.systemTemp.createTemp('hu26_csv_');
    addTearDown(() => tmp.delete(recursive: true));

    PathProviderPlatform.instance = _FakePathProvider(tmp.path);

    final estudiantes = [
      alumno(
        code: '20230001',
        firstName: 'Maria',
        lastName: 'Garcia Lopez',
        currentLevel: 5,
        absent: 40,
        pct: 40.0,
        status: 'impedido',
      ),
      alumno(
        code: '20230002',
        firstName: 'Luis',
        lastName: 'Torres Vega',
        currentLevel: 4,
        absent: 21,
        pct: 21.5,
        status: 'en_riesgo',
        faltas: 2,
      ),
    ];

    await AttendanceRiskService()
        .exportCsv(estudiantes, 'Ingenieria de Software', '801');

    // El archivo se crea con el curso saneado (espacios -> _) y la sección.
    final file = File('${tmp.path}/Ausencias_Ingenieria_de_Software_S801.csv');
    expect(file.existsSync(), isTrue);

    final lineas = file.readAsStringSync().trim().split(RegExp(r'\r?\n'));
    expect(lineas, hasLength(3));
    expect(
      lineas[0],
      'Codigo,Apellidos,Nombres,Ciclo,Horas Ausentes,Total Horas,% Ausencia,Estado',
    );
    expect(lineas[1], '20230001,Garcia Lopez,Maria,5,40,100,40.0,Impedido');
    expect(
      lineas[2],
      '20230002,Torres Vega,Luis,4,21,100,21.5,En Riesgo: a 2 faltas',
    );

    // El diálogo de compartir recibió exactamente ese archivo y el texto.
    expect(share.ultimo, isNotNull);
    expect(share.ultimo!.files!.single.path, file.path);
    expect(
      share.ultimo!.text,
      'Reporte de ausencias - Ingenieria de Software (Seccion 801)',
    );
  });

  test('CN2: lista vacía -> CSV solo con el encabezado (sin filas fantasma)', () async {
    final tmp = await Directory.systemTemp.createTemp('hu26_csv_vacio_');
    addTearDown(() => tmp.delete(recursive: true));

    PathProviderPlatform.instance = _FakePathProvider(tmp.path);

    await AttendanceRiskService().exportCsv(const [], 'Calculo 1', '305');

    final file = File('${tmp.path}/Ausencias_Calculo_1_S305.csv');
    expect(file.existsSync(), isTrue);

    final lineas = file.readAsStringSync().trim().split(RegExp(r'\r?\n'));
    expect(lineas, hasLength(1));
    expect(
      lineas[0],
      'Codigo,Apellidos,Nombres,Ciclo,Horas Ausentes,Total Horas,% Ausencia,Estado',
    );
  });

  test('CN3: ciclo null -> la columna Ciclo sale vacía (no imprime "null")', () async {
    final tmp = await Directory.systemTemp.createTemp('hu26_csv_ciclo_');
    addTearDown(() => tmp.delete(recursive: true));

    PathProviderPlatform.instance = _FakePathProvider(tmp.path);

    final sinCiclo = AtRiskStudent(
      code: '20230003',
      firstName: 'Rosa',
      lastName: 'Nunez Prado',
      currentLevel: null,
      absentHours: 30,
      totalHours: 100,
      absencePercentage: 30.0,
      status: 'impedido',
    );

    await AttendanceRiskService().exportCsv([sinCiclo], 'Fisica 1', '402');

    final file = File('${tmp.path}/Ausencias_Fisica_1_S402.csv');
    final lineas = file.readAsStringSync().trim().split(RegExp(r'\r?\n'));
    expect(lineas[1], '20230003,Nunez Prado,Rosa,,30,100,30.0,Impedido');
    expect(lineas[1].contains('null'), isFalse);
  });

  test('CN4: el porcentaje se redondea SIEMPRE a 1 decimal (33.333 -> 33.3, 25 -> 25.0)', () async {
    final tmp = await Directory.systemTemp.createTemp('hu26_csv_pct_');
    addTearDown(() => tmp.delete(recursive: true));

    PathProviderPlatform.instance = _FakePathProvider(tmp.path);

    final estudiantes = [
      alumno(
        code: '20230004',
        firstName: 'Ana',
        lastName: 'Rios Vela',
        currentLevel: 6,
        absent: 33,
        pct: 33.333,
        status: 'impedido',
      ),
      alumno(
        code: '20230005',
        firstName: 'Jose',
        lastName: 'Diaz Melo',
        currentLevel: 2,
        absent: 25,
        pct: 25.0,
        status: 'impedido',
      ),
    ];

    await AttendanceRiskService().exportCsv(estudiantes, 'Quimica', '110');

    final file = File('${tmp.path}/Ausencias_Quimica_S110.csv');
    final lineas = file.readAsStringSync().trim().split(RegExp(r'\r?\n'));
    expect(lineas[1].split(',')[6], '33.3');
    expect(lineas[2].split(',')[6], '25.0');
  });

  test('CN5: etiqueta de Estado por clase de equivalencia (normal / en_riesgo sin faltas / desconocido)', () async {
    final tmp = await Directory.systemTemp.createTemp('hu26_csv_estado_');
    addTearDown(() => tmp.delete(recursive: true));

    PathProviderPlatform.instance = _FakePathProvider(tmp.path);

    final estudiantes = [
      alumno(
        code: '20230006',
        firstName: 'Ivan',
        lastName: 'Soto Paz',
        currentLevel: 1,
        absent: 2,
        pct: 2.0,
        status: 'normal',
      ),
      // en_riesgo SIN missingFaltas: statusLabel pasa el status crudo.
      alumno(
        code: '20230007',
        firstName: 'Lia',
        lastName: 'Vega Ruiz',
        currentLevel: 3,
        absent: 20,
        pct: 20.0,
        status: 'en_riesgo',
      ),
      // status fuera del dominio conocido: passthrough (clase inválida documentada).
      alumno(
        code: '20230008',
        firstName: 'Teo',
        lastName: 'Mora Solis',
        currentLevel: 4,
        absent: 10,
        pct: 10.0,
        status: 'suspendido',
      ),
    ];

    await AttendanceRiskService().exportCsv(estudiantes, 'Redes', '220');

    final file = File('${tmp.path}/Ausencias_Redes_S220.csv');
    final lineas = file.readAsStringSync().trim().split(RegExp(r'\r?\n'));
    expect(lineas[1].split(',').last, 'Normal');
    expect(lineas[2].split(',').last, 'en_riesgo');
    expect(lineas[3].split(',').last, 'suspendido');
  });

  test('CN6: el nombre del curso se sanea para el archivo (símbolos fuera, espacios -> _)', () async {
    final tmp = await Directory.systemTemp.createTemp('hu26_csv_sanea_');
    addTearDown(() => tmp.delete(recursive: true));

    PathProviderPlatform.instance = _FakePathProvider(tmp.path);

    await AttendanceRiskService().exportCsv(const [], 'Prog. Web 2', '901');

    // El punto se elimina y los espacios pasan a guion bajo.
    final file = File('${tmp.path}/Ausencias_Prog_Web_2_S901.csv');
    expect(file.existsSync(), isTrue);
    // El texto de compartir conserva el nombre ORIGINAL del curso.
    expect(share.ultimo!.text, 'Reporte de ausencias - Prog. Web 2 (Seccion 901)');
  });

  test('CN7 (defecto documentado): un apellido con coma desplaza las columnas porque el CSV no entrecomilla', () async {
    final tmp = await Directory.systemTemp.createTemp('hu26_csv_coma_');
    addTearDown(() => tmp.delete(recursive: true));

    PathProviderPlatform.instance = _FakePathProvider(tmp.path);

    final conComa = alumno(
      code: '20230009',
      firstName: 'Juan',
      lastName: 'Salas, De la Cruz',
      currentLevel: 5,
      absent: 40,
      pct: 40.0,
      status: 'impedido',
    );

    await AttendanceRiskService().exportCsv([conComa], 'Base de Datos', '512');

    final file = File('${tmp.path}/Ausencias_Base_de_Datos_S512.csv');
    final lineas = file.readAsStringSync().trim().split(RegExp(r'\r?\n'));
    // La fila queda con 9 campos en vez de 8: hallazgo registrado en el
    // capítulo de pruebas (el exportador no entrecomilla valores con coma).
    expect(lineas[1].split(','), hasLength(9));
  });
}
