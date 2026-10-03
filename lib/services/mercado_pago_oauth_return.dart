import 'oauth_return_url_stub.dart'
    if (dart.library.js_interop) 'oauth_return_url_web.dart';

/// URL status is a navigation hint, never proof of an authorized integration.
class MercadoPagoOAuthReturn {
  final bool reportedConnected;
  const MercadoPagoOAuthReturn({required this.reportedConnected});

  static MercadoPagoOAuthReturn? parse(Uri uri) {
    final integration = uri.queryParametersAll['integration'];
    final status = uri.queryParametersAll['status'];
    if (integration?.length != 1 ||
        integration!.single != 'mercado_pago' ||
        status?.length != 1 ||
        !['connected', 'error'].contains(status!.single)) {
      return null;
    }
    return MercadoPagoOAuthReturn(
      reportedConnected: status.single == 'connected',
    );
  }

  static Uri cleanedUrl(Uri uri) {
    final query = Map<String, List<String>>.from(uri.queryParametersAll)
      ..remove('integration')
      ..remove('status');
    return Uri(
      scheme: uri.scheme,
      userInfo: uri.userInfo,
      host: uri.host,
      port: uri.hasPort ? uri.port : null,
      path: uri.path,
      queryParameters: query.isEmpty ? null : query,
      fragment: uri.hasFragment ? uri.fragment : null,
    );
  }

  static void clearUrl(Uri uri) {
    try {
      replaceOAuthReturnUrl(cleanedUrl(uri));
    } catch (_) {
      // Navigation and status verification still work if History API is blocked.
    }
  }
}
