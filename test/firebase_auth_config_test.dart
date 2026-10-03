import 'package:flutter_test/flutter_test.dart';
import 'package:torico/config/firebase_auth_config.dart';
import 'package:torico/firebase_options.dart';

void main() {
  test('official host uses its own authDomain and keeps project identity', () {
    final original = DefaultFirebaseOptions.web;
    final resolved = FirebaseAuthConfig.resolveWebOptions(
      original,
      Uri.parse('https://app.meutorico.com.br'),
      authDomain: '',
    );
    expect(resolved.authDomain, 'app.meutorico.com.br');
    expect(resolved.asMap, {
      ...original.asMap,
      'authDomain': 'app.meutorico.com.br',
    });
  });

  test('official define never changes technical, preview or local hosts', () {
    for (final host in [
      'torico-ca479.web.app',
      'torico-ca479.firebaseapp.com',
      'torico-ca479--visual-pre-lojas-example.web.app',
      'localhost',
      'app.meutorico.com.br.example.com',
    ]) {
      for (final query in ['', '?pilot=1']) {
        expect(
          FirebaseAuthConfig.resolveWebOptions(
            DefaultFirebaseOptions.web,
            Uri.parse('https://$host/$query'),
            authDomain: 'app.meutorico.com.br',
          ),
          same(DefaultFirebaseOptions.web),
        );
      }
    }
  });

  test(
    'official define accepts hostname and rejects URLs and unapproved hosts',
    () {
      final uri = Uri.parse('https://app.meutorico.com.br/?pilot=1');
      expect(
        FirebaseAuthConfig.resolveWebOptions(
          DefaultFirebaseOptions.web,
          uri,
          authDomain: 'app.meutorico.com.br',
        ).authDomain,
        'app.meutorico.com.br',
      );
      for (final domain in [
        'https://app.meutorico.com.br',
        'app.meutorico.com.br/path',
        'app.meutorico.com.br:443',
        'other.example.com',
      ]) {
        expect(
          () => FirebaseAuthConfig.resolveWebOptions(
            DefaultFirebaseOptions.web,
            uri,
            authDomain: domain,
          ),
          throwsArgumentError,
        );
      }
    },
  );
}
