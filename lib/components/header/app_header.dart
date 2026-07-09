import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/configs/themes.dart';
import 'package:ulima_plus/services/alert_service.dart';
import 'package:ulima_plus/pages/alertas/alertas_page.dart';
import 'package:ulima_plus/services/auth_service.dart';
import 'package:ulima_plus/pages/horario/horario_controller.dart';

class AppHeader extends StatelessWidget {
  final bool showScheduleToggle;
  
  const AppHeader({super.key, this.showScheduleToggle = false});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final showAlerts = !(AuthService.to.currentUser?.isTeacher ?? false);

    return Container(
      padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 20),
      decoration: BoxDecoration(
        color: MaterialTheme.headerColor(Theme.brightnessOf(context)),
        border: Border(
          bottom: BorderSide(color: colors.primaryContainer, width: 2.0),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ULIMA++',

                style: TextStyle(
                  color: colors.onPrimary,
                  fontSize: 20,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.bold,
                ),
              ),

              Row(
                children: [
                  if (showScheduleToggle)
                    Obx(() {
                      final hControl = Get.put(HorarioController());

                      return IconButton(
                        icon: Icon(
                          hControl.isListView.value
                              ? Icons.calendar_today
                              : Icons.format_list_bulleted,
                          color: colors.onPrimary,
                        ),
                        onPressed: () {
                          hControl.toggleListView();
                        },
                      );
                    }),
                  if (showAlerts)
                    Obx(() {
                      final count = Get.isRegistered<AlertService>()
                          ? AlertService.to.unreadCount
                          : 0;

                      return InkWell(
                        onTap: () {
                          Get.to(() => const AlertasPage());
                        },
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Icon(
                              Icons.notifications_none,
                              color: colors.onPrimary,
                              size: 30,
                            ),
                            if (count > 0)
                              Positioned(
                                right: -4,
                                top: -4,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Color.fromARGB(255, 29, 111, 219),
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 18,
                                    minHeight: 18,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '$count',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    })
                  else
                    const SizedBox(width: 30, height: 30),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/* LOGO SVG
SvgPicture.asset(
                  'assets/images/logo.svg',
                  width: 30,
                  semanticsLabel: 'Logo',
                  
                ),
*/
