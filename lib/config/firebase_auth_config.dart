import 'package:firebase_core/firebase_core.dart';
import '../services/domain_block_service.dart';

/// Selects the Auth helper domain only on official web hosts.
class FirebaseAuthConfig {
  static const configuredDomain = String.fromEnvironment(
    'FIREBASE_AUTH_DOMAIN',
  );

  static FirebaseOptions resolveWebOptions(
    FirebaseOptions options,
    Uri uri, {
    String authDomain = configuredDomain,
  }) {
    if (!DomainBlockService.isOfficialHost(uri.host)) return options;
    final domain = authDomain.trim().isEmpty
        ? uri.host.toLowerCase()
        : authDomain.trim().toLowerCase();
    final parsed = Uri.tryParse('https://$domain');
    if (parsed == null ||
        parsed.host != domain ||
        parsed.hasPort ||
        parsed.userInfo.isNotEmpty ||
        parsed.path.isNotEmpty ||
        parsed.hasQuery ||
        parsed.hasFragment ||
        !DomainBlockService.isOfficialHost(domain)) {
      throw ArgumentError(
        'FIREBASE_AUTH_DOMAIN deve ser um host oficial, sem URL ou caminho.',
      );
    }
    return options.copyWith(authDomain: domain);
  }
}
