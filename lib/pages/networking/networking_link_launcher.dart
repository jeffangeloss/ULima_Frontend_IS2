import 'package:url_launcher/url_launcher.dart';

abstract class NetworkingLinkLauncher {
  Future<bool> open(Uri uri);
}

class ExternalNetworkingLinkLauncher implements NetworkingLinkLauncher {
  @override
  Future<bool> open(Uri uri) {
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
