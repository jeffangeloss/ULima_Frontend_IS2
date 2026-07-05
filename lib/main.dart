// TERMINAL - flutter pub get

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '/configs/themes.dart';
import '/services/auth_service.dart';
import '/services/alert_service.dart';
import '/services/courses_service.dart';
import 'services/evaluations_service.dart';
import '/services/malla_service.dart';
import '/services/storage_service.dart';
import 'pages/home/home_page.dart';
import 'pages/login/login_page.dart';
import 'pages/malla/malla_controller.dart';
import 'pages/malla/malla_list_controller.dart';
import 'pages/malla/malla_page.dart';
import 'pages/login/login_controller.dart';
import 'pages/password_reset/forgot_password_controller.dart';
import 'pages/password_reset/reset_password_controller.dart';
import 'pages/password_reset/forgot_password_page.dart';
import 'pages/password_reset/reset_password_page.dart';
import 'pages/setup_carrera/setup_carrera_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LucideIcons.info.codePoint;

  // Servicios globales permanentes.
  await Get.putAsync<StorageService>(
    () => StorageService().init(),
    permanent: true,
  );
  Get.put<AuthService>(AuthService(), permanent: true);
  Get.put<AlertService>(AlertService(), permanent: true);
  Get.put<MallaService>(MallaService(), permanent: true);


  await Future.wait([
    EvaluationSyllabusService().loadEvaluationData(),
    CoursesService().loadCoursesData(),
  ]);

  // Intentar restaurar sesión guardada.
  final restored = await AuthService.to.tryRestoreSession();
  String initialRoute;
  if (restored) {
    final user = AuthService.to.currentUser!;
    initialRoute = user.setupComplete ? '/home' : '/setup-carrera';
    try {
      await AlertService.to.fetchAlerts();
    } catch (e) {
      print('Error loading alerts at startup: $e');
    }
  } else {
    initialRoute = '/login';
  }

  runApp(MyApp(initialRoute: initialRoute));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.initialRoute});
  final String initialRoute;

  @override
  Widget build(BuildContext context) {
    final materialTheme = MaterialTheme(Theme.of(context).textTheme);
    return GetMaterialApp(
      title: 'ULIMA++',
      theme: materialTheme.light(),
      darkTheme: materialTheme.dark(),
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      initialRoute: initialRoute,
      getPages: [
        // Bindings por ruta: asocian cada controller a SU ruta de forma
        // explícita. Sin esto, Get.put dentro del build podía asociarlo al
        // overlay del snackbar activo durante la transición, y al descartarse
        // el snackbar GetX eliminaba el controller de la página visible
        // (crash "TextEditingController was used after being disposed").
        GetPage(
          name: '/login',
          page: () => const LoginPage(),
          binding: BindingsBuilder(() {
            Get.lazyPut(() => LoginController());
          }),
        ),
        GetPage(
          name: '/forgot-password',
          page: () => const ForgotPasswordPage(),
          binding: BindingsBuilder(() {
            Get.lazyPut(() => ForgotPasswordController());
          }),
        ),
        GetPage(
          name: '/reset-password',
          page: () => const ResetPasswordPage(),
          binding: BindingsBuilder(() {
            Get.lazyPut(() => ResetPasswordController());
          }),
        ),
        GetPage(name: '/setup-carrera', page: () => const SetupCarreraPage()),
        GetPage(
          name: '/home',
          page: () => const HomePage(),
          // HU19: el controller de la tab Malla se asocia a la RUTA (no a un
          // Get.put dentro del build de la tab) para que sobreviva al cambio
          // de pestañas y se elimine al salir de /home (logout).
          binding: BindingsBuilder(() {
            Get.lazyPut(() => MallaListController());
          }),
        ),
        // TT07 (#103): la malla clásica vuelve como "Vista mapa (clásica)" de
        // SOLO LECTURA. El binding re-ejecuta lazyPut en cada entrada a la
        // ruta y GetX elimina el controller al salir, así que la vista se
        // hidrata fresca siempre (sin estado stale) y sin Get.put en builds.
        GetPage(
          name: '/malla-clasica',
          page: () => const MallaPage(),
          binding: BindingsBuilder(() {
            Get.lazyPut(() => MallaController());
          }),
        ),
      ],
    );
  }
}
