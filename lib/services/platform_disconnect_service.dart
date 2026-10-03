import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class PlatformDisconnectService {
  final http.Client? client;
  final Future<String?> Function()? tokenLoader;

  PlatformDisconnectService({this.client, this.tokenLoader});

  Future<void> disconnect(String platformId) async {
    if (platformId != 'mercado_pago') {
      throw Exception('Esta plataforma ainda não está disponível.');
    }
    final token =
        await (tokenLoader?.call() ??
            FirebaseAuth.instance.currentUser?.getIdToken(true) ??
            Future<String?>.value(null));
    if (token == null) throw Exception('Entre novamente para desconectar.');
    final transport = client ?? http.Client();
    try {
      final response = await transport
          .post(
            Uri.parse(
              '${ApiConfig.baseUrl}/integrations/$platformId/disconnect',
            ),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) {
        throw Exception('Não foi possível desconectar. Tente novamente.');
      }
    } finally {
      if (client == null) transport.close();
    }
  }
}
