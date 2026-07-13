String? validateNetworkingUrl(String? value) {
  final trimmed = value?.trim() ?? '';
  if (trimmed.isEmpty) return 'Ingresa el enlace de tu red.';

  final uri = Uri.tryParse(trimmed);
  final isHttp = uri?.scheme == 'http' || uri?.scheme == 'https';
  if (uri == null || !isHttp || uri.host.isEmpty) {
    return 'Ingresa un enlace completo que empiece con http:// o https://.';
  }

  return null;
}
