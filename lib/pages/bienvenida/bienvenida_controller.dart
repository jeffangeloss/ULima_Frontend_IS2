// lib/pages/bienvenida/bienvenida_controller.dart
// La conversación de la bienvenida con Ulises (RF-BIEN-1 a RF-BIEN-13 y
// RF-BIEN-21 de specs/features/bienvenida/bienvenida.spec.md). Es permanente,
// como LoginController, con una visita por cada montaje de su página (B-19).
// Decide qué dice Ulises, qué pide el compositor y cuánto espera cada
// burbuja, y deja el dibujo y el ritmo a la página. Crea y cierra ella misma
// los controladores del registro y del test, sin Get.put (B-20 y B-34).

import 'dart:async';

import 'package:flutter/services.dart' show TextInput;
import 'package:get/get.dart';

import '../../domain/bienvenida/bienvenida_turnos.dart';
import '../../services/auth_service.dart';
import '../../services/post_login_route.dart';
import '../../services/session_navigation.dart';
import '../../services/storage_service.dart';
import '../login/login_controller.dart';
import '../registro/registro_controller.dart';
import '../specialty_test/specialty_test_controller.dart';
import 'conversacion.dart';

typedef TextosB = TextosDeLaBienvenida;
typedef TurnoB = TurnoDeLaBienvenida;

class BienvenidaController extends GetxController {
  BienvenidaController({
    AuthService? auth,
    LoginController? login,
    RegistroController Function()? crearRegistro,
    Future<String?> Function()? tokenGuardado,
    void Function(String ruta)? abrirRuta,
    void Function()? terminarAutocompletado,
  }) : _authInyectado = auth,
       _loginInyectado = login,
       _crearRegistro = crearRegistro ?? RegistroController.new,
       _tokenGuardado = tokenGuardado ?? (() => StorageService.to.savedToken),
       _abrirRuta = abrirRuta ?? ((ruta) => Get.toNamed<void>(ruta)),
       _terminarAutocompletado =
           terminarAutocompletado ?? (() => TextInput.finishAutofillContext());

  final AuthService? _authInyectado;
  final LoginController? _loginInyectado;
  final RegistroController Function() _crearRegistro;
  final Future<String?> Function() _tokenGuardado;
  final void Function(String ruta) _abrirRuta;

  /// Cierra el contexto del autocompletado para que el sistema ofrezca
  /// guardar el código y la contraseña (RF-BIEN-6). Las pruebas lo cambian
  /// por un registro, porque en la VM no hay plataforma que lo reciba.
  final void Function() _terminarAutocompletado;

  AuthService get _auth => _authInyectado ?? AuthService.to;
  LoginController get _login => _loginInyectado ?? Get.find<LoginController>();

  /// El historial vive solo aquí, en memoria (RF-BIEN-5).
  final entradas = <EntradaDeLaConversacion>[].obs;

  /// El turno del compositor abierto, o null con el compositor cerrado.
  final turno = Rxn<TurnoDeLaBienvenida>();

  /// El último turno abierto, que decide el atrás del sistema.
  final ultimoTurno = Rxn<TurnoDeLaBienvenida>();
  final esperando = false.obs;
  final errorLocal = RxnString();

  /// Sube con cada respuesta del alumno, y el sello late (RF-BIEN-4).
  final latidos = 0.obs;

  RegistroController? registro;
  SpecialtyTestController? test;

  int _visita = 0;
  int _siguienteId = 0;
  bool _conSesion = false;
  Worker? _googleEnWeb;

  /// La visita trae una sesión puesta o la puso «Sí, entrar» (RF-BIEN-21).
  bool get conSesion => _conSesion;

  @override
  void onInit() {
    super.onInit();
    _googleEnWeb = ever<DesenlaceDelLogin?>(_login.desenlaceDeGoogleEnWeb, (d) {
      if (d == null) return;
      // Se consume siempre, así un desenlace igual al anterior vuelve a
      // llegar. Solo cuenta mientras E1 está abierto (RF-BIEN-6).
      _login.desenlaceDeGoogleEnWeb.value = null;
      if (turno.value != TurnoB.e1Codigo) return;
      _trasGoogle(d);
    });
  }

  @override
  void onClose() {
    _googleEnWeb?.dispose();
    _cerrarLosTramos();
    super.onClose();
  }

  // ── Ayudas ───────────────────────────────────────────────────────────────

  int _id() => _siguienteId++;

  /// Ulises dice [lineas]. La primera espera [primera] y las siguientes
  /// 850 ms (RF-BIEN-5).
  void _decir(
    List<String> lineas, {
    Duration primera = Ritmo.trasLaRespuesta,
    TipoDeBurbuja tipo = TipoDeBurbuja.texto,
  }) {
    for (var i = 0; i < lineas.length; i++) {
      entradas.add(
        BurbujaDeUlises(
          id: _id(),
          texto: lineas[i],
          tipo: tipo,
          pausa: i == 0 ? primera : Ritmo.entreBurbujas,
        ),
      );
    }
  }

