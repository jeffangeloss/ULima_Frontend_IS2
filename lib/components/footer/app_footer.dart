// lib/components/app_footer.dart

import 'package:flutter/material.dart';
import 'package:ulima_plus/configs/themes.dart';

class AppFooterItem {
  const AppFooterItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

class AppFooter extends StatelessWidget {
  final int currentIndex;
  final List<AppFooterItem> items;
  final Function(int)? onTap;

  const AppFooter({
    super.key,
    required this.currentIndex,
    required this.items,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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

      items: items
          .map(
            (item) => BottomNavigationBarItem(
              icon: Icon(item.icon),
              label: item.label,
            ),
          )
          .toList(),
    );
  }
}
