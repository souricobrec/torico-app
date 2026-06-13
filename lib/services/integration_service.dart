import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class IntegrationService {
  static const String _backendBaseUrl =
      'https://torico-backend-16783123127.us-central1.run.app';

  bool _isMercadoPago(String plataforma) {
    return plataforma.trim().toLowerCase() == 'mercado pago';
  }

  String _platformId(String plataforma) {
    if (_isMercadoPago(plataforma)) {
      return 'mercado_pago';
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

    // Stone e PagBank continuam simulados nesta fase do MVP.
    await Future.delayed(const Duration(seconds: 2));
    return true;
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
    if (!_isMercadoPago(plataforma)) {
      return false;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('Usuário não autenticado no TORICO.');
    }

    final platformId = _platformId(plataforma);

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('integrations')
        .doc(platformId)
        .get();

    final data = doc.data();

    if (!doc.exists || data == null) {
      return false;
    }

    return data['status'] == 'connected';
  }

  Future<Map<String, dynamic>?> getPlatformIntegration(String plataforma) async {
    if (!_isMercadoPago(plataforma)) {
      return null;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('Usuário não autenticado no TORICO.');
    }

    final platformId = _platformId(plataforma);

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('integrations')
        .doc(platformId)
        .get();

    return doc.data();
  }

  String getConnectionModeLabel(String plataforma) {
    if (_isMercadoPago(plataforma)) {
      return 'Conexão real por OAuth';
    }

    return 'Conexão simulada';
  }

  String getConnectionModeDescription(String plataforma) {
    if (_isMercadoPago(plataforma)) {
      return 'O Mercado Pago será conectado usando autorização oficial. O TORICO não pede sua senha e os tokens ficam protegidos no backend.';
    }

    return '$plataforma será adicionada em modo de teste. Vendas reais ainda não serão recebidas automaticamente.';
  }
}
