// test/bienvenida/apoyo_bienvenida.dart
//
// Apoyo de las pruebas de la bienvenida. No termina en _test.dart, así que
// `flutter test` no lo corre como suite. Todo dato es inventado.

import 'dart:async';

import 'package:get/get.dart';
import 'package:ulima_plus/models/portal_sync_models.dart';
import 'package:ulima_plus/models/registro_models.dart';
import 'package:ulima_plus/models/user_model.dart';
import 'package:ulima_plus/pages/bienvenida/bienvenida_controller.dart';
import 'package:ulima_plus/pages/bienvenida/conversacion.dart';
import 'package:ulima_plus/pages/login/login_controller.dart';
import 'package:ulima_plus/pages/registro/registro_controller.dart';
import 'package:ulima_plus/services/auth_service.dart';
import 'package:ulima_plus/services/registro_service.dart';
import 'package:ulima_plus/services/session_navigation.dart';

UserModel alumnaDePrueba({bool setupComplete = true, int? careerId = 1}) =>
    UserModel(
      code: '20230001',
      firstName: 'Alumna',
      lastName: 'De Prueba',
      email: 'test@aloe.ulima.edu.pe',
      role: 'student',
      careerId: careerId,
      currentCycle: '2026-2',
      setupComplete: setupComplete,
    );

UserModel docenteDePrueba() => UserModel(
  code: 'docente.test',
  firstName: 'Docente',
  lastName: 'De Prueba',
  email: 'docente.test@ulima.edu.pe',
  role: 'teacher',
  currentCycle: '2026-2',
  setupComplete: true,
);

/// Lo que `AuthService.login` no atrapa.
class RedCaida implements Exception {
  const RedCaida();
}

/// Un AuthService sin red. [alEntrar] es el usuario que queda al entrar.
class AuthDeLaBienvenida extends AuthService {
  AuthDeLaBienvenida({
    this.usuario,
    this.alEntrar,
    this.errorDeLogin,
    this.redCaida = false,
    this.google,
  });

  UserModel? usuario;
  UserModel? alEntrar;
  String? errorDeLogin;
  bool redCaida;

  /// Lo que devuelve Google, con 'cancelar' para el selector cerrado.
  String? google;
  int logouts = 0;

  @override
  UserModel? get currentUser => usuario;

  @override
  Future<String?> login({
    required String code,
    required String password,
  }) async {
    if (redCaida) throw const RedCaida();
    if (errorDeLogin != null) return errorDeLogin;
    usuario = alEntrar ?? alumnaDePrueba();
    return null;
  }

  @override
  Future<String?> loginWithGoogle() async {
    if (google == 'cancelar') return null;
    if (google != null) return google;
    usuario = alEntrar ?? alumnaDePrueba();
    return null;
  }

  @override
  Future<void> logout() async {
    logouts++;
    usuario = null;
  }
}

/// Un RegistroService sin red. Responde con [resultado], lanza [fallo] o
/// espera a [pendiente], y cuenta las llamadas.
class RegistroFalso implements RegistroService {
  RegistroFalso({this.resultado, this.fallo, this.pendiente});

  RegistroResult? resultado;
  RegistroFailure? fallo;
  Completer<RegistroResult>? pendiente;
  int llamadas = 0;

  @override
  Future<RegistroResult> registrar({
    required String code,
    required String portalPassword,
    required String passcode,
    required String password,
    required bool consent,
  }) async {
    llamadas++;
    if (pendiente != null) return pendiente!.future;
    if (fallo != null) throw fallo!;
    return resultado!;
  }
}

RegistroResult resultadoDelRegistro({
  int cursos = 5,
  List<String> avisos = const <String>[],
}) => RegistroResult(
  token: 'jwt-de-prueba',
  user: alumnaDePrueba(setupComplete: false),
  summary: PortalSyncSummary(
    coursesCreated: 0,
    sectionsCreated: 0,
    sectionsUpdated: 0,
    sessionsUpserted: 12,
    enrollmentsUpserted: cursos,
    enrollmentsWithdrawn: 0,
    progressUpserted: 40,
    syllabiUpserted: 0,
  ),
  warnings: <PortalSyncWarning>[
    for (final a in avisos)
      PortalSyncWarning.fromJson(<String, dynamic>{
        'code': 'AVISO',
        'message': a,
      }),
  ],
);

/// El controlador de la bienvenida con sus dobles, fuera de GetX.
class Bienvenida {
  Bienvenida({
    AuthDeLaBienvenida? auth,
    this.token,
    RegistroFalso? registro,
    this.adoptarFalla = false,
  }) : auth = auth ?? AuthDeLaBienvenida(),
       servicioDeRegistro =
           registro ?? RegistroFalso(resultado: resultadoDelRegistro()) {
    Get.testMode = true;
    Get.put<AuthService>(this.auth);
    login = LoginController();
    controlador = BienvenidaController(
      auth: this.auth,
      login: login,
      tokenGuardado: () async => token,
      abrirRuta: rutas.add,
      terminarAutocompletado: () => autocompletados.add((
        codigo: login.codeController.text,
        contrasena: login.passwordController.text,
      )),
      crearRegistro: () => RegistroController(
        service: servicioDeRegistro,
        adoptarSesion: ({required token, required user}) async {
          if (adoptarFalla) throw StateError('sin catálogos');
          this.auth.usuario = user;
        },
        iniciarSesion: ({required code, required password}) =>
            this.auth.login(code: code, password: password),
      ),
      avisar: (titulo, texto) => avisos.add(titulo),
    )..onStart();
  }

  final AuthDeLaBienvenida auth;
  final RegistroFalso servicioDeRegistro;
  final bool adoptarFalla;

  /// Los títulos de los avisos que salen abajo (B-29).
  final List<String> avisos = <String>[];
  String? token;
  final List<String> rutas = <String>[];

  /// Cada cierre del autocompletado, con lo que tenían los campos en ese
  /// momento (RF-BIEN-6).
  final List<({String codigo, String contrasena})> autocompletados =
      <({String codigo, String contrasena})>[];
  late final LoginController login;
  late final BienvenidaController controlador;

  List<String> get deUlises => <String>[
    for (final e in controlador.entradas)
      if (e is BurbujaDeUlises) e.texto,
  ];

  List<String> get delAlumno => <String>[
    for (final e in controlador.entradas)
      if (e is RespuestaDelAlumno) e.texto,
  ];

  /// Empieza una visita nueva, como el primer cuadro de la página.
  Future<void> visitar({MotivoDeLlegada? motivo}) async {
    final v = controlador.nuevaVisita();
    await controlador.empezarVisita(v, motivo: motivo);
  }
}
