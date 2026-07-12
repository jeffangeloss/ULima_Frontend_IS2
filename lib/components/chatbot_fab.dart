import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ChatbotFab extends StatelessWidget {
  const ChatbotFab({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return FloatingActionButton.extended(
      heroTag: 'chatbot_fab',
      onPressed: () => Get.toNamed('/chatbot'),
      backgroundColor: colors.primary,
      foregroundColor: colors.onPrimary,
      icon: const Icon(LucideIcons.messageCircle, size: 22),
      label: const Text('Chatbot'),
    );
  }
}
