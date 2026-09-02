import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    try {
      await Firebase.initializeApp();
    } catch (_) {}
  }
  runApp(const FixMatesWorkerApp());
}

class FixMatesWorkerApp extends StatelessWidget {
  const FixMatesWorkerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FixMates Worker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const SplashScreen(),
    );
  }
}