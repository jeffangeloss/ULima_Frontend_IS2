import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../components/networking/networking_card_preview.dart';
import '../../components/networking/networking_platform_presentation.dart';
import '../../configs/themes.dart';
import 'networking_controller.dart';

class NetworkingPage extends GetView<NetworkingController> {
  const NetworkingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Obx(
      () => PopScope(
        canPop: !controller.hasUnsavedChanges,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && controller.hasUnsavedChanges) {
            _showPendingChangesNotice(context);
          }
        },
        child: Scaffold(
          backgroundColor: MaterialTheme.pageBg(brightness),
          appBar: AppBar(
            title: const Text(
              'Carnet de networking',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            centerTitle: false,
          ),
          body: _NetworkingBody(controller: controller),
        ),
      ),
    );
  }
}

class _NetworkingBody extends StatelessWidget {
  const _NetworkingBody({required this.controller});

  final NetworkingController controller;

  @override
  Widget build(BuildContext context) {
    switch (controller.status.value) {
      case NetworkingViewStatus.loading:
        return const Center(
          child: CircularProgressIndicator(color: MaterialTheme.primaryColor),
        );
      case NetworkingViewStatus.error:
        return _LoadErrorState(
          message: controller.loadError.value,
          onRetry: controller.load,
        );
      case NetworkingViewStatus.ready:
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    NetworkingCardPreview(
                      fullName: controller.fullName,
                      primaryDetail: controller.primaryDetail,
                      secondaryDetail: controller.secondaryDetail,
                      optIn: controller.optIn.value,
                      link: controller.previewLink,
                      onOpenLink: controller.openPreviewLink,
                    ),
                    const SizedBox(height: 22),
                    _VisibilityCard(controller: controller),
                    const SizedBox(height: 16),
                    _LinkEditorCard(controller: controller),
                    const SizedBox(height: 18),
                    if (controller.saveMessage.value.isNotEmpty) ...[
                      _SaveFeedback(
                        message: controller.saveMessage.value,
                        succeeded: controller.saveSucceeded.value,
                      ),
                      const SizedBox(height: 12),
                    ],
                    FilledButton(
                      onPressed: controller.canSave ? controller.save : null,
                      child: controller.isSaving.value
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Guardar carnet',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
    }
  }
}

class _VisibilityCard extends StatelessWidget {
  const _VisibilityCard({required this.controller});

  final NetworkingController controller;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(brightness),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: MaterialTheme.espPrincipalBg(brightness),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              controller.optIn.value ? LucideIcons.eye : LucideIcons.eyeOff,
              color: MaterialTheme.primaryDark,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mostrar mi carnet',
                  style: TextStyle(
                    color: MaterialTheme.textPrimary(brightness),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  controller.optIn.value
                      ? 'Tu carnet podrá mostrarse dentro de la app.'
                      : 'Tu red seguirá guardada, pero el carnet estará oculto.',
                  style: TextStyle(
                    color: MaterialTheme.textMuted(brightness),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            value: controller.optIn.value,
            activeTrackColor: MaterialTheme.primaryColor,
            onChanged: controller.setOptIn,
          ),
        ],
      ),
    );
  }
}

class _LinkEditorCard extends StatelessWidget {
  const _LinkEditorCard({required this.controller});

