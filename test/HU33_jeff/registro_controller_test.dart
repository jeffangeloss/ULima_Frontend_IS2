import 'package:flutter_test/flutter_test.dart';
import 'package:ulima_plus/models/portal_sync_models.dart';
import 'package:ulima_plus/models/registro_models.dart';
import 'package:ulima_plus/models/user_model.dart';
import 'package:ulima_plus/pages/registro/registro_controller.dart';
import 'package:ulima_plus/services/registro_service.dart';

/// Máquina de estados del registro (HU33).
///
/// El controller se construye DIRECTO, sin Get.put(): así GetX no dispara
/// onInit() y no hay red. Es el estilo mayoritario del repo para lógica de
/// controller.

class _ServicioFalso implements RegistroService {
  _ServicioFalso({this.resultado, this.fallo});

  final RegistroResult? resultado;
  final RegistroFailure? fallo;
  int llamadas = 0;
  String? codigoRecibido;

  @override
  Future<RegistroResult> registrar({
    required String code,
    required String portalPassword,
    required String passcode,
    required String password,
  }) async {
    llamadas++;
    codigoRecibido = code;
    if (fallo != null) throw fallo!;
    // Un `resultado` nulo revienta acá a propósito: es como el caso 10 fabrica
    // una excepción que NO es RegistroFailure.
    return resultado!;
  }
}

UserModel _usuario() => UserModel.fromJson({
      'id': 1,
      'studentId': 1,
      'code': '20230001',
      'fullName': 'GARCIA LOPEZ MARIA',
      'institutionalEmail': '20230001@aloe.ulima.edu.pe',
      'role': 'student',
      'career_id': 1,
      'setupComplete': false,
    });

PortalSyncSummary _summary() => const PortalSyncSummary(
      coursesCreated: 0,
      sectionsCreated: 0,
      sectionsUpdated: 0,
      sessionsUpserted: 12,
      enrollmentsUpserted: 5,
      enrollmentsWithdrawn: 0,
      progressUpserted: 40,
      syllabiUpserted: 0,
    );

RegistroResult _resultado({String token = 'jwt'}) => RegistroResult(
      token: token,
      user: _usuario(),
      summary: _summary(),
      warnings: const [],
    );

/// Controller con las tres costuras controladas.
RegistroController _controller({
  RegistroService? servicio,
  AdoptarSesionFn? adoptar,
  IniciarSesionFn? login,
}) {
  final c = RegistroController(
    service: servicio ?? _ServicioFalso(resultado: _resultado()),
    adoptarSesion: adoptar ?? ({required token, required user}) async {},
    iniciarSesion: login ?? ({required code, required password}) async => null,
  );
  c.codigoCtrl.text = '20230001';
  c.passwordCtrl.text = 'micontrasena';
  c.confirmacionCtrl.text = 'micontrasena';
  c.portalPasswordCtrl.text = 'clave-portal';
  c.passcodeCtrl.text = '123456';
  return c;
}

