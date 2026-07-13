import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../components/networking/networking_card_preview.dart';
import '../../models/networking_model.dart';
import '../../services/api_client.dart';
import '../../services/chat_repository.dart';
import '../../models/message.dart';

class ChatPage extends StatefulWidget {
  final String sectionId;
  final String courseName;

  /// Inyectable para tests; en producción usa el `ChatRepository` real.
  final ChatRepositoryContract? repository;

  const ChatPage({
    super.key,
    required this.sectionId,
    required this.courseName,
    this.repository,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late final ChatRepositoryContract _chatRepository =
      widget.repository ?? ChatRepository();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  ChatSession? _session;
  String? _loadError;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    try {
      final session = await _chatRepository
          .signInWithCustomToken(widget.sectionId)
          .timeout(const Duration(seconds: 8));
      if (mounted) {
        setState(() => _session = session);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadError = 'No se pudo conectar al chat.');
        Get.snackbar(
          'Error',
          'No se pudo conectar al chat',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _sendMessage() async {
    final session = _session;
    if (session == null) {
      Get.snackbar(
        'Chat no disponible',
        'Vuelve a intentar en unos segundos.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();
    try {
      await _chatRepository.sendMessage(widget.sectionId, text, session);
    } catch (_) {
      if (!mounted) return;
      _textController.text = text;
      Get.snackbar(
        'Error',
        'No se pudo enviar el mensaje',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _sendNetworkingCard() async {
    final session = _session;
    if (session == null) {
      Get.snackbar(
        'Chat no disponible',
        'Vuelve a intentar en unos segundos.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final ownerId = int.tryParse(session.uid);
    if (ownerId == null) return;

    try {
      await _chatRepository.fetchNetworkingCard(ownerId);
      await _chatRepository.sendNetworkingCard(widget.sectionId, session);
    } on ApiException catch (error) {
      if (!mounted) return;
      Get.snackbar(
        'Carnet no disponible',
        error.code == 'NETWORKING_CARD_HIDDEN'
            ? 'Activa "Mostrar mi carnet" antes de enviarlo.'
            : error.message,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (_) {
      if (!mounted) return;
      Get.snackbar(
        'No se pudo enviar',
        'Intenta de nuevo en unos segundos.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _openNetworkingCard(ChatMessage message) async {
    final ownerId = message.networkingOwnerId ?? int.tryParse(message.senderId);
    if (ownerId == null) return;

    try {
      final card = await _chatRepository.fetchNetworkingCard(ownerId);
      if (!mounted) return;
      _showNetworkingCardModal(card);
    } on ApiException catch (error) {
      if (!mounted) return;
      Get.snackbar(
        'Carnet no disponible',
        error.code == 'NETWORKING_CARD_HIDDEN'
            ? 'Este usuario oculto su carnet.'
            : error.message,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (_) {
      if (!mounted) return;
      Get.snackbar(
        'Carnet no disponible',
        'No se pudo abrir este carnet.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _showNetworkingCardModal(PublicNetworkingCardDto card) {
    final link = card.link;
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: NetworkingCardPreview(
            fullName: card.owner.fullName,
            primaryDetail: card.owner.primaryDetail,
            secondaryDetail: card.owner.secondaryDetail,
            optIn: card.card.optIn,
            link: link,
            emptyLinkText: 'Carnet visible sin red compartida',
            onOpenLink: () => _openNetworkingLink(link),
          ),
        ),
      ),
    );
  }

  Future<void> _openNetworkingLink(SocialLinkDto? link) async {
    final uri = Uri.tryParse(link?.url ?? '');
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  /// HU23: el profesor confirma y elimina un mensaje (borrado suave). El backend
  /// valida que sea el profesor de la sección; el stream de RTDB refleja la
  /// lápida "eliminado por…".
  Future<void> _confirmDelete(ChatMessage msg) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          '¿Eliminar mensaje?',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Text(
          'El mensaje quedará marcado como "eliminado por ${msg.senderName == _session?.displayName ? 'ti' : 'el profesor'}". '
          'Esta acción no se puede deshacer.',
          style: const TextStyle(fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red[600]),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _chatRepository.deleteMessage(widget.sectionId, msg.id);
    } catch (_) {
      if (!mounted) return;
      Get.snackbar(
        'No se pudo eliminar',
        'Inténtalo de nuevo en unos segundos.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      });
    }
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Widget _buildUnavailableState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1F2C34) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.white12 : const Color(0xFFFFCCBC),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_clock, color: Color(0xFFFF5722), size: 34),
              const SizedBox(height: 12),
              Text(
                _loadError ?? 'Chat no disponible.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Solo los miembros de esta sección pueden entrar al chat.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            const CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white24,
              child: Icon(Icons.group, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.courseName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Text(
                    'Chat grupal',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFFF5722),
        elevation: 1,
      ),
      body: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0B141A) : const Color(0xFFECE5DD),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _loadError != null || _session == null
            ? _buildUnavailableState(isDark)
            : Column(
                children: [
                  Expanded(
                    child: StreamBuilder<List<ChatMessage>>(
                      stream: _chatRepository.getMessages(widget.sectionId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (snapshot.hasError) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                'Error: ${snapshot.error}',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ),
                          );
                        }

                        final messages = snapshot.data ?? [];
                        if (messages.isEmpty) {
                          return Center(
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 40,
                              ),
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF1F2C34)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.lock_outline_rounded,
                                    color: isDark
                                        ? Colors.white54
                                        : const Color(0xFFFF5722),
                                    size: 30,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Chat privado de la sección',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Solo los miembros de esta sección pueden leer y escribir. Sé el primero en saludar 👋',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: isDark
                                          ? Colors.white70
                                          : Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        WidgetsBinding.instance.addPostFrameCallback(
                          (_) => _scrollToBottom(),
                        );

                        return ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final msg = messages[index];
                            final isMe = msg.senderId == _session!.uid;
                            // Solo el PROFESOR de la sección puede eliminar.
                            final canDelete =
                                _session!.role == 'teacher' && !msg.deleted;

                            return _MessageBubble(
                              message: msg,
                              isMe: isMe,
                              showSender: true,
                              timeText: _formatTime(msg.timestamp),
                              isDark: isDark,
                              onDelete: canDelete
                                  ? () => _confirmDelete(msg)
                                  : null,
                              onOpenNetworkingCard: msg.isNetworkingCard
                                  ? () => _openNetworkingCard(msg)
                                  : null,
                            );
                          },
                        );
                      },
                    ),
                  ),
                  // Input bar
                  Container(
                    color: isDark
                        ? const Color(0xFF1F2C34)
                        : const Color(0xFFF0F0F0),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 6,
                    ),
                    child: SafeArea(
                      top: false,
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF2A3942)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Row(
                                children: [
                                  Tooltip(
                                    message: 'Enviar carnet',
                                    child: IconButton(
                                      onPressed: _sendNetworkingCard,
                                      icon: const Icon(
                                        Icons.contact_page_outlined,
                                        size: 21,
                                      ),
                                      color: const Color(0xFFFF7A1A),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ),
                                  Expanded(
                                    child: TextField(
                                      controller: _textController,
                                      textCapitalization:
                                          TextCapitalization.sentences,
                                      maxLines: 4,
                                      minLines: 1,
                                      decoration: InputDecoration(
                                        hintText: 'Escribe un mensaje...',
                                        hintStyle: TextStyle(
                                          color: isDark
                                              ? Colors.grey[500]
                                              : Colors.grey[600],
                                        ),
                                        border: InputBorder.none,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 4,
                                              vertical: 10,
                                            ),
                                      ),
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                      onSubmitted: (_) => _sendMessage(),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Material(
                            color: const Color(0xFFFF5722),
                            shape: const CircleBorder(),
                            elevation: 2,
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: _sendMessage,
                              child: const Padding(
                                padding: EdgeInsets.all(10),
                                child: Icon(
                                  Icons.send,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Individual message bubble styled like WhatsApp
class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final bool showSender;
  final String timeText;
  final bool isDark;

  /// Solo se pasa cuando el usuario actual es el profesor y el mensaje no está
  /// eliminado: habilita el long-press para eliminar.
  final VoidCallback? onDelete;
  final VoidCallback? onOpenNetworkingCard;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.showSender,
    required this.timeText,
    required this.isDark,
    this.onDelete,
    this.onOpenNetworkingCard,
  });

  /// Generates a consistent color from a sender name
  Color _senderColor(String name) {
    const palette = [
      Color(0xFF1FA855), // green
      Color(0xFF5B61D6), // purple
      Color(0xFFD65B5B), // red
      Color(0xFFD6A85B), // amber
      Color(0xFF5BA8D6), // blue
      Color(0xFFD65BAF), // pink
      Color(0xFF35B0AB), // teal
      Color(0xFFE07020), // orange
    ];
    final hash = name.codeUnits.fold<int>(0, (prev, c) => prev + c);
    return palette[hash % palette.length];
  }

  Color _roleAccent(ChatMessage message) {
    switch (message.senderRole) {
      case 'teacher':
        return const Color(0xFFB3261E);
      case 'jp':
        return const Color(0xFFE07020);
      case 'delegate':
        return const Color(0xFF047857);
      case 'subdelegate':
        return const Color(0xFF2563EB);
      default:
        return _senderColor(message.senderName);
    }
  }

  Color _bubbleColor(ChatMessage message, Color baseColor, Color accent) {
    if (!message.isModerator) return baseColor;
    final opacity = message.weight >= 90 ? 0.18 : 0.12;
    return Color.alphaBlend(accent.withValues(alpha: opacity), baseColor);
  }

  @override
  Widget build(BuildContext context) {
    // HU23: mensaje eliminado → lápida "eliminado por…".
    if (message.deleted) {
      return _DeletedTombstone(message: message, isMe: isMe, isDark: isDark);
    }

    // Bubble colors
    final myBubbleColor = isDark
        ? const Color(0xFF005C4B)
        : const Color(0xFFDCF8C6);
    final otherBubbleColor = isDark ? const Color(0xFF1F2C34) : Colors.white;
    final accent = _roleAccent(message);
    final bubbleColor = _bubbleColor(
      message,
      isMe ? myBubbleColor : otherBubbleColor,
      accent,
    );

    // Tail radius
    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(12),
      topRight: const Radius.circular(12),
      bottomLeft: Radius.circular(isMe ? 12 : 0),
      bottomRight: Radius.circular(isMe ? 0 : 12),
    );

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      // Long-press: solo el profesor (onDelete != null) puede eliminar.
      child: GestureDetector(
        onLongPress: onDelete,
        onTap: message.isNetworkingCard ? onOpenNetworkingCard : null,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78,
          ),
          margin: EdgeInsets.only(
            top: showSender ? 8 : 2,
            bottom: 2,
            left: isMe ? 48 : 0,
            right: isMe ? 0 : 48,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: borderRadius,
            border: message.isNetworkingCard
                ? Border.all(
                    color: const Color(0xFFFFB16A).withValues(alpha: 0.85),
                    width: 1.4,
                  )
                : message.isModerator
                ? Border.all(
                    color: accent.withValues(
                      alpha: message.weight >= 90 ? 0.85 : 0.55,
                    ),
                    width: message.weight >= 90 ? 1.4 : 1,
                  )
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Every bubble shows identity; moderator roles get a visible badge.
              if (showSender)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      Text(
                        message.senderName,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: accent,
                        ),
                      ),
                      if (message.isModerator)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: accent.withValues(
                              alpha: isDark ? 0.22 : 0.12,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            message.senderRoleLabel,
                            style: TextStyle(
                              color: accent,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              if (message.isNetworkingCard)
                _NetworkingCardMessage(timeText: timeText, isDark: isDark)
              else
                Wrap(
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.end,
                  spacing: 8,
                  children: [
                    Text(
                      message.text,
                      style: TextStyle(
                        fontSize: 15.5,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        timeText,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white38 : Colors.black45,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NetworkingCardMessage extends StatelessWidget {
  const _NetworkingCardMessage({required this.timeText, required this.isDark});

  final String timeText;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: const Color(0xFFFF7A1A),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.contact_page_outlined,
            color: Colors.white.withValues(alpha: 0.92),
            size: 20,
          ),
        ),
        const SizedBox(width: 9),
        Flexible(
          child: Text(
            'Envio su carnet de networking',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          timeText,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.white38 : Colors.black45,
          ),
        ),
      ],
    );
  }
}

/// HU23: lápida de un mensaje eliminado por el profesor. Reemplaza al bubble
/// normal; mantiene el lado (izq/der) del emisor original pero en tono apagado.
class _DeletedTombstone extends StatelessWidget {
  const _DeletedTombstone({
    required this.message,
    required this.isMe,
    required this.isDark,
  });

  final ChatMessage message;
  final bool isMe;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final by = (message.deletedBy != null && message.deletedBy!.isNotEmpty)
        ? message.deletedBy!
        : 'el profesor';
    final fg = isDark ? Colors.white54 : Colors.black45;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        margin: EdgeInsets.only(
          top: 8,
          bottom: 2,
          left: isMe ? 48 : 0,
          right: isMe ? 0 : 48,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.do_not_disturb_on_outlined, size: 15, color: fg),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                'Mensaje eliminado por $by',
                style: TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: fg,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
