import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'config/api_config.dart';
import 'screens/launch_block_screen.dart';
import 'screens/splash_screen.dart';
import 'services/domain_block_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Validate build configuration before opening the app, including release.
  ApiConfig.baseUrl;

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const ToricoApp());
}

class ToricoApp extends StatelessWidget {
  const ToricoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TORICO',
      home: DomainBlockService.shouldBlock
          ? const LaunchBlockScreen()
          : const SplashScreen(),
    );
  }
}
