// lib/pages/home/home_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/components/footer/app_footer.dart';
import 'package:ulima_plus/components/header/app_header.dart';
import 'package:ulima_plus/services/auth_service.dart';
import 'package:ulima_plus/components/chatbot_fab.dart';

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

  Widget _buildBody() {
    return _config.pages[_currentIndex];
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final u = user;
    return Scaffold(
      backgroundColor: colors.surface,
      floatingActionButton: u != null && !u.isTeacher ? const ChatbotFab() : null,
      body: Column(
        children: [
          AppHeader(showScheduleToggle: _currentIndex == 2),
          Expanded(child: _buildBody()),
        ],
      ),
      bottomNavigationBar: AppFooter(
        currentIndex: _currentIndex,
        items: _config.footerItems,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
