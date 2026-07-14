// CAJA NEGRA — HU22: lista de alumnos impedidos.
// Se prueba lo que hace el docente y lo que observa en pantalla.
//
// Casos:
// 1. Abrir la página muestra los alumnos.
// 2. Elegir "Impedidos" muestra solo a los impedidos.
// 3. Buscar un apellido muestra al alumno correspondiente.
// 4. Buscar un valor inexistente muestra un mensaje vacío.
//
// TABLA DE PARTICIONES DE EQUIVALENCIA:
//
// | Caso | Entrada                         | Partición              | Salida esperada                    |
// |------|---------------------------------|------------------------|------------------------------------|
// | CN1  | Abrir sección con 3 alumnos     | Lista válida no vacía  | Se muestran los 3 alumnos          |
// | CN2  | Filtro "Impedidos"              | Filtro válido          | Solo se muestra Garcia             |
// | CN3  | Búsqueda "tor"                  | Texto con coincidencia | Solo se muestra Torres             |
// | CN4  | Búsqueda "zzz"                  | Texto sin coincidencia | Se muestra el mensaje sin resultados|
//
// En una prueba de caja negra no revisamos cómo trabaja internamente la página:
// solo realizamos acciones de usuario y comprobamos lo que aparece en pantalla.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/models/at_risk_student_model.dart';
import 'package:ulima_plus/pages/teacher/at_risk_students_controller.dart';
import 'package:ulima_plus/pages/teacher/at_risk_students_page.dart';

// Este controlador falso evita conectarse al backend durante la prueba.
// En lugar de hacer una petición HTTP, entrega la lista de alumnos que
// preparamos más abajo. El filtro y la búsqueda de la página siguen siendo reales.
class _AtRiskControllerFake extends AtRiskStudentsController {
  _AtRiskControllerFake(this._fijos);

  // Alumnos que la página recibirá como datos de prueba.
  final List<AtRiskStudent> _fijos;

  @override
  Future<void> loadData(String sectionId) async {
    // Simulamos una carga exitosa y ordenamos por porcentaje de inasistencia.
    allStudents.value = _fijos;
    isLoading.value = false;
    loadError.value = false;
    setSortMode(SortMode.absenceDesc);
  }
}

// Función auxiliar para crear alumnos sin repetir todos sus campos en cada caso.
AtRiskStudent alumno({
  required String code,
  required String firstName,
  required String lastName,
  required int absent,
  required String status,
  int? faltas,
}) => AtRiskStudent(
  code: code,
  firstName: firstName,
  lastName: lastName,
  currentLevel: 5,
  cycle: 3,
  absentHours: absent,
  totalHours: 100,
  absencePercentage: absent.toDouble(),
  status: status,
  missingFaltas: faltas,
);

// Datos conocidos que usaremos en los cuatro casos de prueba.
// Cada alumno tiene un estado distinto: impedido, en riesgo y normal.
final garcia = alumno(
  code: '20230001',
  firstName: 'Maria',
  lastName: 'Garcia Lopez',
  absent: 40,
  status: 'impedido',
);

final torres = alumno(
  code: '20230002',
  firstName: 'Luis',
  lastName: 'Torres Vega',
  absent: 21,
  status: 'en_riesgo',
  faltas: 2,
);

final luna = alumno(
  code: '20230003',
  firstName: 'Ana',
  lastName: 'Luna Paz',
  absent: 5,
  status: 'normal',
);

// Prepara la pantalla antes de cada prueba.
Future<void> abrirPagina(WidgetTester tester) async {
  // Usamos una pantalla alta para visualizar las tres tarjetas sin desplazarnos.
  tester.view.physicalSize = const Size(800, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  // Registramos el controlador falso con los tres alumnos.
  Get.put<AtRiskStudentsController>(
    _AtRiskControllerFake([luna, garcia, torres]),
  );

  // Construimos la página como si el docente abriera la sección 801.
  await tester.pumpWidget(
    const GetMaterialApp(
      home: AtRiskStudentsPage(
        sectionId: '42',
        courseName: 'Ingenieria de Software',
        sectionCode: '801',
      ),
    ),
  );
  // Esperamos a que Flutter termine de dibujar la pantalla.
  await tester.pump();
}

void main() {
  // GetX se configura en modo prueba para no depender de una aplicación real.
  setUp(() {
    Get.testMode = true;
  });

  // Después de cada caso limpiamos GetX para que una prueba no afecte a otra.
  tearDown(Get.reset);

  testWidgets('CN1: al abrir muestra los tres alumnos', (tester) async {
    // Entrada: el docente abre la lista de la sección.
    await abrirPagina(tester);

    // Salida: aparecen los tres alumnos y el contador total.
    expect(find.text('Maria Garcia Lopez'), findsOneWidget);
    expect(find.text('Luis Torres Vega'), findsOneWidget);
    expect(find.text('Ana Luna Paz'), findsOneWidget);
    expect(find.text('Todos (3)'), findsOneWidget);
  });

  testWidgets('CN2: el filtro Impedidos muestra solo a Garcia', (tester) async {
    await abrirPagina(tester);

    // Entrada: el docente toca el filtro de impedidos.
    await tester.tap(find.text('Impedidos (1)'));
    await tester.pump();

    // Salida: Garcia permanece visible; Torres y Luna desaparecen.
    expect(find.text('Maria Garcia Lopez'), findsOneWidget);
    expect(find.text('Luis Torres Vega'), findsNothing);
    expect(find.text('Ana Luna Paz'), findsNothing);
  });

  testWidgets('CN3: buscar "tor" muestra solo a Torres', (tester) async {
    await abrirPagina(tester);

    // Entrada: el docente escribe parte del apellido en el buscador.
    await tester.enterText(find.byType(TextField), 'tor');
    // La búsqueda espera 300 ms antes de aplicar el filtro.
    await tester.pump(const Duration(milliseconds: 400));

    // Salida: solo aparece el alumno cuyo apellido coincide.
    expect(find.text('Luis Torres Vega'), findsOneWidget);
    expect(find.text('Maria Garcia Lopez'), findsNothing);
    expect(find.text('Ana Luna Paz'), findsNothing);
  });

  testWidgets('CN4: una búsqueda sin resultados muestra el mensaje vacío', (
    tester,
  ) async {
    await abrirPagina(tester);

    // Entrada: el docente escribe un texto que no coincide con ningún alumno.
    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pump(const Duration(milliseconds: 400));

    // Salida: la página informa que no encontró resultados.
    expect(
      find.text('No se encontraron alumnos con ese codigo o apellido'),
      findsOneWidget,
    );
  });
}
