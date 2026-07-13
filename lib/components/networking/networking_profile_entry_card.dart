import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../configs/themes.dart';

class NetworkingProfileEntryCard extends StatelessWidget {
  const NetworkingProfileEntryCard({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Semantics(
      button: true,
      label: 'Configurar carnet de networking',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: MaterialTheme.cardBg(brightness),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: MaterialTheme.borderColor(brightness)),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: MaterialTheme.espPrincipalBg(brightness),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    LucideIcons.contactRound,
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
                        'Configurar carnet',
                        style: TextStyle(
                          color: MaterialTheme.textPrimary(brightness),
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Elige una red y controla su visibilidad',
                        style: TextStyle(
                          color: MaterialTheme.labelColor(brightness),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  LucideIcons.chevronRight,
                  size: 18,
                  color: MaterialTheme.labelColor(brightness),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
