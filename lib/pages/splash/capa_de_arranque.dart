// lib/pages/splash/capa_de_arranque.dart
// La capa del arranque (RF-SPL-4 de la spec del splash). Es una pieza fija
// del builder de GetMaterialApp, montada en todas las plataformas. Inactiva
// no pinta nada, no bloquea toques y queda fuera de la semántica. Activa tapa
// la pantalla con la intro y, desde la spec de la bienvenida, con su paso al
// horario (decisión B-33).
//
// Su estado vive en este State y no en un GetxController, porque GetX liga a
// /arranque lo que se registra mientras esa es la ruta actual y lo borra al
// retirarla, en plena salida.

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../components/logo/escena_del_logo.dart';
import '../../components/logo/pintor_del_logo.dart';
import '../../services/session_navigation.dart';
import '../../services/splash_variante_service.dart';
import '../home/home_page.dart' show abrirEnHorario;
import 'estado_de_la_capa.dart';
import 'puntos_de_aterrizaje.dart';
import 'salidas.dart';
import 'variantes/variantes.dart';

/// Lo que la intro necesita del arranque. La carga se inyecta, como el
/// `Random`, así que las pruebas la reemplazan sin Firebase ni el almacén
/// seguro (RF-SPL-4).
class IntroDelArranque {
  const IntroDelArranque({
    required this.carga,
    required this.variantes,
    required this.random,
  });

  final Future<String> Function() carga;
  final SplashVarianteService variantes;
  final Random random;
}

/// La carga falló antes de registrar los servicios, así que no hay una ruta
/// segura (RF-SPL-18).
class FalloAntesDeLosServicios implements Exception {
  const FalloAntesDeLosServicios(this.causa);

  final Object causa;

  @override
  String toString() => 'FalloAntesDeLosServicios($causa)';
}

enum FaseDeLaCapa {
  inactiva,
  eligiendo,
  intro,
  esperandoCabecera,
  salida,
  fundido,
  relevo,
  pasoAlHorario,
}

/// La etiqueta fija de la intro (RF-SPL-15 y S-13).
const String etiquetaDeLaIntro = 'ULIMA++, cargando';

/// El radio de la estrella en el primer cuadro, en dp (RF-SPL-5).
const double radioDelNativo = 90;

/// El centro del nativo es la mitad del alto de la pantalla física, medido
/// desde el borde superior de la vista (S-21). Sin esa medida, o si la
/// pantalla física no alcanza a la vista, es el centro de la vista.
Offset centroDelNativo(Size vista, Size pantallaFisica) {
  final alto = pantallaFisica.height;
  final y = alto > 0 && alto >= vista.height ? alto / 2 : vista.height / 2;
  return Offset(vista.width / 2, y);
}

class CapaDeArranque extends StatefulWidget {
  const CapaDeArranque({super.key, required this.child, this.intro});

  /// El Navigator de GetMaterialApp.
  final Widget child;

  /// La intro, o null en web y donde no hay intro (S-22).
  final IntroDelArranque? intro;

  static _CapaDeArranqueState? _estado;

  static FaseDeLaCapa get fase => _estado?._fase.value ?? FaseDeLaCapa.inactiva;

  @visibleForTesting
  static EscenaDelLogo? get escenaActual => _estado?._escena.value;

  /// La bienvenida avisa que pintó su primer cuadro, igual al último de la
  /// intro, y la capa se retira sin fundido (RF-SPL-21).
  static void avisarPrimerCuadroDeLaBienvenida() =>
      _estado?._alPintarLaBienvenida();

  @visibleForTesting
  static EscenaDeSalida? get salidaActual => _estado?._salida.value;

  /// La opacidad de lo que pinta la capa, que solo baja en un fundido.
  static double get opacidad => _estado?._opacidad.value ?? 1;

  @visibleForTesting
  static void reiniciar() => _estado = null;

  @override
  State<CapaDeArranque> createState() => _CapaDeArranqueState();
}

