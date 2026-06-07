import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/sale.dart';

class ToricoSaleRecord {
  final String id;
  final double amount;
  final String platform;
  final String status;
  final String source;
  final String dateKey;
  final DateTime? createdAt;

  const ToricoSaleRecord({
    required this.id,
    required this.amount,
    required this.platform,
    required this.status,
    required this.source,
    required this.dateKey,
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

    return ToricoSaleRecord(
      id: doc.id,
      amount: amount is num ? amount.toDouble() : 0.0,
      platform: (data['platform'] ?? 'Simulador').toString(),
      status: (data['status'] ?? 'approved').toString(),
      source: (data['source'] ?? 'simulator').toString(),
      dateKey: (data['dateKey'] ?? '').toString(),
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
    final now = DateTime.now();

    final year = now.year.toString().padLeft(4, '0');
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  Future<void> addSale({
    required Sale sale,
    required String plataforma,
  }) async {
    final now = DateTime.now();

    await _salesCollection.add({
      'amount': sale.amount,
      'platform': plataforma,
      'platformId': plataforma.toLowerCase().replaceAll(' ', '_'),
      'status': 'approved',
      'source': 'simulator',
      'dateKey': _todayKey(),
      'createdAtClient': Timestamp.fromDate(now),
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
