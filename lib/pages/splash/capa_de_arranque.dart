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

import '../../components/logo/escena_del_logo.dart';
import '../../components/logo/pintor_del_logo.dart';
import '../../services/splash_variante_service.dart';
import 'estado_de_la_capa.dart';
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

  /// La carga corre en paralelo con la intro desde el montaje. La Tarea 13
  /// le suma lo que pasa al terminar.
  void _empezarLaCarga() {
    unawaited(widget.intro!.carga().then((_) {}, onError: (Object _) {}));
  }

  Future<void> _elegirVariante() async {
    final intro = widget.intro!;
    final tipo = await intro.variantes.elegir(intro.random);
    if (!mounted || _fase.value != FaseDeLaCapa.eligiendo) return;
    _variante = varianteDe(tipo);
    _inicioDeLaIntro = _ahora;
    _fase.value = FaseDeLaCapa.intro;
  }

  void _alTic(Duration transcurrido) {
    _ahora = transcurrido;
    if (_fase.value == FaseDeLaCapa.intro) {
      _escena.value = _variante!.escena(
        _ms,
        centro: _centro,
        radio: radioDelNativo,
      );
    }
  }

  void _alPintarLaBienvenida() {}

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
        ]),
      );

  final _CapaDeArranqueState capa;

  @override
  void paint(Canvas canvas, Size size) {
    final opacidad = capa._opacidad.value;
    if (opacidad <= 0) return;
    final escena = capa._escena.value;
    if (opacidad < 1) {
      canvas.saveLayer(
        null,
        Paint()..color = Color.fromRGBO(0, 0, 0, opacidad),
      );
    }
    canvas.drawRect(Offset.zero & size, Paint()..color = naranjaDelSplash);
    if (escena != null) pintarEscena(canvas, escena);
    if (opacidad < 1) canvas.restore();
  }

  @override
  bool shouldRepaint(_PintorDeLaCapa oldDelegate) => oldDelegate.capa != capa;
}
