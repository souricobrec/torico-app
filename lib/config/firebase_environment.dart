import 'package:firebase_core/firebase_core.dart';

/// Non-production builds must explicitly use a demo project and both emulators.
class FirebaseEnvironment {
  static FirebaseOptions resolve({
    required String environment,
    required String project,
    required String emulatorHost,
    required String apiBaseUrl,
    required FirebaseOptions production,
  }) {
    if (environment == 'production') {
      if (project.isNotEmpty || emulatorHost.isNotEmpty) {
        throw StateError('Production cannot use demo/emulator overrides.');
      }
      return production;
    }
    final api = Uri.parse(apiBaseUrl);
    if (!['development', 'preview'].contains(environment) ||
        !RegExp(r'^demo-[a-z0-9-]+$').hasMatch(project) ||
        !['127.0.0.1', 'localhost', '10.0.2.2'].contains(emulatorHost) ||
        api.scheme != 'http' ||
        api.host != emulatorHost) {
      throw StateError(
        'Non-production requires demo-* Firebase and local emulators/API.',
      );
    }
    return FirebaseOptions(
      apiKey: 'demo-only-key',
      appId: '1:123:android:demo',
      messagingSenderId: '123',
      projectId: project,
    );
  }
}
