import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/sale.dart';

class ToricoSaleRecord {
  final String id;
  final double amount;
  final String platform;
  final String platformId;
  final String status;
  final String source;
  final String dateKey;
  final String? externalId;
  final Map<String, dynamic>? rawPayload;
  final DateTime? createdAt;

  const ToricoSaleRecord({
    required this.id,
    required this.amount,
    required this.platform,
    required this.platformId,
    required this.status,
    required this.source,
    required this.dateKey,
    required this.externalId,
    required this.rawPayload,
    required this.createdAt,
  });

  factory ToricoSaleRecord.fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();

    DateTime? createdAt;

    final createdAtClient = data['createdAtClient'];
    final createdAtServer = data['createdAtServer'];

    if (createdAtClient is Timestamp) {
      createdAt = createdAtClient.toDate();
    } else if (createdAtServer is Timestamp) {
      createdAt = createdAtServer.toDate();
    }

    final amount = data['amount'];
    final rawPayload = data['rawPayload'];

    return ToricoSaleRecord(
      id: doc.id,
      amount: amount is num ? amount.toDouble() : 0.0,
      platform: (data['platform'] ?? 'Simulador').toString(),
      platformId: (data['platformId'] ?? 'simulator').toString(),
      status: (data['status'] ?? 'approved').toString(),
      source: (data['source'] ?? 'simulator').toString(),
      dateKey: (data['dateKey'] ?? '').toString(),
      externalId: data['externalId']?.toString(),
      rawPayload: rawPayload is Map<String, dynamic> ? rawPayload : null,
      createdAt: createdAt,
    );
  }
}

class PlatformSalesSummary {
  final String platform;
  final String platformId;
  final double totalSold;
  final int salesCount;

  const PlatformSalesSummary({
    required this.platform,
    required this.platformId,
    required this.totalSold,
    required this.salesCount,
  });

  factory PlatformSalesSummary.fromMap(
    String platformId,
    Map<String, dynamic> data,
  ) {
    final totalSold = data['totalSold'];
    final salesCount = data['salesCount'];

    return PlatformSalesSummary(
      platform: (data['platform'] ?? platformId).toString(),
      platformId: (data['platformId'] ?? platformId).toString(),
      totalSold: totalSold is num ? totalSold.toDouble() : 0.0,
      salesCount: salesCount is num ? salesCount.toInt() : 0,
    );
  }
}

class DailySalesSummary {
  final String dateKey;
  final double totalSold;
  final int salesCount;
  final Map<String, PlatformSalesSummary> platforms;
  final DateTime? lastSaleAt;

  const DailySalesSummary({
    required this.dateKey,
    required this.totalSold,
    required this.salesCount,
    required this.platforms,
    required this.lastSaleAt,
  });

  factory DailySalesSummary.empty(String dateKey) {
    return DailySalesSummary(
      dateKey: dateKey,
      totalSold: 0,
      salesCount: 0,
      platforms: const {},
      lastSaleAt: null,
    );
  }

  factory DailySalesSummary.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
    String dateKey,
  ) {
    if (!doc.exists) {
      return DailySalesSummary.empty(dateKey);
    }

    final data = doc.data() ?? <String, dynamic>{};
    final totalSold = data['totalSold'];
    final salesCount = data['salesCount'];
    final lastSaleAtValue = data['lastSaleAt'];
    final platformsData = data['platforms'];

    final platforms = <String, PlatformSalesSummary>{};

    if (platformsData is Map<String, dynamic>) {
      for (final entry in platformsData.entries) {
        final value = entry.value;

        if (value is Map<String, dynamic>) {
          platforms[entry.key] = PlatformSalesSummary.fromMap(entry.key, value);
        }
      }
    }

    return DailySalesSummary(
      dateKey: (data['dateKey'] ?? dateKey).toString(),
      totalSold: totalSold is num ? totalSold.toDouble() : 0.0,
      salesCount: salesCount is num ? salesCount.toInt() : 0,
      platforms: platforms,
      lastSaleAt: lastSaleAtValue is Timestamp
          ? lastSaleAtValue.toDate()
          : null,
    );
  }
}

class FirestoreSalesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _userId {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Usuário não autenticado.');
    }

    return user.uid;
  }

  DocumentReference<Map<String, dynamic>> get _userDocument {
    return _firestore.collection('users').doc(_userId);
  }

  CollectionReference<Map<String, dynamic>> get _salesCollection {
    return _userDocument.collection('sales');
  }

  DocumentReference<Map<String, dynamic>> _dailyTotalDocument(String dateKey) {
    return _userDocument.collection('daily_totals').doc(dateKey);
  }

  String _todayKey() {
    return _dateKeyFromDate(DateTime.now());
  }

  String _dateKeyFromDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  String platformIdFromName(String platform) {
    final normalized = platform.trim().toLowerCase();

    if (normalized.contains('mercado')) {
      return 'mercado_pago';
    }

    if (normalized.contains('stone')) {
      return 'stone';
    }

    if (normalized.contains('pagbank') || normalized.contains('pag bank')) {
      return 'pagbank';
    }

    if (normalized.isEmpty) {
      return 'simulator';
    }

    return normalized
        .replaceAll('ã', 'a')
        .replaceAll('á', 'a')
        .replaceAll('à', 'a')
        .replaceAll('â', 'a')
        .replaceAll('é', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ç', 'c')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  Future<void> addSale({required Sale sale, required String plataforma}) async {
    final platformId = platformIdFromName(plataforma);
    final saleDate = sale.createdAt;
    final dateKey = _dateKeyFromDate(saleDate);

    await _salesCollection.add({
      'amount': sale.amount,
      'platform': plataforma,
      'platformId': platformId,
      'status': sale.status,
      'source': sale.source,
      'externalId': sale.externalId,
      'rawPayload': sale.rawPayload ?? <String, dynamic>{},
      'dateKey': dateKey,
      'createdAtClient': Timestamp.fromDate(saleDate),
      'createdAtServer': FieldValue.serverTimestamp(),
    });
  }

  /// Estrutura preparada para uso futuro por venda real recebida via webhook.
  ///
  /// Em produção, as vendas reais são gravadas pelo backend/Cloud Run.
  /// O app não deve gravar vendas diretamente no Firestore.
  Future<void> addWebhookSale({
    required double amount,
    required String platform,
    required String externalId,
    String status = 'approved',
    DateTime? createdAt,
    Map<String, dynamic>? rawPayload,
  }) async {
    final saleDate = createdAt ?? DateTime.now();
    final platformId = platformIdFromName(platform);

    await _salesCollection.doc(externalId).set({
      'amount': amount,
      'platform': platform,
      'platformId': platformId,
      'status': status,
      'source': 'webhook',
      'externalId': externalId,
      'rawPayload': rawPayload ?? <String, dynamic>{},
      'dateKey': _dateKeyFromDate(saleDate),
      'createdAtClient': Timestamp.fromDate(saleDate),
      'createdAtServer': FieldValue.serverTimestamp(),
    });
  }

  Future<double> getTodayTotal() async {
    final todayKey = _todayKey();
    final summarySnapshot = await _dailyTotalDocument(todayKey).get();

    if (summarySnapshot.exists) {
      final data = summarySnapshot.data() ?? <String, dynamic>{};
      final totalSold = data['totalSold'];
      return totalSold is num ? totalSold.toDouble() : 0.0;
    }

    // Fallback temporário para vendas antigas criadas antes de daily_totals.
    // Depois que o backend estiver atualizado, o painel usará só daily_totals.
    final snapshot = await _salesCollection
        .where('dateKey', isEqualTo: todayKey)
        .where('status', isEqualTo: 'approved')
        .get();

    return _sumSnapshot(snapshot);
  }

  Stream<DailySalesSummary> watchTodaySummary() {
    final todayKey = _todayKey();

    return _dailyTotalDocument(todayKey).snapshots().map(
          (snapshot) => DailySalesSummary.fromDoc(snapshot, todayKey),
        );
  }

  Stream<double> watchTodayTotal() {
    final todayKey = _todayKey();

    return _dailyTotalDocument(todayKey).snapshots().asyncExpand((snapshot) {
      if (snapshot.exists) {
        final summary = DailySalesSummary.fromDoc(snapshot, todayKey);
        return Stream<double>.value(summary.totalSold);
      }

      // Fallback temporário para manter compatibilidade com vendas antigas.
      return _salesCollection
          .where('dateKey', isEqualTo: todayKey)
          .where('status', isEqualTo: 'approved')
          .snapshots()
          .map(_sumSnapshot);
    });
  }

  Stream<List<ToricoSaleRecord>> watchTodaySales({
    String? platform,
    int limit = 10,
  }) {
    Query<Map<String, dynamic>> query = _salesCollection
        .where('dateKey', isEqualTo: _todayKey())
        .where('status', isEqualTo: 'approved');

    if (platform != null && platform.trim().isNotEmpty) {
      query = query.where(
        'platformId',
        isEqualTo: platformIdFromName(platform),
      );
    }

    return query
        .orderBy('createdAtClient', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(ToricoSaleRecord.fromDoc).toList());
  }

  double _sumSnapshot(QuerySnapshot<Map<String, dynamic>> snapshot) {
    double total = 0.0;

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final amount = data['amount'];

      if (amount is num) {
        total += amount.toDouble();
      }
    }

    return total;
  }
}
