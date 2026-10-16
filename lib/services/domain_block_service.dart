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
  static bool get shouldBlock {
    if (!kIsWeb) {
      // Native apps must use the same authenticated rollout gate as official web.
      return true;
    }

    return shouldBlockHost(Uri.base.host);
  }

  /// Official hosts must also pass the authenticated allowlist gate.
  static bool shouldBlockHost(String value) {
    // Host names are routing information, never an authentication bypass.
    return true;
  }
}
