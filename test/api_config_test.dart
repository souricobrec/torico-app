import 'package:flutter_test/flutter_test.dart';
import 'package:torico/config/api_config.dart';

void main() {
  test('production defaults to the official domain', () {
    expect(ApiConfig.resolve('production', ''), 'https://api.meutorico.com.br');
  });
  test('development allows local API and preview requires explicit API', () {
    expect(ApiConfig.resolve('development', ''), 'http://localhost:3333');
    expect(() => ApiConfig.resolve('preview', ''), throwsStateError);
    expect(
      ApiConfig.resolve('preview', 'https://preview.example.com/'),
      'https://preview.example.com',
    );
  });
  test('rejects unsafe configuration in release as well', () {
    for (final env in ['preview', 'production']) {
      for (final url in [
        'http://api.example.com',
        'https://localhost',
        'https://127.0.0.1',
        'https://[::1]',
        'https://user:password@api.example.com',
        'https://api.example.com?token=secret',
        'https://api.example.com#fragment',
        'https://api.example.com/path',
      ]) {
        expect(() => ApiConfig.resolve(env, url), throwsStateError);
      }
    }
    expect(() => ApiConfig.resolve('unknown', ''), throwsStateError);
  });
}
