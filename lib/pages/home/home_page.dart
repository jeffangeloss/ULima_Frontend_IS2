// lib/pages/home/home_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/components/footer/app_footer.dart';
import 'package:ulima_plus/components/header/app_header.dart';
import 'package:ulima_plus/services/auth_service.dart';
import 'package:ulima_plus/components/chatbot_bubble.dart';

import '../horario/horario_controller.dart';
import 'home_controller.dart';
import 'home_shell_config.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final HomeController control = Get.put(HomeController());
  final user = AuthService.to.currentUser;

  int _currentIndex = 0;

  late final HomeShellConfig _config = HomeShellConfig.forUser(user);

  /// Índice del tab de Horario según el rol del usuario.
  int get _horarioTabIndex => (user?.isTeacher ?? false) ? 2 : 2;

  Widget _buildBody() {
    return _config.pages[_currentIndex];
  }

  void _onTabTap(int index) {
    final previous = _currentIndex;
    setState(() {
      _currentIndex = index;
    });
    // Si el usuario cambia al tab de Horario, recargamos los datos
    // para reflejar asesorías creadas o modificadas recientemente.
    // Para docentes: también recargamos si venían del tab de Asesorías (índice 3).
    final isTeacher = user?.isTeacher ?? false;
    final comingFromAsesorias = isTeacher && previous == 3;
    if (index == _horarioTabIndex || comingFromAsesorias) {
      try {
        Get.find<HorarioController>().reload();
      } catch (_) {
        // El controller aún no existe (primera visita): onInit lo cargará.
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final u = user;
    final showBubble = u != null && !u.isTeacher;
    return Scaffold(
      backgroundColor: colors.surface,
      body: Column(
        children: [
          AppHeader(showScheduleToggle: _currentIndex == _horarioTabIndex),
          Expanded(
            // La burbuja del chatbot va en un Stack sobre el body (no en el slot
            // fijo del FAB) para poder arrastrarla; las zonas vacías del Stack
            // dejan pasar los toques al contenido de abajo.
            child: Stack(
              children: [
                _buildBody(),
                if (showBubble) const ChatbotBubble(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: AppFooter(
        currentIndex: _currentIndex,
        items: _config.footerItems,
        onTap: _onTabTap,
      ),
    );
  }
}

