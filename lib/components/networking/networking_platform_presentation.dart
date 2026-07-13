import 'package:flutter/material.dart';

String networkingPlatformLabel(String platform) {
  switch (platform) {
    case 'linkedin':
      return 'LinkedIn';
    case 'instagram':
      return 'Instagram';
    case 'github':
      return 'GitHub';
    case 'x':
      return 'X';
    case 'website':
      return 'Sitio web';
    case 'other':
      return 'Otra red';
    default:
      return platform;
  }
}

IconData networkingPlatformIcon(String platform) {
  switch (platform) {
    case 'linkedin':
      return Icons.work_outline_rounded;
    case 'instagram':
      return Icons.camera_alt_outlined;
    case 'github':
      return Icons.code_rounded;
    case 'x':
      return Icons.alternate_email_rounded;
    case 'website':
      return Icons.language_rounded;
    default:
      return Icons.share_outlined;
  }
}