class _CapaDeArranqueState extends State<CapaDeArranque>
    with SingleTickerProviderStateMixin {
  late final Ticker _reloj = createTicker(_alTic);
  final ValueNotifier<FaseDeLaCapa> _fase = ValueNotifier<FaseDeLaCapa>(
    FaseDeLaCapa.inactiva,
  );
  final ValueNotifier<EscenaDelLogo?> _escena = ValueNotifier<EscenaDelLogo?>(
    null,
  );

  /// Cómo se ve la página de debajo. Solo la salida la mueve y la funde.
  final ValueNotifier<Offset> _corrimientoDeLaPagina = ValueNotifier<Offset>(
    Offset.zero,
  );
  final ValueNotifier<double> _opacidadDeLaPagina = ValueNotifier<double>(1);

  /// La opacidad de lo que la capa pinta, para los fundidos.
  final ValueNotifier<double> _opacidad = ValueNotifier<double>(1);

  VarianteDeIntro? _variante;
  Duration _ahora = Duration.zero;
  Duration? _inicioDeLaIntro;
  bool _preparada = false;
  Offset _centro = Offset.zero;
  Size _vista = Size.zero;
  final ValueNotifier<EscenaDeSalida?> _salida = ValueNotifier<EscenaDeSalida?>(
    null,
  );
  bool _sinMovimiento = false;

  /// Los ms de la intro en que terminó la carga, y la ruta que devolvió.
  double? _cargaLista;
  String? _destino;

  Duration _inicioDeFase = Duration.zero;
  int _cuadrosEsperando = 0;
  double _msInicioDeSalida = 0;
  DestinoDeLaSalida? _destinoDeLaSalida;
  double _duracionDelFundido = 300;

  bool get _haciaHome => _destino == '/home';

  double get _msDeFase => (_ahora - _inicioDeFase).inMicroseconds / 1000;

  /// Los ms de la intro, contados desde que la variante está elegida.
  double get _ms => _inicioDeLaIntro == null
      ? 0
      : (_ahora - _inicioDeLaIntro!).inMicroseconds / 1000;

  String get _etiqueta => etiquetaDeLaIntro;

  @override
  void initState() {
    super.initState();
    CapaDeArranque._estado = this;
    if (widget.intro != null) {
      _fase.value = FaseDeLaCapa.eligiendo;
      EstadoDeLaCapa.cubre.value = true;
      _reloj.start();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _medir();
    if (_preparada || widget.intro == null) return;
    _preparada = true;
    _sinMovimiento = MediaQuery.disableAnimationsOf(context);
    // El primer cuadro es el nativo, sin «++» y sin giro (RF-SPL-5).
    _escena.value = EscenaDelLogo.reposo(
      centro: _centro,
      radio: radioDelNativo,
      conCruces: false,
    );
    _empezarLaCarga();
    unawaited(_elegirVariante());
  }

  void _medir() {
    _vista = MediaQuery.sizeOf(context);
    final pantalla = View.of(context).display;
    _centro = centroDelNativo(
      _vista,
      pantalla.size / pantalla.devicePixelRatio,
    );
  }

  /// La carga corre en paralelo con la intro desde el montaje (RF-SPL-4).
  void _empezarLaCarga() {
    unawaited(widget.intro!.carga().then(_alCargar, onError: _alFallarLaCarga));
  }

  void _alCargar(String ruta) {
    if (!mounted) return;
    _destino = ruta;
    _cargaLista = _ms;
  }

  /// Antes de registrar los servicios no hay ruta segura y la intro sigue en
  /// su bucle, como hoy queda quieto el nativo. Después, la intro hace el
  /// relevo a la bienvenida sin borrar nada (RF-SPL-18).
  void _alFallarLaCarga(Object error, StackTrace pila) {
    debugPrint('Arranque. La carga falló con $error');
    if (error is FalloAntesDeLosServicios) return;
    _alCargar('/login');
  }

  Future<void> _elegirVariante() async {
    if (_sinMovimiento) {
      // Sin variante, y sin leer ni escribir la preferencia (RF-SPL-14).
      _inicioDeLaIntro = _ahora;
      _fase.value = FaseDeLaCapa.intro;
      return;
    }
    final intro = widget.intro!;
    final tipo = await intro.variantes.elegir(intro.random);
    if (!mounted || _fase.value != FaseDeLaCapa.eligiendo) return;
    _variante = varianteDe(tipo);
    _inicioDeLaIntro = _ahora;
    _fase.value = FaseDeLaCapa.intro;
  }

  void _alTic(Duration transcurrido) {
    _ahora = transcurrido;
    switch (_fase.value) {
      case FaseDeLaCapa.intro:
        _avanzarLaIntro();
      case FaseDeLaCapa.esperandoCabecera:
        _esperarLaCabecera();
      case FaseDeLaCapa.salida:
        _avanzarLaSalida();
      case FaseDeLaCapa.fundido:
        _avanzarElFundido();
      case FaseDeLaCapa.relevo:
        // Si la bienvenida no avisa en 500 ms, la capa se retira igual.
        if (_msDeFase > 500) _retirar();
      case FaseDeLaCapa.inactiva:
      case FaseDeLaCapa.eligiendo:
      case FaseDeLaCapa.pasoAlHorario:
        break;
    }
  }

  void _avanzarLaIntro() {
    final ms = _ms;
    if (_sinMovimiento) {
      // La estrella fija y los «++» con un fundido de 200 ms (RF-SPL-14).
      _escena.value = EscenaDelLogo(
        centro: _centro,
        radio: radioDelNativo,
        cruces: <CruzEnEscena>[
          for (final c in EscenaDelLogo.crucesEnReposo())
            c.copyWith(opacidad: (ms / 200).clamp(0.0, 1.0).toDouble()),
        ],
      );
      if (_destino != null && ms >= 200) _terminarLaIntro();
      return;
    }
    final v = _variante!;
    // Hacia /home el bucle sigue hasta que empieza la salida. Hacia la
    // bienvenida la variante vuelve al reposo desde la carga (S-34).
    _escena.value = v.escena(
      ms,
      centro: _centro,
      radio: radioDelNativo,
      cargaLista: _haciaHome ? null : _cargaLista,
    );
    if (_destino == null) return;
    final lista = _haciaHome
        ? ms >= v.finDeLaEntrada
        : ms >= v.finDelReposo(_cargaLista);
    if (lista) _terminarLaIntro();
  }

  void _terminarLaIntro() {
    if (_haciaHome) {
      PuntosDeAterrizaje.cabecera.value = null;
      if (!offAllSinTransicion('/home', arguments: abrirEnHorario)) {
        _retirar();
        return;
      }
      if (_sinMovimiento) {
        _empezarElFundido(250);
        return;
      }
      _cuadrosEsperando = 0;
      _fase.value = FaseDeLaCapa.esperandoCabecera;
      return;
    }
    // Sin sesión, o con la de un alumno sin especialidad, no hay salida y
    // la bienvenida toma el relevo con la pose (RF-SPL-12 y RF-SPL-21).
    unawaited(
      precacheImage(
        const AssetImage('assets/images/ulises_chatbot.png'),
        context,
      ).catchError((Object _) {}),
    );
    final pose = _escena.value!.pose;
    _inicioDeFase = _ahora;
    _fase.value = FaseDeLaCapa.relevo;
    if (!offAllToLogin(pose: pose, desdeLaIntro: true)) _retirar();
  }

  /// Espera el primer cuadro de /home y la medida de su cabecera, a lo sumo
  /// tres cuadros (decisión 5 del plan). La variante sigue su bucle.
  void _esperarLaCabecera() {
    _escena.value = _variante!.escena(
      _ms,
      centro: _centro,
      radio: radioDelNativo,
    );
    final medida = PuntosDeAterrizaje.cabecera.value;
    if (medida != null && Get.currentRoute == '/home') {
      _destinoDeLaSalida = DestinoDeLaSalida.desdeMedida(medida, _vista);
      _msInicioDeSalida = _ms;
      _inicioDeFase = _ahora;
      _fase.value = FaseDeLaCapa.salida;
      _avanzarLaSalida();
      return;
    }
    _cuadrosEsperando++;
    if (_cuadrosEsperando > 3) _empezarElFundido(300);
  }

  void _avanzarLaSalida() {
    final v = _variante!;
    if (Get.currentRoute != '/home') {
      // La ruta de debajo cambió, por ejemplo por un 401 (RF-SPL-4).
      _empezarElFundido(300);
      return;
    }
    final ms = _msDeFase;
    final s = salidaHaciaHome(
      variante: v,
      msInicio: _msInicioDeSalida,
      msEnSalida: ms,
      centroDelMarco: _centro,
      radioDelMarco: radioDelNativo,
      destino: _destinoDeLaSalida!,
    );
    _salida.value = s;
    _corrimientoDeLaPagina.value = Offset(0, s.paginaDy);
    _opacidadDeLaPagina.value = s.paginaOpacidad;
    if (ms >= v.duracionDeLaSalida) _retirar();
  }

  void _empezarElFundido(double duracion) {
    _duracionDelFundido = duracion;
    _inicioDeFase = _ahora;
    _corrimientoDeLaPagina.value = Offset.zero;
    _opacidadDeLaPagina.value = 1;
    _fase.value = FaseDeLaCapa.fundido;
  }

  void _avanzarElFundido() {
    final ms = _msDeFase;
    _opacidad.value = (1 - ms / _duracionDelFundido).clamp(0.0, 1.0).toDouble();
    if (ms >= _duracionDelFundido) _retirar();
  }

  void _alPintarLaBienvenida() {
    if (_fase.value == FaseDeLaCapa.relevo) _retirar();
  }

  /// La capa queda inactiva, sin pintar, sin bloquear toques y fuera de la
  /// semántica, pero montada (RF-SPL-4).
  void _retirar() {
    _reloj.stop();
    _salida.value = null;
    _opacidad.value = 1;
    _corrimientoDeLaPagina.value = Offset.zero;
    _opacidadDeLaPagina.value = 1;
    _fase.value = FaseDeLaCapa.inactiva;
    EstadoDeLaCapa.cubre.value = false;
  }

  @override
  void dispose() {
    _reloj.dispose();
    if (identical(CapaDeArranque._estado, this)) CapaDeArranque._estado = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<FaseDeLaCapa>(
      valueListenable: _fase,
      builder: (context, fase, _) {
        final activa = fase != FaseDeLaCapa.inactiva;
        // Siempre los mismos tres hijos, para que el Navigator no se vuelva a
        // montar cuando la capa cambia de fase.
        return Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: _fondoDeLaPagina(context, fase)),
            ExcludeSemantics(
              excluding: activa,
              child: AbsorbPointer(
                absorbing: activa,
                child: _PaginaDeDebajo(capa: this, child: widget.child),
              ),
            ),
            if (activa)
              AnnotatedRegion<SystemUiOverlayStyle>(
                value: SystemUiOverlayStyle.light,
                child: Semantics(
                  container: true,
                  label: _etiqueta,
                  excludeSemantics: true,
                  child: AbsorbPointer(
                    child: CustomPaint(
                      size: Size.infinite,
                      painter: _PintorDeLaCapa(this),
                    ),
                  ),
                ),
              )
            else
              const SizedBox.shrink(),
          ],
        );
      },
    );
  }

  /// Detrás de la página va el fondo del tema, así que la salida no deja ver
  /// un destello blanco ni negro (RF-SPL-11).
  Color _fondoDeLaPagina(BuildContext context, FaseDeLaCapa fase) =>
      fase == FaseDeLaCapa.salida || fase == FaseDeLaCapa.pasoAlHorario
      ? Theme.of(context).colorScheme.surface
      : const Color(0x00000000);
}

