// lib/pages/teacher/create_advising_page.dart
// HU18: formulario de creación de asesoría extra (7 campos de entrada:
// sección, fecha, hora inicio, hora fin, modalidad, ubicación, cupo).

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../configs/themes.dart';
import '../../models/advising_models.dart';
import 'create_advising_controller.dart';

class CreateAdvisingPage extends StatelessWidget {
  const CreateAdvisingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<CreateAdvisingController>();
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
            borderSide: const BorderSide(color: MaterialTheme.primaryColor, width: 2),
          ),
        );

    Widget label(String text) => Padding(
          padding: const EdgeInsets.only(bottom: 8, top: 18),
          child: Text(
            text,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: labelColor),
          ),
        );

    return Scaffold(
      backgroundColor: MaterialTheme.pageBg(brightness),
      appBar: AppBar(title: const Text('Nueva asesoría extra')),
      body: Obx(() {
        if (c.loadingSections.value) {
          return const Center(child: CircularProgressIndicator(color: MaterialTheme.primaryColor));
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Sección
              label('Sección'),
              DropdownButtonFormField<int>(
                initialValue: c.selectedSectionId.value,
                isExpanded: true,
                decoration: boxDecoration('Elige una sección'),
                items: c.sections
                    .map((TeacherSectionOption s) => DropdownMenuItem(
                          value: s.sectionId,
                          child: Text('${s.label}  ·  ${s.rol}', overflow: TextOverflow.ellipsis),
                        ))
                    .toList(),
                onChanged: (v) => c.selectedSectionId.value = v,
              ),

              // 2. Fecha
              label('Fecha'),
              _PickerField(
                text: c.date.value == null
                    ? 'Selecciona la fecha'
                    : '${c.date.value!.year}-${c.date.value!.month.toString().padLeft(2, '0')}-${c.date.value!.day.toString().padLeft(2, '0')}',
                icon: Icons.calendar_today_outlined,
                brightness: brightness,
                onTap: () async {
                  final now = DateTime.now();
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: c.date.value ?? now,
                    firstDate: now,
                    lastDate: now.add(const Duration(days: 365)),
                  );
                  if (picked != null) c.date.value = picked;
                },
              ),

              // 3-4. Horas
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        label('Hora inicio'),
                        _PickerField(
                          text: c.startTimeText.isEmpty ? '--:--' : c.startTimeText,
                          icon: Icons.schedule,
                          brightness: brightness,
                          onTap: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: c.startTime.value ?? const TimeOfDay(hour: 10, minute: 0),
                            );
                            if (picked != null) c.startTime.value = picked;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        label('Hora fin'),
                        _PickerField(
                          text: c.endTimeText.isEmpty ? '--:--' : c.endTimeText,
                          icon: Icons.schedule,
                          brightness: brightness,
                          onTap: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: c.endTime.value ?? const TimeOfDay(hour: 11, minute: 0),
                            );
                            if (picked != null) c.endTime.value = picked;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // 5. Modalidad
              label('Modalidad'),
              SegmentedButton<String>(
                // Sin el check de selección (el fondo naranja ya indica la
                // opción elegida): así "Presencial" + ✓ deja de desbordar y
                // partirse en dos líneas. Padding/densidad reducidos y softWrap
                // desactivado para que las 3 etiquetas quepan en una sola línea.
                showSelectedIcon: false,
                style: SegmentedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
                  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                segments: const [
                  ButtonSegment(
                    value: 'classroom',
                    label: Text('Presencial', softWrap: false, overflow: TextOverflow.fade),
                  ),
                  ButtonSegment(
                    value: 'virtual',
                    label: Text('Virtual', softWrap: false, overflow: TextOverflow.fade),
                  ),
                  ButtonSegment(
                    value: 'hybrid',
                    label: Text('Híbrida', softWrap: false, overflow: TextOverflow.fade),
                  ),
                ],
                selected: {c.modality.value},
                onSelectionChanged: (s) => c.modality.value = s.first,
              ),

              // 6. Ubicación (según modalidad)
              if (c.modality.value != 'virtual') ...[
                label('Aula'),
                TextField(controller: c.classroomController, decoration: boxDecoration('Ej. T-501')),
              ],
              if (c.modality.value != 'classroom') ...[
                label('Enlace de la reunión'),
                TextField(
                  controller: c.urlController,
                  keyboardType: TextInputType.url,
                  decoration: boxDecoration('https://...'),
                ),
              ],

              // 7. Cupo (opcional)
              label('Cupo (opcional)'),
              TextField(
                controller: c.capacityController,
                keyboardType: TextInputType.number,
                decoration: boxDecoration('Sin límite'),
              ),

              // Nota (opcional)
              label('Nota (opcional)'),
              TextField(
                controller: c.noteController,
                maxLines: 3,
                decoration: boxDecoration('Tema o indicaciones para los alumnos'),
              ),

              // Error + submit
              if (c.errorMessage.value != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    c.errorMessage.value!,
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
                child: ElevatedButton(
                  onPressed: c.submitting.value ? null : c.submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MaterialTheme.primaryColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: MaterialTheme.primaryColor.withValues(alpha: 0.5),
                  ),
                  child: c.submitting.value
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                        )
                      : const Text('Publicar asesoría',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.text,
    required this.icon,
    required this.brightness,
    required this.onTap,
  });

  final String text;
  final IconData icon;
  final Brightness brightness;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
        decoration: BoxDecoration(
          color: MaterialTheme.cardBg(brightness),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: MaterialTheme.borderColor(brightness)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: MaterialTheme.textMuted(brightness)),
            const SizedBox(width: 10),
            Text(text, style: TextStyle(fontSize: 15, color: MaterialTheme.textPrimary(brightness))),
          ],
        ),
      ),
    );
  }
}