  /// Un error del backend o de la red, que entra enseguida (RF-BIEN-12).
  void _decirError(String mensaje) => _decir(
    <String>[mensaje],
    primera: Duration.zero,
    tipo: TipoDeBurbuja.error,
  );

  /// El compositor se cierra, entra la respuesta y el sello late.
  void _responder(
    String texto, {
    bool secreta = false,
    bool conGoogle = false,
  }) {
    turno.value = null;
    errorLocal.value = null;
    entradas.add(
      RespuestaDelAlumno(
        id: _id(),
        texto: texto,
        secreta: secreta,
        conGoogle: conGoogle,
      ),
    );
    latidos.value++;
  }

  void _abrir(TurnoDeLaBienvenida t) {
    turno.value = t;
    ultimoTurno.value = t;
  }

  // ── Visitas (RF-BIEN-1) ──────────────────────────────────────────────────

  /// El State de la página crea una visita al montarse.
  int nuevaVisita() => ++_visita;

  /// Después del primer cuadro de la página. Borra la conversación, cierra
  /// los tramos, vacía el login y mira si hay una sesión puesta.
  Future<void> empezarVisita(int visita, {MotivoDeLlegada? motivo}) async {
    if (visita != _visita) return;
    _reiniciar();
    final token = await _tokenGuardado();
    if (visita != _visita) return;
    final usuario = _auth.currentUser;
    final hayToken = token != null && token.isNotEmpty;
    if (motivo == null && hayToken && usuario != null) {
      // La llegada con sesión sigue lo que diga postLoginRoute (RF-BIEN-21).
      _conSesion = true;
      if (postLoginRoute(usuario) == '/home') {
        _decir(<String>[TextosB.e3], primera: Duration.zero);
        _abrir(TurnoB.pasoAlHorario);
        return;
      }
      _abrir(TurnoB.llegadaConSesion);
      return;
    }
    if (motivo != null) {
      // Directo a «Sí, entrar», con el sello ya en su lugar (RF-BIEN-3).
      _decir(<String>[TextosB.saludo], primera: Duration.zero);
      _abrirE1(primera: Ritmo.entreBurbujas);
      return;
    }
    _abrir(TurnoB.recibimiento);
  }

  /// El dispose de la página. Una visita vieja no toca la nueva.
  void terminarVisita(int visita) {
    if (visita != _visita) return;
    _cerrarLosTramos();
  }

  void _reiniciar() {
    _cerrarLosTramos();
    entradas.clear();
    turno.value = null;
    ultimoTurno.value = null;
    esperando.value = false;
    errorLocal.value = null;
    _conSesion = false;
    _login.vaciarCampos();
  }

  void _cerrarLosTramos() {
    _cerrarRegistro();
    _cerrarTest();
  }

  void _cerrarRegistro() {
    registro?.cerrar();
    registro = null;
  }

  void _cerrarTest() {
    test?.onDelete();
    test = null;
  }

  // ── Recibimiento (RF-BIEN-2 y RF-BIEN-21) ────────────────────────────────

  /// «Sí, entrar» o «Soy nuevo». La conversación ya trae el primer grupo.
  void responderAlSaludo({required bool yaUsa}) {
    if (turno.value != TurnoB.recibimiento) return;
    entradas.add(BurbujaDeUlises(id: _id(), texto: TextosB.saludo));
    entradas.add(BurbujaDeUlises(id: _id(), texto: TextosB.pregunta));
    _responder(yaUsa ? TextosB.siEntrar : TextosB.soyNuevo);
    if (yaUsa) {
      _abrirE1();
    } else {
      _abrirN1();
    }
  }

  /// En la llegada con sesión, el fin del rebote de Ulises hace de respuesta,
  /// sin respuesta del alumno.
  void ulisesAterrizoConSesion() {
    if (turno.value != TurnoB.llegadaConSesion) return;
    turno.value = null;
    entradas.add(BurbujaDeUlises(id: _id(), texto: TextosB.saludoConSesion));
    entradas.add(BurbujaDeUlises(id: _id(), texto: TextosB.faltaEspecialidad));
    _empezarElTest();
  }

  // ── «Sí, entrar» (RF-BIEN-6) ─────────────────────────────────────────────

  void _abrirE1({Duration primera = Ritmo.trasLaRespuesta}) {
    _decir(<String>[TextosB.e1], primera: primera);
    _abrir(TurnoB.e1Codigo);
  }

  void enviarCodigo() {
    if (turno.value != TurnoB.e1Codigo) return;
    final codigo = _login.codeController.text.trim();
    if (codigo.isEmpty) return;
    _responder(codigo);
    _decir(<String>[TextosB.e2]);
    _abrir(TurnoB.e2Contrasena);
  }

