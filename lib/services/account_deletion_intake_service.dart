import 'dart:convert';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class DeletionIntakeException implements Exception {
  final String code;
  const DeletionIntakeException(this.code);
}

class DeletionRequestStatus {
  final String requestId, protocol, status;
  final DateTime receivedAt;
  const DeletionRequestStatus(
    this.requestId,
    this.protocol,
    this.status,
    this.receivedAt,
  );
  static DeletionRequestStatus parse(String body) {
    final data = jsonDecode(body) as Map<String, dynamic>;
    if (data['ok'] != true ||
        data['requestId'] is! String ||
        data['protocol'] is! String ||
        ![
          'received',
          'verifying',
          'processing',
          'completed',
          'rejected',
        ].contains(data['status']) ||
        (data['status'] == 'completed' && data['completedAt'] == null)) {
      throw const DeletionIntakeException('invalid_response');
    }
    return DeletionRequestStatus(
      data['requestId'],
      data['protocol'],
      data['status'],
      DateTime.parse(data['receivedAt']),
    );
  }

  String get label => switch (status) {
    'received' => 'Recebido',
    'verifying' => 'Em verificação',
    'processing' => 'Em processamento',
    'completed' => 'Concluído conforme informação do servidor',
    'rejected' => 'Rejeitado — consulte o atendimento',
    _ => 'Indisponível',
  };
}

class AccountDeletionIntakeService {
  static const configuredEnabled = bool.fromEnvironment(
    'ACCOUNT_DELETION_INTAKE_ENABLED',
    defaultValue: false,
  );
  static const noticeVersion = 'intake-review-v1';
  final bool enabled;
  final http.Client? client;
  final String? baseUrl;
  final String? Function()? uidLoader;
  final Future<String?> Function()? tokenLoader;
  AccountDeletionIntakeService({
    this.enabled = configuredEnabled,
    this.client,
    this.baseUrl,
    this.uidLoader,
    this.tokenLoader,
  });
  String? _uid() =>
      uidLoader != null ? uidLoader!() : FirebaseAuth.instance.currentUser?.uid;
  Future<DeletionRequestStatus?> current() => _request(false);
  Future<DeletionRequestStatus> submit() async => (await _request(true))!;
  Future<DeletionRequestStatus?> _request(bool submit) async {
    if (!enabled) throw const DeletionIntakeException('feature_disabled');
    final uid = _uid();
    if (uid == null) {
      throw const DeletionIntakeException('authentication_required');
    }
    final token = await (tokenLoader != null
        ? tokenLoader!()
        : FirebaseAuth.instance.currentUser!.getIdToken(true));
    if (token == null || uid != _uid()) {
      throw const DeletionIntakeException('session_changed');
    }
    final headers = {'Authorization': 'Bearer $token'};
    String? body;
    if (submit) {
      // Non-secret idempotency key, persisted before POST; never a status receipt.
      final prefs = await SharedPreferences.getInstance();
      final slot =
          'torico_deletion_intake_key_${base64Url.encode(utf8.encode(uid))}';
      var key = prefs.getString(slot);
      if (key == null) {
        final random = Random.secure();
        key = base64Url
            .encode(List<int>.generate(32, (_) => random.nextInt(256)))
            .replaceAll('=', '');
        if (!await prefs.setString(slot, key)) {
          throw const DeletionIntakeException('local_storage_unavailable');
        }
      }
      headers['Idempotency-Key'] = key;
      headers['Content-Type'] = 'application/json';
      body = jsonEncode({
        'confirmation': 'delete_account',
        'noticeVersion': noticeVersion,
        'policyVersion': noticeVersion,
      });
    }
    if (uid != _uid()) throw const DeletionIntakeException('session_changed');
    final transport = client ?? http.Client();
    try {
      final uri = Uri.parse(
        '${baseUrl ?? ApiConfig.baseUrl}/v1/account-deletion/requests${submit ? '' : '/current'}',
      );
      final response =
          await (submit
                  ? transport.post(uri, headers: headers, body: body)
                  : transport.get(uri, headers: headers))
              .timeout(const Duration(seconds: 20));
      if (uid != _uid()) throw const DeletionIntakeException('session_changed');
      if (!submit && response.statusCode == 404) {
        final data = jsonDecode(response.body);
        if (data['code'] == 'request_not_found') return null;
      }
      if (response.statusCode != (submit ? 202 : 200)) {
        String code = 'service_unavailable';
        try {
          code = (jsonDecode(response.body)['code'] as String?) ?? code;
        } catch (_) {
          /* No untrusted body shown. */
        }
        throw DeletionIntakeException(code);
      }
      return DeletionRequestStatus.parse(response.body);
    } finally {
      if (client == null) transport.close();
    }
  }
}
