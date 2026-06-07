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

  CollectionReference<Map<String, dynamic>> get _salesCollection {
    return _firestore.collection('users').doc(_userId).collection('sales');
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

    await _salesCollection.add({
      'amount': sale.amount,
      'platform': plataforma,
      'platformId': platformId,
      'status': sale.status,
      'source': sale.source,
      'externalId': sale.externalId,
      'rawPayload': sale.rawPayload ?? <String, dynamic>{},
      'dateKey': _dateKeyFromDate(sale.createdAt),
      'createdAtClient': Timestamp.fromDate(sale.createdAt),
      'createdAtServer': FieldValue.serverTimestamp(),
    });
  }

  /// Estrutura preparada para uso futuro por venda real recebida via webhook.
  ///
  /// Hoje ainda não temos endpoint/backend chamando este método.
  /// Ele deixa o padrão de dados pronto para Mercado Pago, Stone, PagBank etc.
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

    await _salesCollection.add({
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
    final snapshot = await _salesCollection
        .where('dateKey', isEqualTo: _todayKey())
        .where('status', isEqualTo: 'approved')
        .get();

    return _sumSnapshot(snapshot);
  }

  Stream<double> watchTodayTotal() {
    return _salesCollection
        .where('dateKey', isEqualTo: _todayKey())
        .where('status', isEqualTo: 'approved')
        .snapshots()
        .map(_sumSnapshot);
  }

  Stream<List<ToricoSaleRecord>> watchTodaySales() {
    return _salesCollection
        .where('dateKey', isEqualTo: _todayKey())
        .where('status', isEqualTo: 'approved')
        .snapshots()
        .map((snapshot) {
          final sales = snapshot.docs.map(ToricoSaleRecord.fromDoc).toList();

          sales.sort((a, b) {
            final dateA = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final dateB = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);

            return dateB.compareTo(dateA);
          });

          return sales;
        });
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