  final NetworkingController controller;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(brightness),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Red para compartir',
                  style: TextStyle(
                    color: MaterialTheme.textPrimary(brightness),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (controller.hasLinkDraft.value) ...[
                Tooltip(
                  message: 'Editar red',
                  child: IconButton(
                    onPressed: controller.isEditingLink.value
                        ? null
                        : controller.startEditingLink,
                    icon: const Icon(LucideIcons.pencil, size: 18),
                    color: MaterialTheme.primaryDark,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                Tooltip(
                  message: 'Eliminar red',
                  child: IconButton(
                    onPressed: () => _confirmRemoveLink(context, controller),
                    icon: const Icon(LucideIcons.trash2, size: 18),
                    color: Colors.redAccent,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Aquí puedes compartir LinkedIn, Instagram, GitHub, X, tu página propia u otra red. Solo se mostrará una a la vez y podrás cambiarla cuando quieras.',
            style: TextStyle(
              color: MaterialTheme.textMuted(brightness),
              fontSize: 12,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          if (!controller.hasLinkDraft.value)
            _EmptyLinkEditor(onAdd: controller.startAddingLink)
          else if (!controller.isEditingLink.value)
            _SavedLinkSummary(controller: controller)
          else ...[
            DropdownButtonFormField<String>(
              initialValue: controller.platform.value,
              isExpanded: true,
              decoration: _inputDecoration(
                context,
                label: 'Red social',
                icon: LucideIcons.share2,
              ),
              items: NetworkingController.supportedPlatforms
                  .map(
                    (value) => DropdownMenuItem(
                      value: value,
                      child: Row(
                        children: [
                          Icon(
                            networkingPlatformIcon(value),
                            size: 18,
                            color: MaterialTheme.primaryDark,
                          ),
                          const SizedBox(width: 10),
                          Text(networkingPlatformLabel(value)),
                        ],
                      ),
                    ),
                  )
                  .toList(growable: false),
              onChanged: controller.setPlatform,
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller.urlController,
              keyboardType: TextInputType.url,
              textInputAction: controller.showLabelField
                  ? TextInputAction.next
                  : TextInputAction.done,
              autocorrect: false,
              enableSuggestions: false,
              decoration: _inputDecoration(
                context,
                label: 'Enlace',
                hint: 'https://...',
                icon: LucideIcons.link,
              ),
            ),
            if (controller.showLabelField) ...[
              const SizedBox(height: 14),
              TextField(
                controller: controller.labelController,
                textInputAction: TextInputAction.done,
                decoration: _inputDecoration(
                  context,
                  label: 'Nombre visible',
                  hint: 'Ej. Mi portafolio',
                  icon: LucideIcons.tag,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _SavedLinkSummary extends StatelessWidget {
  const _SavedLinkSummary({required this.controller});

  final NetworkingController controller;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final link = controller.previewLink;
    if (link == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: MaterialTheme.lockedBg(brightness),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: MaterialTheme.borderColor(brightness)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: MaterialTheme.espPrincipalBg(brightness),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              networkingPlatformIcon(link.platform),
              color: MaterialTheme.primaryDark,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  link.label ?? networkingPlatformLabel(link.platform),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: MaterialTheme.textPrimary(brightness),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  link.url,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: MaterialTheme.textMuted(brightness),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyLinkEditor extends StatelessWidget {
  const _EmptyLinkEditor({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MaterialTheme.lockedBg(brightness),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: MaterialTheme.borderColor(brightness)),
      ),
      child: Column(
        children: [
          Icon(
            LucideIcons.link2Off,
            color: MaterialTheme.textMuted(brightness),
            size: 30,
          ),
          const SizedBox(height: 8),
          Text(
            'Todavia no tienes una red configurada.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: MaterialTheme.textSecondary(brightness),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onAdd,
            icon: const Icon(LucideIcons.plus, size: 17),
            label: const Text('Agregar red social'),
          ),
        ],
      ),
    );
  }
}

class _SaveFeedback extends StatelessWidget {
  const _SaveFeedback({required this.message, required this.succeeded});

  final String message;
  final bool succeeded;

  @override
  Widget build(BuildContext context) {
    final color = succeeded ? const Color(0xFF15803D) : Colors.redAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(
            succeeded ? LucideIcons.circleCheck : LucideIcons.circleAlert,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadErrorState extends StatelessWidget {
  const _LoadErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.wifiOff,
              color: MaterialTheme.textMuted(brightness),
              size: 42,
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: MaterialTheme.textSecondary(brightness),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(LucideIcons.refreshCw, size: 17),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _confirmRemoveLink(
  BuildContext context,
  NetworkingController controller,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('¿Eliminar red?'),
      content: const Text(
        'Se quitará esta red de tu carnet. Podrás agregar otra cuando quieras.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('Eliminar'),
        ),
      ],
    ),
  );

  if (confirmed == true) controller.removeLink();
}

void _showPendingChangesNotice(BuildContext context) {
  final brightness = Theme.of(context).brightness;
  Get.snackbar(
    'Cambios pendientes',
    'Guarda el carnet o descarta tus cambios antes de salir.',
    snackPosition: SnackPosition.TOP,
    margin: const EdgeInsets.all(14),
    borderRadius: 14,
    backgroundColor: MaterialTheme.primaryColor.withValues(alpha: 0.12),
    borderColor: MaterialTheme.primaryColor.withValues(alpha: 0.26),
    borderWidth: 1,
    colorText: MaterialTheme.textPrimary(brightness),
    icon: const Icon(
      LucideIcons.triangleAlert,
      color: MaterialTheme.primaryDark,
      size: 20,
    ),
    duration: const Duration(seconds: 3),
  );
}

BoxDecoration _cardDecoration(Brightness brightness) => BoxDecoration(
  color: MaterialTheme.cardBg(brightness),
  borderRadius: BorderRadius.circular(16),
  border: Border.all(color: MaterialTheme.borderColor(brightness)),
);

InputDecoration _inputDecoration(
  BuildContext context, {
  required String label,
  required IconData icon,
  String? hint,
}) {
  final brightness = Theme.of(context).brightness;
  return InputDecoration(
    labelText: label,
    hintText: hint,
    prefixIcon: Icon(icon, size: 19),
    filled: true,
    fillColor: MaterialTheme.pageBg(brightness),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(13),
      borderSide: BorderSide(color: MaterialTheme.borderColor(brightness)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(13),
      borderSide: BorderSide(color: MaterialTheme.borderColor(brightness)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(13),
      borderSide: const BorderSide(
        color: MaterialTheme.primaryColor,
        width: 1.5,
      ),
    ),
  );
}
