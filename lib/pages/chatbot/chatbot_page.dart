import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../components/skeleton.dart';
import 'chatbot_controller.dart';
import '../../models/chatbot_models.dart';

class ChatbotPage extends StatelessWidget {
  const ChatbotPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ChatbotController());
    final colors = Theme.of(context).colorScheme;
    final isWide = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () {
            if (!isWide && controller.activeSessionId.value != null) {
              controller.activeSessionId.value = null;
            } else {
              Get.back();
            }
          },
        ),
        title: const Text('Chatbot'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.plus),
            tooltip: 'Nueva conversacion',
            onPressed: () => controller.createSession(),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 600;
          return _buildBody(controller, colors, isWide);
        },
      ),
    );
  }

  Widget _buildBody(ChatbotController controller, ColorScheme colors, bool isWide) {
    return Obx(() {
      if (controller.loadingSessions.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.sessions.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.messageCircle, size: 64, color: colors.primary.withAlpha(100)),
              const SizedBox(height: 16),
              Text(
                'No tienes conversaciones.',
                style: TextStyle(fontSize: 18, color: colors.onSurface.withAlpha(180)),
              ),
              const SizedBox(height: 8),
              Text(
                'Crea una nueva para empezar.',
                style: TextStyle(color: colors.onSurface.withAlpha(120)),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => controller.createSession(),
                icon: const Icon(LucideIcons.plus, size: 18),
                label: const Text('Nueva conversacion'),
              ),
            ],
          ),
        );
      }

      return Builder(
        builder: (ctx) {
          if (isWide) {
            return Row(
              children: [
                SizedBox(
                  width: 280,
                  child: _buildSessionList(controller, colors),
                ),
                const VerticalDivider(width: 1),
                Expanded(child: _buildChatArea(controller, colors, ctx)),
              ],
            );
          }

          if (controller.activeSessionId.value == null) {
            return _buildSessionList(controller, colors);
          }

          return _buildChatArea(controller, colors, ctx);
        },
      );
    });
  }

  Widget _buildSessionList(ChatbotController controller, ColorScheme colors) {
    return Obx(() {
      return ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: controller.sessions.length,
        separatorBuilder: (_, _) => const SizedBox(height: 4),
        itemBuilder: (context, index) {
          final session = controller.sessions[index];
          final isActive = session.id == controller.activeSessionId.value;

          return Dismissible(
            key: Key(session.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 16),
              color: colors.error,
              child: const Icon(LucideIcons.trash2, color: Colors.white),
            ),
            confirmDismiss: (_) async {
              return await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Eliminar conversacion'),
                  content: const Text('¿Estas seguro de eliminar esta conversacion?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancelar'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text('Eliminar', style: TextStyle(color: colors.error)),
                    ),
                  ],
                ),
              ) ?? false;
            },
            onDismissed: (_) => controller.deleteSession(session.id),
            child: ListTile(
              selected: isActive,
              selectedTileColor: colors.primary.withAlpha(30),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              title: Text(
                session.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14),
              ),
              subtitle: Text(
                _formatDate(session.updatedAt),
                style: TextStyle(fontSize: 12, color: colors.onSurface.withAlpha(120)),
              ),
              leading: Icon(
                LucideIcons.messageSquare,
                size: 20,
                color: isActive ? colors.primary : colors.onSurface.withAlpha(120),
              ),
              onTap: () => controller.selectSession(session.id),
            ),
          );
        },
      );
    });
  }

  Widget _buildChatArea(ChatbotController controller, ColorScheme colors, BuildContext context) {
    final textController = TextEditingController();

    return Column(
      children: [
        Expanded(
          child: Obx(() {
            if (controller.loadingMessages.value) {
              return SkeletonCardList(count: 6);
            }

            if (controller.messages.isEmpty) {
              return Center(
                child: Text(
                  'Escribe tu primera pregunta.',
                  style: TextStyle(color: colors.onSurface.withAlpha(120)),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: controller.messages.length + (controller.isTyping.value ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= controller.messages.length) {
                  return _buildTypingIndicator(colors);
                }
                return _buildMessageBubble(controller.messages[index], colors, context);
              },
            );
          }),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border(top: BorderSide(color: colors.outline.withAlpha(40))),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: textController,
                  maxLength: 500,
                  minLines: 1,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Escribe tu pregunta...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    counterText: '',
                    filled: true,
                    fillColor: colors.surfaceContainerHighest.withAlpha(80),
                  ),
                  onSubmitted: controller.isTyping.value
                      ? null
                      : (value) {
                          if (value.trim().isNotEmpty) {
                            controller.sendQuestion(value.trim());
                            textController.clear();
                          }
                        },
                ),
              ),
              const SizedBox(width: 8),
              Obx(() => IconButton.filled(
                onPressed: controller.isTyping.value
                    ? null
                    : () {
                        final value = textController.text.trim();
                        if (value.isNotEmpty) {
                          controller.sendQuestion(value);
                          textController.clear();
                        }
                      },
                icon: const Icon(LucideIcons.send, size: 20),
              )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessageBubble(ChatbotMessage message, ColorScheme colors, BuildContext context) {
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isUser ? colors.primary : colors.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              isUser ? 'Tu' : 'ULimaBot',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isUser ? colors.onPrimary.withAlpha(180) : colors.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message.content,
              style: TextStyle(
                fontSize: 14,
                color: isUser ? colors.onPrimary : colors.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator(ColorScheme colors) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: SkeletonPulse(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Escribiendo', style: TextStyle(color: colors.onSurface.withAlpha(120), fontSize: 13)),
              const SizedBox(width: 4),
              _buildDot(colors, 0),
              _buildDot(colors, 200),
              _buildDot(colors, 400),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDot(ColorScheme colors, int delayMs) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        Future.delayed(Duration(milliseconds: delayMs));
        return Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: colors.primary.withAlpha((value * 255).toInt()),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inHours < 1) return '${diff.inMinutes} min';
    if (diff.inDays < 1) return '${diff.inHours}h';
    if (diff.inDays == 1) return 'Ayer';
    return '${date.day}/${date.month}/${date.year}';
  }
}
