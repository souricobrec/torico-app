/// Public build configuration. Never put secrets in dart defines.
class ApiConfig {
  static const environment = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'production',
  );
  static const _override = String.fromEnvironment('API_BASE_URL');
  static final baseUrl = resolve(environment, _override);

  static String resolve(String environment, String override) {
    if (!['development', 'preview', 'production'].contains(environment)) {
      throw StateError('Invalid APP_ENV.');
    }
    final value = override.isNotEmpty
        ? override
        : environment == 'production'
        ? 'https://api.meutorico.com.br'
        : environment == 'development'
        ? 'http://localhost:3333'
        : throw StateError('Preview requires API_BASE_URL.');
    final uri = Uri.tryParse(value);
    if (uri == null ||
        !uri.hasAuthority ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        (uri.path.isNotEmpty && uri.path != '/') ||
        !['http', 'https'].contains(uri.scheme)) {
      throw StateError(
        'Invalid API_BASE_URL; use an origin without credentials.',
      );
    }
    final local = [
      'localhost',
      '127.0.0.1',
      '0.0.0.0',
      '[::1]',
      '::1',
    ].contains(uri.host.toLowerCase());
    if (environment != 'development' && (uri.scheme != 'https' || local)) {
      throw StateError('Preview and production require a remote HTTPS API.');
    }
    return uri.replace(path: '').toString();
  }
}
