// lib/pages/bienvenida/bienvenida_page.dart
// La página de /login con la bienvenida de Ulises (RF-BIEN-1 a RF-BIEN-17).
// Cada montaje es una visita. El primer cuadro sale solo de los argumentos de
// la ruta, que son la pose del splash, el motivo o ninguno, y avisa a la capa
// del arranque cuando lo pinta (RF-SPL-21). Después pinta el estado del
// controlador, con el ritmo del revelador.

import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../components/logo/escena_del_logo.dart';
import '../../components/logo/estrella_del_logo.dart' show EscenaFija;
import '../../components/logo/pintor_del_logo.dart';
import '../../components/logo/sello_del_logo.dart';
import '../../configs/themes.dart';
import '../../domain/bienvenida/bienvenida_turnos.dart';
import '../../services/session_navigation.dart';
import '../specialty_test/widgets/result_view.dart' show PintorDelConfeti;
import '../splash/capa_de_arranque.dart';
import '../splash/salidas.dart' show naranjaDelSplash;
import 'bienvenida_controller.dart';
import 'conversacion.dart';
import 'widgets/burbujas.dart';
import 'widgets/compositor.dart';
import 'widgets/compositor_del_test.dart';
import 'widgets/franja_con_sello.dart';
import 'widgets/revelador.dart';

class BienvenidaPage extends StatefulWidget {
  const BienvenidaPage({super.key});

  @override
  State<BienvenidaPage> createState() => _BienvenidaPageState();
}

