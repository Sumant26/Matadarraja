import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DesertScreen extends StatefulWidget {
  final String title;
  const DesertScreen({super.key, required this.title});

  @override
  State<DesertScreen> createState() => _DesertScreenState();
}

class _DesertScreenState extends State<DesertScreen> {
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
          child: Card(
            elevation: 4,
            color: Colors.white,
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Replace with your actual image path or remove if not needed
                    Image.asset(
                      "assets/icons/matadarrajalogo.jpeg",
                      height: 100,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      '''About SOA Technologies
        
        SOA Technologies stands for innovation, accuracy, and a strong sense of purpose. To bridge the gap between technology and everyday needs, our three founders started this company not just as a business, but as a mission — to create useful and impactful tech solutions based on customer needs.
        
        At SOA, we believe that technology is not just about writing code, but about creating real value. Our solutions are developed with expert knowledge and an understanding of what users really need, so that each project can make a positive difference in society:
         • Education: Supporting digital learning and smart institutions
         • Politics: Improving communication with the public and making data-based decisions
         • Business: Making work processes easier and helping businesses grow through digital tools
         • Society: Using technology to build impactful social projects
         • Construction and Infrastructure: Creating smart, safe, and efficient plans
         • Farming: Promoting smart farming through the use of technology, data, and useful information
        
        Our work is based on the principles of Service-Oriented Architecture (SOA). This helps us build systems that are scalable, flexible, and ready for future needs. Focusing on customer needs and satisfaction is our top priority.
        
        SOA Technologies — Where Solutions Meet Purpose.''',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
