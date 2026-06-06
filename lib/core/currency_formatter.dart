class CurrencyFormatter {
  static String format(double value) {
    final fixed = value.toStringAsFixed(2);

    final parts = fixed.split('.');
    final integerPart = parts[0];
    final decimalPart = parts[1];

    final buffer = StringBuffer();

    for (int i = 0; i < integerPart.length; i++) {
      final positionFromEnd = integerPart.length - i;

      buffer.write(integerPart[i]);

      if (positionFromEnd > 1 && positionFromEnd % 3 == 1) {
        buffer.write('.');
      }
    }

    return 'R\$ ${buffer.toString()},$decimalPart';
  }
}
