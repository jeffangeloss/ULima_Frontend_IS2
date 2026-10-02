// test/aviso_version/aviso_version_arranque_test.dart
//
// WIDGET · Aviso de versión nueva (specs/features/aviso-version/aviso-version.spec.md).
// RF-AVV-1 fija que la consulta corre una sola vez por arranque, después de que
// la capa del arranque termina, en segundo plano, solo en Android y solo si la
// build trae APP_VERSION. RF-AVV-6 fija que ninguna falla se ve en pantalla.
// Archivos probados lib/pages/splash/aviso_version_arranque.dart y la llamada
// de lib/main.dart.

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ulima_plus/pages/splash/aviso_version_arranque.dart';
import 'package:ulima_plus/pages/splash/capa_de_arranque.dart';
import 'package:ulima_plus/services/aviso_version_service.dart';
import 'package:ulima_plus/services/splash_variante_service.dart';

import '../splash/apoyo_splash.dart';

String _apk(String version) =>
    'https://github.com/meltiruiz/ULima_Frontend_IS2/releases/download/'
    'v$version/ULimaPlus-build-78.apk';

/// Un servidor de version.json que cuenta las peticiones que recibe.
class _Servidor {
  _Servidor({this.version = '1.2.0', this.estado = 200});

  final String version;
  final int estado;
  int peticiones = 0;

  late final MockClient cliente = MockClient((_) async {
    peticiones++;
    return http.Response(
      jsonEncode(<String, Object>{
        'version': version,
        'build': 78,
        'url': _apk(version),
      }),
      estado,
    );
  });
}

/// El enganche con el servicio sobre el [servidor], sin red.
AvisoVersionArranque _enganche(
  _Servidor servidor, {
  ValueListenable<bool>? capa,
  GlobalKey<NavigatorState>? navegador,
  BuildContext? Function()? contexto,
  String instalada = '1.1.0',
  bool? esAndroid = true,
  Future<bool> Function(Uri url)? abrir,
}) => AvisoVersionArranque(
  servicio: AvisoVersionService(
    cliente: servidor.cliente,
    versionInstalada: instalada,
  ),
  esAndroid: esAndroid,
  capaCubre: capa,
  contexto:
      contexto ?? (navegador == null ? null : () => navegador.currentContext),
  abrir: abrir,
);

/// Una pantalla vacía con un navegador que el enganche puede usar.
Future<GlobalKey<NavigatorState>> _montar(WidgetTester tester) async {
  final navegador = GlobalKey<NavigatorState>();
  await tester.pumpWidget(
    MaterialApp(
      navigatorKey: navegador,
      home: const Scaffold(body: Text('pantalla')),
    ),
  );
  return navegador;
}

/// La capa cubre la pantalla y se retira, como la intro.
Future<void> _cubrirYRetirar(
  WidgetTester tester,
  ValueNotifier<bool> capa,
) async {
  capa.value = true;
  await tester.pumpAndSettle();
  capa.value = false;
  await tester.pumpAndSettle();
}

