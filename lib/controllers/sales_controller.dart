import 'package:flutter/material.dart';

import '../models/sale.dart';

class SalesController extends ChangeNotifier {
  double totalSold = 0.00;
  Sale? lastSale;

  void addSale(Sale sale) {
    totalSold += sale.amount;
    lastSale = sale;

    notifyListeners();
  }
}
