import 'package:flutter/material.dart';

import '../models/sale.dart';
import '../services/local_storage_service.dart';

class SalesController extends ChangeNotifier {
  final LocalStorageService _storage = LocalStorageService();

  double totalSold = 0.00;
  Sale? lastSale;

  Future<void> loadTotalSold() async {
    totalSold = await _storage.getTotalSold();
    notifyListeners();
  }

  Future<void> addSale(Sale sale) async {
    totalSold += sale.amount;
    lastSale = sale;

    await _storage.saveTotalSold(totalSold);

    notifyListeners();
  }

  Future<void> clearTotalSold() async {
    totalSold = 0.00;
    lastSale = null;

    await _storage.clearTotalSold();

    notifyListeners();
  }
}
