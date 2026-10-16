import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'local_storage_service.dart';
import '../config/api_config.dart';
import 'mercado_pago_oauth_launcher.dart';

class IntegrationService {
  static final String _backendBaseUrl = ApiConfig.baseUrl;

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

  Uri? _preparedMercadoPago;
  String? _preparedUid;
  DateTime? _preparedAt;
  bool get hasPreparedMercadoPago => _preparedMercadoPago != null;
  Future<bool> openPreparedMercadoPago() {
    final uri = _preparedMercadoPago;
    if (_preparedUid != FirebaseAuth.instance.currentUser?.uid ||
        _preparedAt == null ||
        DateTime.now().difference(_preparedAt!).inMinutes >= 9) {
      _preparedMercadoPago = null;
      throw Exception('Autorização expirada. Inicie a conexão novamente.');
    }
    _preparedMercadoPago = null;
    if (uri == null) return Future.value(false);
    return MercadoPagoOAuthLauncher().open(uri);
  }

  Future<bool> _openMercadoPagoOAuth() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('Usuário não autenticado no TORICO.');
    }

    final token = await user.getIdToken();
    if (token == null) throw Exception('Entre novamente no TORICO.');
    final launcher = MercadoPagoOAuthLauncher(apiBaseUrl: _backendBaseUrl);
    final uri = await launcher.prepare(token);
    if (FirebaseAuth.instance.currentUser?.uid != user.uid) {
      throw Exception('A sessão mudou. Inicie a conexão novamente.');
    }
    _preparedUid = user.uid;
    _preparedAt = DateTime.now();
    _preparedMercadoPago = uri;
    return false;
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
        .get(const GetOptions(source: Source.server));

    if (FirebaseAuth.instance.currentUser?.uid != user.uid) {
      throw Exception('A sessão mudou.');
    }
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
      final doc = await statusCollection
          .doc(entry.value)
          .get(const GetOptions(source: Source.server));
      final data = doc.data();

      if (doc.exists && data != null && data['status'] == 'connected') {
        connectedPlatforms.add(entry.key);
      }
    }

    if (FirebaseAuth.instance.currentUser?.uid != user.uid) {
      throw Exception('A sessão mudou.');
    }
    return connectedPlatforms;
  }

  Future<List<String>> syncConnectedPlatformsToLocalStorage(
    LocalStorageService storage,
  ) async {
    final connectedPlatforms = await getConnectedPlatforms();
    if (!storage.isCurrentSession) throw Exception('A sessão mudou.');
    await storage.saveConnectedPlatforms(connectedPlatforms);
    return connectedPlatforms;
  }

  String getConnectionModeLabel(String plataforma) {
    if (_isMercadoPago(plataforma)) {
      return 'Conexão real por OAuth';
    }

    if (_isRede(plataforma)) {
      return 'Ativação assistida';
    }

    return 'Integração em andamento';
  }

  String getConnectionModeDescription(String plataforma) {
    if (_isMercadoPago(plataforma)) {
      return 'O Mercado Pago será conectado usando autorização oficial. O TORICO não pede sua senha e os tokens ficam protegidos no backend.';
    }

    if (_isRede(plataforma)) {
      return 'A Rede é ativada de forma assistida e sincronizada pelo backend via API Gestão de Vendas. O app consulta apenas o status público da integração.';
    }

    return '$plataforma será liberada quando houver integração oficial e segura no backend.';
  }
}
