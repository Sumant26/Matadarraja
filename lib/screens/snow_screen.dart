import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SnowScreen extends StatefulWidget {
  final String title;
  const SnowScreen({super.key, required this.title});

  @override
  State<SnowScreen> createState() => _SnowScreenState();
}

class _SnowScreenState extends State<SnowScreen> {
  Color _bgColor1 = Colors.blue;
  // default if not in prefs
  Color _bgColor2 = Colors.green;
  // default if not in prefs
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadColorsFromPrefs();
  }

  Future<void> _loadColorsFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final bgColor1Value = prefs.getInt('bgColor1');
    final bgColor2Value = prefs.getInt('bgColor2');

    setState(() {
      if (bgColor1Value != null) {
        _bgColor1 = Color(bgColor1Value);
      }
      if (bgColor2Value != null) {
        _bgColor2 = Color(bgColor2Value);
      }
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: _bgColor1,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_bgColor2, _bgColor1],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.lightBlue,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: const Icon(
                  Icons.ac_unit,
                  size: 100,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Welcome to ${widget.title}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Experience the magic of winter',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
