import 'package:flutter/foundation.dart';

class DomainBlockService {
  static const officialHostsConfig = String.fromEnvironment(
    'OFFICIAL_APP_HOSTS',
    defaultValue: 'app.meutorico.com.br',
  );
  static final Set<String> officialHosts = officialHostsConfig
      .split(',')
      .map((host) => host.trim().toLowerCase())
      .where((host) => host.isNotEmpty)
      .toSet();
  static bool isOfficialHost(String host) =>
      officialHosts.contains(host.trim().toLowerCase());
  // Bloqueio temporário usado apenas na fase pré-lojas.
  // Após publicação na Apple App Store e Google Play,
  // remover esta regra e liberar o domínio oficial normalmente.
  static const Set<String> _blockedPublicHosts = {
    'www.meutorico.com.br',
    'meutorico.com.br',
    'torico-ca479.web.app',
    'torico-ca479.firebaseapp.com',
    'app.meutorico.com.br',
  };

  static bool get shouldBlock {
    if (!kIsWeb) {
      return false;
    }

    return shouldBlockHost(Uri.base.host);
  }

  /// Official hosts must also pass the authenticated allowlist gate.
  static bool shouldBlockHost(String value) {
    final host = value.trim().toLowerCase();
    if (isOfficialHost(host)) return true;

    if (host.isEmpty) {
      return false;
    }

    // Libera testes locais.
    if (host == 'localhost' || host == '127.0.0.1' || host == '0.0.0.0') {
      return false;
    }

    // Libera canais de preview do Firebase Hosting.
    // Exemplo: torico-ca479--visual-pre-lojas-axawxjx3.web.app
    if (host.contains('--visual-pre-lojas')) {
      return false;
    }

    return _blockedPublicHosts.contains(host);
  }
}
