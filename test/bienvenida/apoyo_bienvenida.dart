// test/bienvenida/apoyo_bienvenida.dart
//
// Apoyo de las pruebas de la bienvenida. No termina en _test.dart, así que
// `flutter test` no lo corre como suite. Todo dato es inventado.

import 'package:get/get.dart';
import 'package:ulima_plus/models/user_model.dart';
import 'package:ulima_plus/pages/bienvenida/bienvenida_controller.dart';
import 'package:ulima_plus/pages/bienvenida/conversacion.dart';
import 'package:ulima_plus/pages/login/login_controller.dart';
import 'package:ulima_plus/services/auth_service.dart';
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

/// El controlador de la bienvenida con sus dobles, fuera de GetX.
class Bienvenida {
  Bienvenida({AuthDeLaBienvenida? auth, this.token})
    : auth = auth ?? AuthDeLaBienvenida() {
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
    )..onStart();
  }

  final AuthDeLaBienvenida auth;
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
