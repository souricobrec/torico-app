import 'firestore_sales_service.dart';

/// Initial snapshots are history; only unseen approved Mercado Pago records
/// after that baseline can produce a notification during this session.
class NewSaleTracker {
  final Set<String> _seen = {};
  bool _initialized = false;

  bool observe(List<ToricoSaleRecord> sales) {
    var notify = false;
    for (final sale in sales) {
      if (sale.status != 'approved') continue;
      final key = sale.externalId ?? sale.id;
      final fresh = _seen.add(key);
      if (_initialized &&
          fresh &&
          sale.status == 'approved' &&
          sale.platformId == 'mercado_pago' &&
          sale.source == 'webhook') {
        notify = true;
      }
    }
    _initialized = true;
    return notify;
  }
}