class _BienvenidaPageState extends State<BienvenidaPage>
    with TickerProviderStateMixin {
  late final BienvenidaController _c = Get.find<BienvenidaController>();
  late final int _visita;
  final Revelador _revelador = Revelador();
  final ScrollController _desplazamiento = ScrollController();
  late final AnimationController _latido = AnimationController(
    vsync: this,
    duration: duracionDelLatido,
  );
  final ValueNotifier<List<double>?> _rombos = ValueNotifier<List<double>?>(
    null,
  );
  late final Ticker _pulso = createTicker(_alPulsar);
  late final AnimationController _confeti = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );
  final List<Worker> _trabajos = <Worker>[];
  Timer? _finDeLaPildora;
  final ValueNotifier<EstadoDeLaPildora?> _pildora =
      ValueNotifier<EstadoDeLaPildora?>(null);

  bool _leida = false;
  PoseDelLogo? _pose;
  MotivoDeLlegada? _motivo;

  bool get _sinMovimiento => MediaQuery.disableAnimationsOf(context);
  bool get _conLector => MediaQuery.accessibleNavigationOf(context);

  @override
  void initState() {
    super.initState();
    _visita = _c.nuevaVisita();
    _trabajos.addAll(<Worker>[
      ever<int>(_c.latidos, (_) => _latir()),
      ever<bool>(_c.enviando, _alCambiarElEnvio),
      ever<EstadoDeLaPildora?>(_c.pildora, _alCambiarLaPildora),
      ever<List<EntradaDeLaConversacion>>(_c.entradas, (_) => _sincronizar()),
      ever<TurnoDeLaBienvenida?>(_c.turno, (_) => _sincronizar()),
      ever<int>(_c.visitaEmpezada, (_) => _sincronizar()),
      ever<int>(_c.confeti, (_) {
        if (!mounted || _sinMovimiento) return;
        unawaited(HapticFeedback.heavyImpact());
        unawaited(_confeti.forward(from: 0));
      }),
    ]);
    _revelador.addListener(_alRevelar);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // El primer cuadro ya se pintó igual al último de la intro.
      CapaDeArranque.avisarPrimerCuadroDeLaBienvenida();
      unawaited(_c.empezarVisita(_visita, motivo: _motivo));
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_leida) return;
    _leida = true;
    final argumentos = ModalRoute.of(context)?.settings.arguments;
    if (argumentos is Map) {
      final pose = argumentos[argumentoDePose];
      final motivo = argumentos[argumentoDeMotivo];
      _pose = pose is PoseDelLogo ? pose : null;
      _motivo = motivo is MotivoDeLlegada ? motivo : null;
    }
    // Sin pose, el splash no precargó a Ulises (RF-BIEN-3).
    if (_pose == null) {
      unawaited(
        precacheImage(
          const AssetImage('assets/images/ulises_chatbot.png'),
          context,
        ).catchError((Object _) {}),
      );
    }
  }

  bool get _atendida => _c.visitaEmpezada.value == _visita;

  void _sincronizar() {
    if (!mounted || !_atendida) return;
    final turno = _c.turno.value;
    _revelador.actualizar(
      entradas: _c.entradas,
      hayCompositor: turno != null && _tieneCompositor(turno),
      conLector: _conLector,
      pausaDelCompositor: turno == TurnoDeLaBienvenida.pasoAlHorario
          ? Ritmo.antesDelPaso
          : Ritmo.antesDelCompositor,
    );
  }

  bool _tieneCompositor(TurnoDeLaBienvenida t) =>
      t != TurnoDeLaBienvenida.recibimiento &&
      t != TurnoDeLaBienvenida.llegadaConSesion;

  void _alRevelar() {
    if (!mounted) return;
    setState(() {});
    // La conversación se desplaza en 450 ms hasta el final, o salta con
    // reducir movimiento (RF-BIEN-5 y RF-BIEN-15).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_desplazamiento.hasClients) return;
      final fin = _desplazamiento.position.maxScrollExtent;
      if (_sinMovimiento) {
        _desplazamiento.jumpTo(fin);
      } else {
        unawaited(
          _desplazamiento.animateTo(
            fin,
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeOutCubic,
          ),
        );
      }
    });
  }

  void _latir() {
    if (!mounted || _sinMovimiento) return;
    unawaited(_latido.forward(from: 0));
  }

  Duration _inicioDelPulso = Duration.zero;
  Duration _ahoraDelPulso = Duration.zero;
  List<double>? _desdeAlApagar;

  void _alCambiarElEnvio(bool enviando) {
    if (!mounted || _sinMovimiento) return;
    _inicioDelPulso = _ahoraDelPulso;
    _desdeAlApagar = enviando ? null : _rombos.value;
    if (!_pulso.isActive) unawaited(_pulso.start());
  }

  /// El pulso recorre los ocho rombos mientras se envía, y con cualquier
  /// desenlace vuelven a la opacidad plena en 200 ms (RF-BIEN-4).
  void _alPulsar(Duration t) {
    _ahoraDelPulso = t;
    final ms = (t - _inicioDelPulso).inMicroseconds / 1000;
    if (_c.enviando.value) {
      final p = posicionDelPulso(ms);
      _rombos.value = <double>[
        for (var k = 0; k < 8; k++) opacidadDelRombo(k, p),
      ];
      return;
    }
    final desde = _desdeAlApagar;
    final avance = (ms / 200).clamp(0.0, 1.0);
    if (desde == null || avance >= 1) {
      _rombos.value = null;
      _pulso.stop();
      return;
    }
    _rombos.value = <double>[for (final o in desde) o + (1 - o) * avance];
  }

  void _alCambiarLaPildora(EstadoDeLaPildora? estado) {
    _finDeLaPildora?.cancel();
    _pildora.value = estado;
    // «Cuenta creada» se va 900 ms después (RF-BIEN-8).
    if (estado == EstadoDeLaPildora.creada) {
      _finDeLaPildora = Timer(const Duration(milliseconds: 900), () {
        _pildora.value = null;
      });
    }
  }

  @override
  void dispose() {
    for (final w in _trabajos) {
      w.dispose();
    }
    _finDeLaPildora?.cancel();
    _revelador
      ..removeListener(_alRevelar)
      ..dispose();
    _desplazamiento.dispose();
    _latido.dispose();
    _confeti.dispose();
    _pulso.dispose();
    _rombos.dispose();
    _pildora.dispose();
    _c.terminarVisita(_visita);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final b = Theme.brightnessOf(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Arriba siempre hay #E77330, la franja naranja o la #262626
      // (RF-BIEN-17).
      value: SystemUiOverlayStyle.light,
      child: Obx(
        () => PopScope(
          canPop: _atendida && _c.atrasSaleDeLaApp,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _c.atras();
          },
          child: Scaffold(
            backgroundColor: MaterialTheme.pageBg(b),
            resizeToAvoidBottomInset: true,
            // Un solo grupo del autocompletado para todos los turnos, que
            // vive lo que vive la página, así que E1 y E2 comparten el mismo
            // aunque el compositor cambie. Al salir no guarda nada, porque
            // solo la sesión puesta cierra el contexto con
            // finishAutofillContext (RF-BIEN-6).
            body: AutofillGroup(
              onDisposeAction: AutofillContextAction.cancel,
              child: _cuerpo(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _cuerpo(BuildContext context) {
    final atendida = _atendida;
    final turno = atendida ? _c.ultimoTurno.value : null;
    // Antes de que el controlador atienda la visita, el primer cuadro sale
    // solo de los argumentos (RF-BIEN-1).
    final directo = _motivo != null;
    final enElPrimerCuadro =
        !directo &&
        (!atendida ||
            turno == TurnoDeLaBienvenida.recibimiento ||
            turno == TurnoDeLaBienvenida.llegadaConSesion);
    return Stack(
      children: [
        _conversacion(context, atendida: atendida),
        Positioned(
          top: CabeceraConSello.alto(context),
          left: 0,
          right: 0,
          bottom: 0,
          child: IgnorePointer(
            child: ClipRect(
              child: AnimatedBuilder(
                animation: _confeti,
                builder: (context, _) => _confeti.isAnimating
                    ? CustomPaint(painter: PintorDelConfeti(_confeti.value))
                    : const SizedBox.shrink(),
              ),
            ),
          ),
        ),
        if (enElPrimerCuadro) Positioned.fill(child: _primerCuadro(context)),
        Positioned(
          top: CabeceraConSello.alto(context) + 8,
          left: 0,
          right: 0,
          child: Center(
            child: ValueListenableBuilder<EstadoDeLaPildora?>(
              valueListenable: _pildora,
              builder: (context, estado, _) => estado == null
                  ? const SizedBox.shrink()
                  : PildoraDelRegistro(estado: estado),
            ),
          ),
        ),
      ],
    );
  }

  /// #E77330 de borde a borde y el logo blanco en la pose recibida, o en su
  /// pose de reposo sin pose, en los dos temas (RF-BIEN-2 y RF-BIEN-3).
  Widget _primerCuadro(BuildContext context) {
    final pose = _pose ?? _poseDeReposo(context);
    return ColoredBox(
      color: naranjaDelSplash,
      child: LogoEnEscena(escena: EscenaFija(EscenaDelLogo.desdePose(pose))),
    );
  }

  PoseDelLogo _poseDeReposo(BuildContext context) {
    final vista = MediaQuery.sizeOf(context);
    final pantalla = View.of(context).display;
    // En web la estrella se centra en la vista, porque display.size es el
    // del monitor (RF-BIEN-3).
    final centro = kIsWeb
        ? vista.center(Offset.zero)
        : centroDelNativo(vista, pantalla.size / pantalla.devicePixelRatio);
    return EscenaDelLogo.reposo(centro: centro, radio: radioDelNativo).pose;
  }

  Widget _conversacion(BuildContext context, {required bool atendida}) {
    final visibles = atendida ? _revelador.visibles : 0;
    final entradas = _c.entradas;
    final turno = _c.turno.value;
    final primerIdDeUlises = entradas
        .whereType<BurbujaDeUlises>()
        .map((e) => e.id)
        .firstOrNull;
    // El compositor mide hasta el 60 % del alto sobre el teclado (RF-BIEN-5).
    return LayoutBuilder(
      builder: (context, limites) => Column(
        children: [
          FranjaConSello(latido: _latido, rombos: _rombos),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: ListView.builder(
                  controller: _desplazamiento,
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                  itemCount: visibles.clamp(0, entradas.length),
                  itemBuilder: (context, i) {
                    final entrada = entradas[i];
                    final anterior = i > 0 ? entradas[i - 1] : null;
                    return EntradaView(
                      key: ValueKey<int>(entrada.id),
                      entrada: entrada,
                      anterior: anterior,
                      primerGrupo: _enElPrimerGrupo(
                        entradas,
                        i,
                        primerIdDeUlises,
                      ),
                      conMovimiento: !_sinMovimiento,
                      resultado: (context) => ResultadoEnLaConversacion(c: _c),
                    );
                  },
                ),
              ),
            ),
          ),
          if (atendida && turno != null && _revelador.compositorVisible)
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: _CompositorAnimado(
                  key: ValueKey<TurnoDeLaBienvenida>(turno),
                  conMovimiento: !_sinMovimiento,
                  altoDisponible: limites.maxHeight,
                  child: compositorDelTurno(context, _c, turno),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// El primer grupo de Ulises es el de las burbujas desde la primera hasta
  /// la primera respuesta del alumno.
  bool _enElPrimerGrupo(
    List<EntradaDeLaConversacion> entradas,
    int i,
    int? primerId,
  ) {
    if (primerId == null) return false;
    for (var j = 0; j <= i; j++) {
      if (entradas[j] is RespuestaDelAlumno) return false;
    }
    return true;
  }
}

/// El compositor entra en 300 ms, subiendo 8 dp, o con un fundido de 200 ms
/// con reducir movimiento (RF-BIEN-5 y RF-BIEN-15).
class _CompositorAnimado extends StatelessWidget {
  const _CompositorAnimado({
    super.key,
    required this.conMovimiento,
    required this.altoDisponible,
    required this.child,
  });

  final bool conMovimiento;
  final double altoDisponible;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final contenido = child;
    if (contenido == null) return const SizedBox.shrink();
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: conMovimiento ? 300 : 200),
      curve: Curves.easeOutCubic,
      child: MarcoDelCompositor(
        altoDisponible: altoDisponible,
        child: contenido,
      ),
      builder: (context, t, hijo) => Opacity(
        opacity: t,
        child: conMovimiento
            ? Transform.translate(offset: Offset(0, 8 * (1 - t)), child: hijo)
            : hijo,
      ),
    );
  }
}
