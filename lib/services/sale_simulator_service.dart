import 'dart:math';

import '../models/sale.dart';

class SaleSimulatorService {
  static final List<double> _valores = [
    7.00,
    10.00,
    15.00,
    18.00,
    22.00,
    25.00,
    30.00,
    35.00,
    42.00,
    50.00,
    67.00,
    89.90,
    120.00,
  ];

  static Sale generateSale() {
    final random = Random();

    final valorVenda = _valores[random.nextInt(_valores.length)];

    return Sale(amount: valorVenda, createdAt: DateTime.now());
  }
}
