import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
  final http.Client _client;

  MercadoPagoOAuthLauncher({
    OAuthUrlLauncher? launcher,
    String? apiBaseUrl,
    http.Client? client,
  }) : _launch = launcher ?? launchUrl,
       _client = client ?? http.Client(),
       _apiBaseUrl = apiBaseUrl ?? ApiConfig.baseUrl;

  Future<Uri> prepare(String token) async {
    final response = await _client
        .post(
          Uri.parse('$_apiBaseUrl/integrations/mercado-pago/connect'),
          headers: {'Authorization': 'Bearer $token'},
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw Exception(
        'Não foi possível iniciar a conexão. Entre novamente no TORICO.',
      );
    }
    Uri uri;
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      uri = Uri.parse(body['authorizationUrl'] as String);
    } catch (_) {
      throw Exception('Resposta de autorização inválida. Tente novamente.');
    }
    if (uri.scheme != 'https' ||
        uri.host != 'auth.mercadopago.com.br' ||
        uri.path != '/authorization' ||
        uri.userInfo.isNotEmpty ||
        uri.hasFragment ||
        uri.hasPort) {
      throw Exception('Endereço de autorização inválido.');
    }
    return uri;
  }

  // Called in a second explicit user gesture, after the authenticated request.
  Future<bool> open(Uri uri) {
    return _launch(
      uri,
      mode: LaunchMode.externalApplication,
      webOnlyWindowName: '_blank',
    );
  }
}
