import 'dart:async';

import 'package:flutter/material.dart';

import '../models/sale.dart';
import '../services/firestore_sales_service.dart';
import '../services/local_storage_service.dart';

class SalesController extends ChangeNotifier {
  final LocalStorageService _storage = LocalStorageService();
  final FirestoreSalesService _firestoreSalesService = FirestoreSalesService();

  StreamSubscription<double>? _todayTotalSubscription;

  double totalSold = 0.00;
  Sale? lastSale;
  bool usingCloud = false;

  Future<void> loadTotalSold() async {
    try {
      totalSold = await _firestoreSalesService.getTodayTotal();
      usingCloud = true;

      await _storage.saveTotalSold(totalSold);
    } catch (_) {
      totalSold = await _storage.getTotalSold();
      usingCloud = false;
    }

    notifyListeners();
  }

  void startWatchingTodayTotal() {
    _todayTotalSubscription?.cancel();

    _todayTotalSubscription = _firestoreSalesService.watchTodayTotal().listen(
      (total) async {
        totalSold = total;
        usingCloud = true;

        await _storage.saveTotalSold(totalSold);

        notifyListeners();
      },
      onError: (_) async {
        totalSold = await _storage.getTotalSold();
        usingCloud = false;

        notifyListeners();
      },
    );
  }

  Future<void> addSale(
    Sale sale, {
    required String plataforma,
  }) async {
    lastSale = sale;

    try {
      await _firestoreSalesService.addSale(
        sale: sale,
        plataforma: plataforma,
      );

      totalSold = await _firestoreSalesService.getTodayTotal();
      usingCloud = true;

      await _storage.saveTotalSold(totalSold);
    } catch (_) {
      totalSold += sale.amount;
      usingCloud = false;

      await _storage.saveTotalSold(totalSold);
    }

    notifyListeners();
  }

  Future<void> clearTotalSold() async {
    totalSold = 0.00;
    lastSale = null;

    await _storage.clearTotalSold();

    notifyListeners();
  }

  @override
  void dispose() {
    _todayTotalSubscription?.cancel();
    super.dispose();
  }
}