void main() {
  group('UNITARIA · validadores del registro (HU33)', () {
    test('caso 1: el código acepta de 6 a 10 dígitos, ni más ni menos', () {
      expect(validarCodigo('20230001'), isNull);
      expect(validarCodigo('123456'), isNull);
      expect(validarCodigo('1234567890'), isNull);
      expect(validarCodigo('12345'), isNotNull);
      expect(validarCodigo('12345678901'), isNotNull);
      expect(validarCodigo('2023000a'), isNotNull);
      expect(validarCodigo(''), isNotNull);
    });

    test('caso 2: el código con espacios alrededor es válido: se recorta', () {
      // El limitador de tasa del backend recorta para su clave pero el esquema
      // no, así que enviarlo sin recortar gastaría cupo y devolvería 400.
      expect(validarCodigo('  20230001  '), isNull);
    });

    test('caso 3: la contraseña de ULima++ exige 8 y su confirmación coincide', () {
      expect(validarPasoDatos(codigo: '20230001', password: 'corta', confirmacion: 'corta'), isNotNull);
      expect(validarPasoDatos(codigo: '20230001', password: 'micontrasena', confirmacion: 'otra'), isNotNull);
      expect(validarPasoDatos(codigo: '20230001', password: 'micontrasena', confirmacion: 'micontrasena'), isNull);
    });

    test('caso 4: el authenticator acepta de 6 a 8 dígitos', () {
      // SecurID entrega 6 de tokencode y 8 cuando el PIN va delante, y el campo
      // no recorta: exigir exactamente 6 rechazaría un passcode legítimo.
      expect(validarPasoVerificar(portalPassword: 'x', passcode: '123456'), isNull);
      expect(validarPasoVerificar(portalPassword: 'x', passcode: '12345678'), isNull);
      expect(validarPasoVerificar(portalPassword: 'x', passcode: '12345'), isNotNull);
      expect(validarPasoVerificar(portalPassword: 'x', passcode: '123456789'), isNotNull);
      expect(validarPasoVerificar(portalPassword: '', passcode: '123456'), isNotNull);
    });
  });

  group('UNITARIA · RegistroController transiciones (HU33)', () {
    test('caso 1: arranca en datos y continuar no toca la red', () async {
      final servicio = _ServicioFalso(resultado: _resultado());
      final c = _controller(servicio: servicio);
      expect(c.paso.value, equals(RegistroPaso.datos));

      c.continuar();
      expect(c.paso.value, equals(RegistroPaso.verificar));
      expect(servicio.llamadas, equals(0),
          reason: 'el paso 1 no consulta al backend: sería un oráculo de enumeración');
    });

    test('caso 2: continuar con datos inválidos se queda en datos', () {
      final c = _controller()..passwordCtrl.text = 'corta';
      c.continuar();
      expect(c.paso.value, equals(RegistroPaso.datos));
      expect(c.errorMessage.value, isNotNull);
    });

    test('caso 3: un registro exitoso deja la sesión puesta y pasa a listo', () async {
      var adoptado = false;
      final c = _controller(adoptar: ({required token, required user}) async {
        adoptado = true;
        expect(token, equals('jwt'));
        expect(user.code, equals('20230001'));
      });
      c.continuar();
      await c.enviar();

      expect(c.paso.value, equals(RegistroPaso.listo));
      expect(adoptado, isTrue);
      expect(c.resultado.value, isNotNull);
    });

    test('caso 4: el código se envía recortado', () async {
      final servicio = _ServicioFalso(resultado: _resultado());
      final c = _controller(servicio: servicio)..codigoCtrl.text = '  20230001 ';
      c.continuar();
      await c.enviar();
      expect(servicio.codigoRecibido, equals('20230001'));
    });

    test('caso 5: tras el éxito las credenciales del portal quedan vacías', () async {
      final c = _controller();
      c.continuar();
      await c.enviar();
      expect(c.portalPasswordCtrl.text, isEmpty);
      expect(c.passcodeCtrl.text, isEmpty);
    });

    test('caso 6: un fallo del portal vuelve a verificar, borra el passcode y conserva la contraseña', () async {
      final c = _controller(
        servicio: _ServicioFalso(
          fallo: const RegistroFailure('miUlima rechazó los datos.', code: 'PORTAL_AUTH_FAILED'),
        ),
      );
      c.continuar();
      await c.enviar();

      expect(c.paso.value, equals(RegistroPaso.verificar));
      expect(c.passcodeCtrl.text, isEmpty, reason: 'lo que casi siempre venció es el código');
      expect(c.portalPasswordCtrl.text, equals('clave-portal'),
          reason: 'reescribirla alarga el reintento hasta que el código nuevo también vence');
      expect(c.errorMessage.value, contains('miUlima'));
    });

    test('caso 7: un 409 vuelve a datos, que es donde está el código', () async {
      final c = _controller(
        servicio: _ServicioFalso(
          fallo: const RegistroFailure('Ya existe una cuenta.', code: 'USER_ALREADY_EXISTS'),
        ),
      );
      c.continuar();
      await c.enviar();
      expect(c.paso.value, equals(RegistroPaso.datos));
    });

    test('caso 8: el plazo vencido va a incierto, no a un fallo', () async {
      final c = _controller(
        servicio: _ServicioFalso(
          fallo: const RegistroFailure('No pudimos confirmar…', code: 'TIEMPO_AGOTADO'),
        ),
      );
      c.continuar();
      await c.enviar();
      expect(c.paso.value, equals(RegistroPaso.incierto));
    });

    test('caso 9: si adoptar la sesión falla, la cuenta existe: incierto, no fallo', () async {
      final c = _controller(
        adoptar: ({required token, required user}) async => throw Exception('keychain'),
      );
      c.continuar();
      await c.enviar();
      expect(c.paso.value, equals(RegistroPaso.incierto));
    });

    test('caso 10: una excepción inesperada no deja la pantalla colgada en enviando', () async {
      final c = _controller(servicio: _ServicioFalso(resultado: null));
      c.continuar();
      await c.enviar();
      expect(c.paso.value, isNot(equals(RegistroPaso.enviando)),
          reason: 'portal-sync tiene ese agujero; acá no se repite');
      expect(c.errorMessage.value, isNotNull);
    });

    test('caso 11: la contraseña de miUlima no llega a ningún estado observable', () async {
      // RS-FE-6. Es la comprobación que sí muerde: `onClose` también borra los
      // campos, pero eso no se puede afirmar después de `dispose()` sin
      // depender de si el SDK lanza al leer un controller liberado.
      final c = _controller(
        servicio: _ServicioFalso(
          fallo: const RegistroFailure('miUlima rechazó los datos.', code: 'PORTAL_AUTH_FAILED'),
        ),
      );
      c.continuar();
      await c.enviar();

      expect(c.errorMessage.value ?? '', isNot(contains('clave-portal')));
      expect(c.resultado.value?.toString() ?? '', isNot(contains('clave-portal')));
      expect(c.paso.value.toString(), isNot(contains('clave-portal')));
    });
  });

  group('UNITARIA · RegistroController salidas de incierto (HU33)', () {
    Future<RegistroController> enIncierto({IniciarSesionFn? login}) async {
      final c = _controller(
        servicio: _ServicioFalso(
          fallo: const RegistroFailure('No pudimos confirmar…', code: 'TIEMPO_AGOTADO'),
        ),
        login: login,
      );
      c.continuar();
      await c.enviar();
      expect(c.paso.value, equals(RegistroPaso.incierto));
      return c;
    }

    test('caso 1: si el login de rescate entra, la cuenta existía', () async {
      final c = await enIncierto(login: ({required code, required password}) async => null);
      expect(await c.intentarIniciarSesion(), isTrue);
    });

    test('caso 2: el login usa el código y la contraseña que se eligieron', () async {
      String? codigoUsado;
      String? claveUsada;
      final c = await enIncierto(login: ({required code, required password}) async {
        codigoUsado = code;
        claveUsada = password;
        return null;
      });
      await c.intentarIniciarSesion();
      expect(codigoUsado, equals('20230001'));
      expect(claveUsada, equals('micontrasena'));
    });

    test('caso 3: si el login falla NO se concluye que la cuenta no existe', () async {
      final c = await enIncierto(
        login: ({required code, required password}) async => 'Código o contraseña incorrectos.',
      );
      expect(await c.intentarIniciarSesion(), isFalse);
      expect(c.paso.value, equals(RegistroPaso.incierto), reason: 'sigue siendo incierto');
      // Puede existir bajo el código que devolvió el portal, que gana sobre el
      // tecleado: el mensaje tiene que dar el siguiente paso, no un veredicto.
      expect(c.errorMessage.value, contains('ya existe'));
    });

    test('caso 4: volver a intentar regresa a verificar con el passcode limpio', () async {
      final c = await enIncierto();
      c.passcodeCtrl.text = '999999';
      c.volverAVerificar();
      expect(c.paso.value, equals(RegistroPaso.verificar));
      expect(c.passcodeCtrl.text, isEmpty);
    });
  });
}