Finder get _aviso => find.text('Hay una versión nueva');

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  group('cuándo consulta (RF-AVV-1)', () {
    testWidgets('con la versión instalada vacía no pide nada ni muestra nada', (
      tester,
    ) async {
      final servidor = _Servidor();
      final capa = ValueNotifier<bool>(false);
      final navegador = await _montar(tester);
      _enganche(
        servidor,
        capa: capa,
        navegador: navegador,
        instalada: '',
      ).programar();
      await _cubrirYRetirar(tester, capa);
      expect(servidor.peticiones, 0);
      expect(_aviso, findsNothing);
    });

    testWidgets('no consulta mientras la capa cubre la pantalla, y consulta '
        'cuando se retira', (tester) async {
      final servidor = _Servidor();
      final capa = ValueNotifier<bool>(false);
      final navegador = await _montar(tester);
      _enganche(servidor, capa: capa, navegador: navegador).programar();

      capa.value = true;
      await tester.pumpAndSettle();
      expect(servidor.peticiones, 0);
      expect(_aviso, findsNothing);

      capa.value = false;
      await tester.pumpAndSettle();
      expect(servidor.peticiones, 1);
      expect(_aviso, findsOneWidget);
    });

    testWidgets('si la capa ya cubría al programarlo, espera igual a que se '
        'retire', (tester) async {
      final servidor = _Servidor();
      final capa = ValueNotifier<bool>(true);
      final navegador = await _montar(tester);
      _enganche(servidor, capa: capa, navegador: navegador).programar();
      await tester.pumpAndSettle();
      expect(servidor.peticiones, 0);
      capa.value = false;
      await tester.pumpAndSettle();
      expect(servidor.peticiones, 1);
    });

    testWidgets('consulta una sola vez por arranque, aunque la capa vuelva a '
        'cubrir y a retirarse', (tester) async {
      final servidor = _Servidor();
      final capa = ValueNotifier<bool>(false);
      final navegador = await _montar(tester);
      final enganche = _enganche(servidor, capa: capa, navegador: navegador)
        ..programar()
        ..programar();
      await _cubrirYRetirar(tester, capa);
      expect(servidor.peticiones, 1);
      // La persona elige «Más tarde», y la capa vuelve a cubrir, como en el
      // paso al horario de la bienvenida.
      await tester.tap(find.text('Más tarde'));
      await tester.pumpAndSettle();
      await _cubrirYRetirar(tester, capa);
      enganche.programar();
      await _cubrirYRetirar(tester, capa);
      expect(servidor.peticiones, 1);
      expect(_aviso, findsNothing);
    });

    testWidgets(
      'fuera de Android no pide nada',
      variant: TargetPlatformVariant.all(excluding: {TargetPlatform.android}),
      (tester) async {
        final servidor = _Servidor();
        final capa = ValueNotifier<bool>(false);
        final navegador = await _montar(tester);
        _enganche(
          servidor,
          capa: capa,
          navegador: navegador,
          esAndroid: null,
        ).programar();
        await _cubrirYRetirar(tester, capa);
        expect(servidor.peticiones, 0);
        expect(_aviso, findsNothing);
      },
    );

    testWidgets(
      'en Android consulta',
      variant: TargetPlatformVariant.only(TargetPlatform.android),
      (tester) async {
        final servidor = _Servidor();
        final capa = ValueNotifier<bool>(false);
        final navegador = await _montar(tester);
        _enganche(
          servidor,
          capa: capa,
          navegador: navegador,
          esAndroid: null,
        ).programar();
        await _cubrirYRetirar(tester, capa);
        expect(servidor.peticiones, 1);
        expect(_aviso, findsOneWidget);
      },
    );
  });

  group('lo que muestra (RF-AVV-3, RF-AVV-4 y RF-AVV-5)', () {
    testWidgets('el diálogo lleva la versión publicada y la instalada', (
      tester,
    ) async {
      final capa = ValueNotifier<bool>(false);
      final navegador = await _montar(tester);
      _enganche(_Servidor(), capa: capa, navegador: navegador).programar();
      await _cubrirYRetirar(tester, capa);
      expect(
        find.text('ULima++ 1.2.0 ya está disponible. Tienes la 1.1.0.'),
        findsOneWidget,
      );
    });

    testWidgets('«Más tarde» guarda la versión y el siguiente arranque ya no '
        'avisa de ella', (tester) async {
      final capa = ValueNotifier<bool>(false);
      final navegador = await _montar(tester);
      _enganche(_Servidor(), capa: capa, navegador: navegador).programar();
      await _cubrirYRetirar(tester, capa);
      await tester.tap(find.text('Más tarde'));
      await tester.pumpAndSettle();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('aviso_version_pospuesta'), '1.2.0');

      // El arranque siguiente, con la misma versión publicada.
      final otraCapa = ValueNotifier<bool>(false);
      final otro = _Servidor();
      _enganche(otro, capa: otraCapa, navegador: navegador).programar();
      await _cubrirYRetirar(tester, otraCapa);
      expect(otro.peticiones, 1);
      expect(_aviso, findsNothing);
    });

    testWidgets('«Descargar» abre la URL del APK y no guarda nada, así que el '
        'aviso reaparece en el siguiente arranque', (tester) async {
      final abiertas = <Uri>[];
      final capa = ValueNotifier<bool>(false);
      final navegador = await _montar(tester);
      _enganche(
        _Servidor(),
        capa: capa,
        navegador: navegador,
        abrir: (url) async {
          abiertas.add(url);
          return true;
        },
      ).programar();
      await _cubrirYRetirar(tester, capa);
      await tester.tap(find.text('Descargar'));
      await tester.pumpAndSettle();
      expect(abiertas, <Uri>[Uri.parse(_apk('1.2.0'))]);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('aviso_version_pospuesta'), isNull);

      final otraCapa = ValueNotifier<bool>(false);
      _enganche(_Servidor(), capa: otraCapa, navegador: navegador).programar();
      await _cubrirYRetirar(tester, otraCapa);
      expect(_aviso, findsOneWidget);
    });

    testWidgets('una versión publicada igual a la instalada no muestra nada', (
      tester,
    ) async {
      final capa = ValueNotifier<bool>(false);
      final navegador = await _montar(tester);
      _enganche(
        _Servidor(version: '1.1.0'),
        capa: capa,
        navegador: navegador,
      ).programar();
      await _cubrirYRetirar(tester, capa);
      expect(_aviso, findsNothing);
    });
  });

  group('las fallas no se ven (RF-AVV-6)', () {
    testWidgets('una respuesta que no es 200 no muestra nada', (tester) async {
      final servidor = _Servidor(estado: 500);
      final capa = ValueNotifier<bool>(false);
      final navegador = await _montar(tester);
      _enganche(servidor, capa: capa, navegador: navegador).programar();
      await _cubrirYRetirar(tester, capa);
      expect(servidor.peticiones, 1);
      expect(_aviso, findsNothing);
    });

    testWidgets('sin contexto, no muestra nada', (tester) async {
      final servidor = _Servidor();
      final capa = ValueNotifier<bool>(false);
      await _montar(tester);
      _enganche(servidor, capa: capa, contexto: () => null).programar();
      await _cubrirYRetirar(tester, capa);
      expect(servidor.peticiones, 1);
      expect(_aviso, findsNothing);
    });

    testWidgets('con un contexto que ya no está montado, no muestra nada', (
      tester,
    ) async {
      final servidor = _Servidor();
      final capa = ValueNotifier<bool>(false);
      await _montar(tester);
      final viejo = tester.element(find.byType(Scaffold));
      await tester.pumpWidget(const SizedBox.shrink());
      expect(viejo.mounted, isFalse);
      _enganche(servidor, capa: capa, contexto: () => viejo).programar();
      await _cubrirYRetirar(tester, capa);
      expect(servidor.peticiones, 1);
      expect(_aviso, findsNothing);
    });

    testWidgets('si el diálogo no se puede abrir, el error no sale', (
      tester,
    ) async {
      final servidor = _Servidor();
      final capa = ValueNotifier<bool>(false);
      // Un contexto sin Navigator: showDialog lanza.
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox.shrink(),
        ),
      );
      final sinNavegador = tester.element(find.byType(SizedBox));
      _enganche(servidor, capa: capa, contexto: () => sinNavegador).programar();
      await _cubrirYRetirar(tester, capa);
      expect(servidor.peticiones, 1);
      expect(_aviso, findsNothing);
    });
  });

  group('con la capa real del arranque (RF-AVV-1)', () {
    setUp(reiniciarArranque);
    tearDown(reiniciarArranque);

    IntroDelArranque intro(CargaFalsa carga) => IntroDelArranque(
      carga: carga.call,
      variantes: VariantesFijas(VarianteSplash.ensamble),
      random: Random(1),
    );

    testWidgets('la consulta empieza cuando la intro termina y no antes, y el '
        'aviso sale sobre /home', (tester) async {
      telefono(tester);
      final servidor = _Servidor();
      final carga = CargaFalsa();
      // Como main(): se programa justo después de runApp y antes del primer
      // cuadro, y usa la señal de la capa y el contexto de Get.
      _enganche(servidor, esAndroid: true).programar();
      await tester.pumpWidget(
        appConCapa(intro: intro(carga), home: (_) => const HomeDePrueba()),
      );
      await avanzar(tester, 800);
      expect(CapaDeArranque.fase, isNot(FaseDeLaCapa.inactiva));
      expect(servidor.peticiones, 0, reason: 'la intro todavía corre');

      carga.terminar('/home');
      await avanzarHasta(
        tester,
        () => CapaDeArranque.fase == FaseDeLaCapa.inactiva,
      );
      await tester.pumpAndSettle();
      expect(servidor.peticiones, 1);
      expect(_aviso, findsOneWidget);
      expect(find.text('home'), findsOneWidget);
    });

    testWidgets('también cuando la intro termina en la bienvenida', (
      tester,
    ) async {
      telefono(tester);
      final servidor = _Servidor();
      final carga = CargaFalsa();
      _enganche(servidor, esAndroid: true).programar();
      await tester.pumpWidget(appConCapa(intro: intro(carga)));
      await avanzar(tester, 800);
      expect(servidor.peticiones, 0);

      carga.terminar('/login');
      await avanzarHasta(
        tester,
        () => CapaDeArranque.fase == FaseDeLaCapa.inactiva,
      );
      await tester.pumpAndSettle();
      expect(servidor.peticiones, 1);
      expect(_aviso, findsOneWidget);
      expect(find.text('bienvenida'), findsOneWidget);
    });

    testWidgets('con la versión instalada vacía, la intro corre sin que nada '
        'pida version.json', (tester) async {
      telefono(tester);
      final servidor = _Servidor();
      final carga = CargaFalsa();
      _enganche(servidor, instalada: '', esAndroid: true).programar();
      await tester.pumpWidget(
        appConCapa(intro: intro(carga), home: (_) => const HomeDePrueba()),
      );
      carga.terminar('/home');
      await avanzarHasta(
        tester,
        () => CapaDeArranque.fase == FaseDeLaCapa.inactiva,
      );
      await tester.pumpAndSettle();
      expect(servidor.peticiones, 0);
      expect(_aviso, findsNothing);
      expect(find.text('home'), findsOneWidget);
    });
  });

  group('la llamada de main.dart', () {
    test('se crea una sola vez, solo en la rama móvil y después de runApp', () {
      final fuente = File('lib/main.dart').readAsStringSync();
      final web = fuente.indexOf('if (kIsWeb) {');
      final finDeWeb = fuente.indexOf('return;', web);
      final runAppMovil = fuente.indexOf('runApp(', finDeWeb);
      final llamada = fuente.indexOf('AvisoVersionArranque().programar();');
      expect(web, isNonNegative, reason: 'la rama de web');
      expect(finDeWeb, greaterThan(web));
      expect(runAppMovil, greaterThan(finDeWeb), reason: 'el runApp móvil');
      expect(
        llamada,
        greaterThan(runAppMovil),
        reason: 'va después del runApp de la rama móvil',
      );
      expect('AvisoVersionArranque('.allMatches(fuente), hasLength(1));
    });
  });
}
