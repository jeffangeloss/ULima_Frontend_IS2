import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../configs/themes.dart';
import '../../../models/anuncio_model.dart';
import '../../../models/curso_delegado_model.dart';
import 'create_announcement_controller.dart';

class CreateAnnouncementPage extends StatefulWidget {
  const CreateAnnouncementPage({super.key, required this.curso, this.anuncio});

  final CursoDelegado curso;
  final Anuncio? anuncio;

  @override
  State<CreateAnnouncementPage> createState() => _CreateAnnouncementPageState();
}

class _CreateAnnouncementPageState extends State<CreateAnnouncementPage> {
  late final String _tag;
  late final CreateAnnouncementController controller;

  @override
  void initState() {
    super.initState();
    _tag =
        'create-announcement-${widget.curso.idSeccion}-${widget.anuncio?.id ?? 'new'}';
    controller = Get.put(
      CreateAnnouncementController(
        curso: widget.curso,
        anuncio: widget.anuncio,
      ),
      tag: _tag,
    );
  }

  @override
  void dispose() {
    Get.delete<CreateAnnouncementController>(tag: _tag);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.brightnessOf(context);
    final labelColor = MaterialTheme.textPrimary(brightness);

    InputDecoration boxDecoration(String hint) => InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: MaterialTheme.cardBg(brightness),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      isDense: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: MaterialTheme.borderColor(brightness)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: MaterialTheme.borderColor(brightness)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: MaterialTheme.primaryColor,
          width: 2,
        ),
      ),
    );

    Widget label(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 18),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: labelColor,
        ),
      ),
    );

    return Scaffold(
      backgroundColor: MaterialTheme.pageBg(brightness),
      appBar: AppBar(
        title: Text(controller.isEditing ? 'Editar anuncio' : 'Nuevo anuncio'),
      ),
      body: Obx(
        () => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionBanner(curso: widget.curso, brightness: brightness),
              label('Título'),
              TextField(
                controller: controller.titleController,
                textInputAction: TextInputAction.next,
                decoration: boxDecoration(
                  'Ej. Cambio de aula para la práctica',
                ),
              ),
              label('Mensaje'),
              TextField(
                controller: controller.messageController,
                minLines: 6,
                maxLines: 10,
                textInputAction: TextInputAction.newline,
                decoration: boxDecoration(
                  'Escribe la actualización para tu sección',
                ),
              ),
              if (controller.errorMessage.value != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    controller.errorMessage.value!,
                    style: const TextStyle(
                      color: MaterialTheme.primaryDark,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: controller.submitting.value
                      ? null
                      : controller.submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MaterialTheme.primaryColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: MaterialTheme.primaryColor
                        .withValues(alpha: 0.5),
                  ),
                  icon: controller.submitting.value
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.2,
                          ),
                        )
                      : Icon(
                          controller.isEditing
                              ? LucideIcons.save
                              : LucideIcons.send,
                          size: 18,
                        ),
                  label: Text(
                    controller.isEditing
                        ? 'Guardar cambios'
                        : 'Publicar anuncio',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionBanner extends StatelessWidget {
  const _SectionBanner({required this.curso, required this.brightness});

  final CursoDelegado curso;
  final Brightness brightness;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: MaterialTheme.cardBg(brightness),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MaterialTheme.borderColor(brightness)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: MaterialTheme.primaryColor.withValues(alpha: 0.15),
            child: const Icon(
              LucideIcons.megaphone,
              color: MaterialTheme.primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  curso.nombreCurso,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: MaterialTheme.textPrimary(brightness),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${curso.codigoSeccion} · ${curso.rolTexto}',
                  style: const TextStyle(
                    color: MaterialTheme.primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
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
