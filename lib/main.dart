import 'package:flutter/material.dart';
import 'package:matadarraja/screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext dcontext) {
    return MaterialApp(
      title: 'Matadar Raja',
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}