  Future<void> entrar() async {
    if (turno.value != TurnoB.e2Contrasena || esperando.value) return;
    if (_login.passwordController.text.isEmpty) return;
    esperando.value = true;
    final d = await _login.entrar();
    esperando.value = false;
    switch (d.tipo) {
      case TipoDeDesenlace.sesionPuesta:
        // Con los dos campos todavía escritos y montados, el sistema empareja
        // el usuario con la contraseña y ofrece guardarlos. Los campos se
        // vacían después, al pasar al horario o al reiniciar (RF-BIEN-6).
        _terminarAutocompletado();
        _responder(TextosB.contrasenaLista, secreta: true);
        _trasEntrar();
      case TipoDeDesenlace.error:
        // Vuelve a E1 con el código escrito y la contraseña vacía (B-6).
        _login.passwordController.clear();
        _decirError(d.mensaje ?? TextosB.sinConexion);
        _abrir(TurnoB.e1Codigo);
      case TipoDeDesenlace.sinConexion:
        _decirError(TextosB.sinConexion);
        _abrir(TurnoB.e2Contrasena);
      case TipoDeDesenlace.cancelado:
        break;
    }
  }

  Future<void> entrarConGoogle() async {
    if (turno.value != TurnoB.e1Codigo || esperando.value) return;
    esperando.value = true;
    final d = await _login.entrarConGoogle();
    esperando.value = false;
    _trasGoogle(d);
  }

  void _trasGoogle(DesenlaceDelLogin d) {
    switch (d.tipo) {
      case TipoDeDesenlace.sesionPuesta:
        _responder(TextosB.continuarConGoogle, conGoogle: true);
        _trasEntrar();
      case TipoDeDesenlace.error:
        _decirError(d.mensaje ?? TextosB.sinConexion);
      case TipoDeDesenlace.sinConexion:
        _decirError(TextosB.sinConexion);
      case TipoDeDesenlace.cancelado:
        break;
    }
  }

  /// Con la sesión puesta, un docente o un alumno completo van al horario y
  /// un alumno a medias sigue con el test, sin navegar a /setup-carrera
  /// (RF-BIEN-6 y B-10).
  void _trasEntrar() {
    final usuario = _auth.currentUser;
    if (usuario == null) return;
    _conSesion = true;
    if (postLoginRoute(usuario) == '/home') {
      _decir(<String>[TextosB.e3]);
      _abrir(TurnoB.pasoAlHorario);
      return;
    }
    _decir(<String>[TextosB.holaFaltaEspecialidad]);
    _empezarElTest();
  }

  /// «Soy nuevo» en E1 o en E2. Lo escrito no pasa de una rama a la otra.
  void soyNuevo() {
    final t = turno.value;
    if (t != TurnoB.e1Codigo && t != TurnoB.e2Contrasena) return;
    _responder(TextosB.soyNuevo);
    _login.vaciarCampos();
    _abrirN1();
  }

  /// Abre /forgot-password encima, con el sello en su cabecera (B-9).
  void abrirOlvido() => _abrirRuta('/forgot-password');

  void volverAE1() {
    if (turno.value != TurnoB.e2Contrasena) return;
    _abrir(TurnoB.e1Codigo);
  }

  // ── Registro (Tarea 24) ──────────────────────────────────────────────────

  void _abrirN1({Duration primera = Ritmo.trasLaRespuesta}) {
    registro ??= _crearRegistro();
    _decir(<String>[TextosB.n1a, TextosB.n1b], primera: primera);
    _abrir(TurnoB.n1Codigo);
  }

  // ── Test (Tarea 25) ──────────────────────────────────────────────────────

  void _empezarElTest() {
    _abrir(TurnoB.t0Invitacion);
  }

  // ── Atrás (RF-BIEN-13) ───────────────────────────────────────────────────

  AccionDelAtras get _accionDelAtras =>
      accionDelAtras(ultimoTurno.value ?? TurnoB.recibimiento);

  bool get atrasSaleDeLaApp => _accionDelAtras == AccionDelAtras.salirDeLaApp;

  void atras() {
    switch (_accionDelAtras) {
      case AccionDelAtras.volverAE1:
        volverAE1();
      case AccionDelAtras.yaTengoCuenta:
      case AccionDelAtras.volver:
      case AccionDelAtras.avisarQueSeEnvia:
      case AccionDelAtras.volverAIntentar:
      case AccionDelAtras.preguntaAnterior:
      case AccionDelAtras.irAT0:
      case AccionDelAtras.salirDeLaApp:
      case AccionDelAtras.nada:
        break;
    }
  }

  // ── Paso al horario (RF-BIEN-11) ─────────────────────────────────────────

  /// La página entregó el paso a la capa y navegó a /home. Se cierran los
  /// tramos, se borra el historial y se vacían los campos.
  void pasoHecho() => _reiniciar();
}
