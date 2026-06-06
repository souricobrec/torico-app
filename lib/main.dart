import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const ToricoApp());
}

class ToricoApp extends StatelessWidget {
  const ToricoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TORICO',
      home: const LoginScreen(),
    );
  }
}
