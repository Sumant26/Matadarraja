import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:matadarraja/screens/authorization_screen.dart';
import 'package:matadarraja/screens/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool("isLoggedIn") ?? false;
    print("🔑 Logged In Flag: $isLoggedIn");

    String? storedCandidateData = prefs.getString("candidateData");
    Map<String, dynamic> candidateData = {};

    if (storedCandidateData != null && storedCandidateData.isNotEmpty) {
      try {
        candidateData = jsonDecode(storedCandidateData);
        print("📦 Loaded Candidate Data: $candidateData");
      } catch (e) {
        print("❌ Error decoding candidateData: $e");
      }
    } else {
      print("⚠️ No candidateData found, using empty map.");
    }

    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;

      if (isLoggedIn) {
        print("➡️ Navigating to HomeScreen with data: $candidateData");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => HomeScreen()),
        );
      } else {
        print("➡️ Navigating to AuthorizationScreen");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AuthorizationScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Color(0xFFFB8C00), // start color
              Color(0xFFF4511E), // end color
            ],
          ),
        ),
        child: Center(
          child: TweenAnimationBuilder(
            tween: Tween<double>(begin: 1.0, end: 1.3),
            duration: const Duration(seconds: 2),
            builder: (context, scale, child) {
              return Transform.scale(scale: scale, child: child);
            },
            child: Image.asset(
              "assets/icons/soalogowhite.png",
              width: 500,
              height: 500,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