class _PaginaDeDebajo extends StatelessWidget {
  const _PaginaDeDebajo({required this.capa, required this.child});

  final _CapaDeArranqueState capa;
  final Widget child;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<Offset>(
    valueListenable: capa._corrimientoDeLaPagina,
    builder: (context, corrimiento, hijo) => Transform.translate(
      offset: corrimiento,
      child: ValueListenableBuilder<double>(
        valueListenable: capa._opacidadDeLaPagina,
        builder: (context, opacidad, hijo) =>
            Opacity(opacity: opacidad, child: hijo),
        child: hijo,
      ),
    ),
    child: child,
  );
}

class _PintorDeLaCapa extends CustomPainter {
  _PintorDeLaCapa(this.capa)
    : super(
        repaint: Listenable.merge(<Listenable>[
          capa._fase,
          capa._escena,
          capa._opacidad,
          capa._salida,
        ]),
      );

  final _CapaDeArranqueState capa;

  @override
  void paint(Canvas canvas, Size size) {
    final opacidad = capa._opacidad.value;
    if (opacidad <= 0) return;
    if (opacidad < 1) {
      canvas.saveLayer(
        null,
        Paint()..color = Color.fromRGBO(0, 0, 0, opacidad),
      );
    }
    final salida = capa._salida.value;
    final destino = capa._destinoDeLaSalida;
    if (salida != null && destino != null) {
      // La salida, o su fundido si la ruta cambió en medio.
      pintarSalida(canvas, salida, destino);
    } else {
      canvas.drawRect(Offset.zero & size, Paint()..color = naranjaDelSplash);
      final escena = capa._escena.value;
      if (escena != null) pintarEscena(canvas, escena);
    }
    if (opacidad < 1) canvas.restore();
  }

  @override
  bool shouldRepaint(_PintorDeLaCapa oldDelegate) => oldDelegate.capa != capa;
}
