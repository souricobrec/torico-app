import 'package:flutter/material.dart';

/// Reuses the approved complete artwork; launcher assets are unchanged.
class ToricoPanelBrand extends StatelessWidget {
  const ToricoPanelBrand({super.key});
  @override
  Widget build(BuildContext context) {
    final width = (MediaQuery.sizeOf(context).width * .56).clamp(180.0, 240.0);
    return Image.asset(
      'assets/images/torico_logo.png',
      width: width,
      height: width / 3,
      fit: BoxFit.contain,
      semanticLabel: 'TORICO',
    );
  }
}
