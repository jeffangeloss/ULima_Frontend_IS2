import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/components/header/app_header.dart';
import 'package:ulima_plus/models/user_model.dart';
import 'package:ulima_plus/services/auth_service.dart';

class _FakeAuthService extends AuthService {
  @override
  UserModel? get currentUser => UserModel(
    code: 'docente.test',
    firstName: 'Docente',
    lastName: 'De Prueba',
    email: 'docente.test@ulima.edu.pe',
    role: 'teacher',
    currentCycle: '2026-1',
    setupComplete: true,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.reset();
    Get.put<AuthService>(_FakeAuthService());
  });

  tearDown(Get.reset);

  testWidgets(
    'al pulsar ULIMA++ solicita abrir la promoción exacta fuera de la app',
    (tester) async {
      Uri? launchedUri;
      var launchCalls = 0;

      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: AppHeader(
              linkLauncher: (uri) async {
                launchCalls++;
                launchedUri = uri;
                return true;
              },
            ),
          ),
        ),
      );

      // El test pulsa el mismo texto que ve el usuario; el launcher inyectado
      // captura la URI y evita abrir un navegador real durante la prueba.
      await tester.tap(find.text('ULIMA++'));
      await tester.pump();

      expect(launchCalls, 1);
      expect(
        launchedUri.toString(),
        'https://www.donbelisario.com.pe/clasico-combo-contundente?'
        'gsImpressionId=01KXPTTES6C5C0S9FKJG902C2G&'
        'gsListName=Recomendaciones%20-%20Promociones&gsIndex=3',
      );
      expect(
        find.bySemanticsLabel('Abrir promoción de Don Belisario'),
        findsOneWidget,
      );
    },
  );
}
