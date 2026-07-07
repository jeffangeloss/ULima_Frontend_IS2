// lib/pages/teacher/attendees_page.dart
// HU18: detalle de una asesoría con la lista de alumnos confirmados.

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../components/skeleton.dart';
import '../../configs/themes.dart';
import 'attendees_controller.dart';

class AttendeesPage extends StatelessWidget {
  const AttendeesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<AttendeesController>();
    final brightness = Theme.brightnessOf(context);

    return Scaffold(
      backgroundColor: MaterialTheme.pageBg(brightness),
      appBar: AppBar(title: Text(c.title)),
      body: Obx(() {
        if (c.isLoading.value && c.attendees.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: SkeletonCardList(count: 4),
          );
        }
        if (c.loadError.value != null) {
          return Center(
            child: Text(
              c.loadError.value!,
              style: TextStyle(color: MaterialTheme.textSecondary(brightness)),
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.groups, color: MaterialTheme.primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    '${c.total.value} confirmados',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: MaterialTheme.textPrimary(brightness),
                    ),
                  ),
                ],
              ),
            ),
            if (c.attendees.isEmpty)
              Expanded(
                child: Center(
                  child: Text(
                    'Aún no hay alumnos confirmados.',
                    style: TextStyle(color: MaterialTheme.textSecondary(brightness)),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: c.attendees.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final a = c.attendees[i];
                    final initials = ((a.lastName.isNotEmpty ? a.lastName[0] : '') +
                            (a.firstName.isNotEmpty ? a.firstName[0] : ''))
                        .toUpperCase();
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: MaterialTheme.cardBg(brightness),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: MaterialTheme.borderColor(brightness)),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: MaterialTheme.primaryColor.withValues(alpha: 0.15),
                            child: Text(
                              initials.isEmpty ? '?' : initials,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                color: MaterialTheme.primaryColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  a.fullName,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: MaterialTheme.textPrimary(brightness),
                                  ),
                                ),
                                Text(
                                  a.code,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: MaterialTheme.textMuted(brightness),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      }),
    );
  }
}
