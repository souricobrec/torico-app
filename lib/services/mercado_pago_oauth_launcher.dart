import 'package:url_launcher/url_launcher.dart';

import '../config/api_config.dart';

typedef OAuthUrlLauncher =
    Future<bool> Function(
      Uri uri, {
      LaunchMode mode,
      String? webOnlyWindowName,
    });

/// Keep launch in the user's click handler: no async capability check first.
/// Native platforms use the external browser; web requests a separate tab.
class MercadoPagoOAuthLauncher {
  final OAuthUrlLauncher _launch;
  final String _apiBaseUrl;

  MercadoPagoOAuthLauncher({OAuthUrlLauncher? launcher, String? apiBaseUrl})
    : _launch = launcher ?? launchUrl,
      _apiBaseUrl = apiBaseUrl ?? ApiConfig.baseUrl;

  Future<bool> open(String firebaseUid) {
    final uri = Uri.parse(
      '$_apiBaseUrl/integrations/mercado-pago/connect',
    ).replace(queryParameters: {'userId': firebaseUid});
    return _launch(
      uri,
      mode: LaunchMode.externalApplication,
      webOnlyWindowName: '_blank',
    );
  }
}
