// lib/components/app_footer.dart

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ulima_plus/configs/themes.dart';
import 'package:ulima_plus/services/auth_service.dart';

class AppFooter extends StatelessWidget {
  final int currentIndex;
  final Function(int)? onTap;

  const AppFooter({super.key, required this.currentIndex, this.onTap});

  @override
  Widget build(BuildContext context) {
    final user = AuthService.to.currentUser;

    return BottomNavigationBar(
      currentIndex: currentIndex,
      backgroundColor: const Color(0xFF1E1E24),
      elevation: 12,

      onTap: (index) {
        if (onTap != null) {
          onTap!(index);
        }
      },

      selectedItemColor: MaterialTheme.primaryColor,
      unselectedItemColor: Colors.white.withValues(alpha: 0.68),

      type: BottomNavigationBarType.fixed,

      items: [
        const BottomNavigationBarItem(
          icon: Icon(LucideIcons.network),
          label: 'Malla',
        ),

        const BottomNavigationBarItem(
          icon: Icon(LucideIcons.calculator),
          label: 'Notas',
        ),

        const BottomNavigationBarItem(
          icon: Icon(LucideIcons.calendar),

          label: 'Horario',
        ),

        // MODULO EXTRA A LOS ALUMNOS CON ROL 'Delegado'
        if (user?.isDelegate ?? false)
          const BottomNavigationBarItem(
            icon: Icon(LucideIcons.shield),
            label: 'Delegado',
          ),

        const BottomNavigationBarItem(
          icon: Icon(LucideIcons.user),
          label: 'Perfil',
        ),
      ],
    );
  }
}
