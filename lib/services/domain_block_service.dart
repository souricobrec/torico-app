import 'package:flutter/foundation.dart';

class DomainBlockService {
  // Bloqueio temporário usado apenas na fase pré-lojas.
  // Após publicação na Apple App Store e Google Play,
  // remover esta regra e liberar o domínio oficial normalmente.
  static const Set<String> _blockedPublicHosts = {
    'www.meutorico.com.br',
    'meutorico.com.br',
    'torico-ca479.web.app',
    'torico-ca479.firebaseapp.com',
  };

  static bool get shouldBlock {
    if (!kIsWeb) {
      return false;
    }

    final host = Uri.base.host.trim().toLowerCase();

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
