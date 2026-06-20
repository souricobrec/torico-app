import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

import 'local_storage_service.dart';

class IntegrationService {
  static const String _backendBaseUrl =
      'https://torico-backend-16783123127.us-central1.run.app';

  static const Map<String, String> _supportedPlatformIds = {
    'Mercado Pago': 'mercado_pago',
    'Rede': 'rede',
  };

  bool _isMercadoPago(String plataforma) {
    return plataforma.trim().toLowerCase() == 'mercado pago';
  }

  bool _isRede(String plataforma) {
    return plataforma.trim().toLowerCase() == 'rede';
  }

  String _platformId(String plataforma) {
    final normalized = plataforma.trim().toLowerCase();

    for (final entry in _supportedPlatformIds.entries) {
      if (entry.key.toLowerCase() == normalized) {
        return entry.value;
      }
    }

    return plataforma
        .trim()
        .toLowerCase()
        .replaceAll(' ', '_')
        .replaceAll('-', '_');
  }

  Future<bool> connect(String plataforma) async {
    if (_isMercadoPago(plataforma)) {
      return _openMercadoPagoOAuth();
    }

    if (_isRede(plataforma)) {
      return isPlatformConnected(plataforma);
    }

    // Stone e PagBank continuam indisponíveis nesta fase do MVP.
    await Future.delayed(const Duration(milliseconds: 600));
    return false;
  }

  Future<bool> _openMercadoPagoOAuth() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('Usuário não autenticado no TORICO.');
    }

    final uri = Uri.parse(
      '$_backendBaseUrl/integrations/mercado-pago/connect',
    ).replace(queryParameters: {'userId': user.uid});

    final canOpen = await canLaunchUrl(uri);

    if (!canOpen) {
      throw Exception('Não foi possível abrir a autorização do Mercado Pago.');
    }

    return launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
      webOnlyWindowName: '_blank',
    );
  }

  Future<bool> isPlatformConnected(String plataforma) async {
    final integration = await getPlatformIntegration(plataforma);
    return integration?['status'] == 'connected';
  }

  Future<Map<String, dynamic>?> getPlatformIntegration(
    String plataforma,
  ) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('Usuário não autenticado no TORICO.');
    }

    final platformId = _platformId(plataforma);

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('integration_status')
        .doc(platformId)
        .get();

    if (!doc.exists) {
      return null;
    }

    return doc.data();
  }

  Future<List<String>> getConnectedPlatforms() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('Usuário não autenticado no TORICO.');
    }

    final connectedPlatforms = <String>[];
    final statusCollection = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('integration_status');

    for (final entry in _supportedPlatformIds.entries) {
      final doc = await statusCollection.doc(entry.value).get();
      final data = doc.data();

      if (doc.exists && data != null && data['status'] == 'connected') {
        connectedPlatforms.add(entry.key);
      }
    }

    return connectedPlatforms;
  }

  Future<List<String>> syncConnectedPlatformsToLocalStorage(
    LocalStorageService storage,
  ) async {
    final connectedPlatforms = await getConnectedPlatforms();
    await storage.saveConnectedPlatforms(connectedPlatforms);
    return connectedPlatforms;
  }

  String getConnectionModeLabel(String plataforma) {
    if (_isMercadoPago(plataforma)) {
      return 'Conexão real por OAuth';
    }

    if (_isRede(plataforma)) {
      return 'Conexão real por API';
    }

    return 'Integração em andamento';
  }

  String getConnectionModeDescription(String plataforma) {
    if (_isMercadoPago(plataforma)) {
      return 'O Mercado Pago será conectado usando autorização oficial. O TORICO não pede sua senha e os tokens ficam protegidos no backend.';
    }

    if (_isRede(plataforma)) {
      return 'A Rede é sincronizada pelo backend via API Gestão de Vendas. O app consulta apenas o status público da integração.';
    }

    return '$plataforma será liberada quando houver integração oficial e segura no backend.';
  }
}
