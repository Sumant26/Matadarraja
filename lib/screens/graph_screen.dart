import 'dart:async';
import 'package:flutter/material.dart';
import 'package:matadarraja/screens/booth_graph_screen.dart';
import 'package:matadarraja/screens/graph_part_Screen.dart';
import 'package:matadarraja/screens/surname_graph_screen.dart';
import 'package:matadarraja/screens/twon_graph_screen.dart';
import 'package:matadarraja/screens/age_graph_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:matadarraja/screens/chart_screen.dart';
import 'package:matadarraja/screens/home_screen.dart';

class GraphScreen extends StatefulWidget {
  final String title;

  GraphScreen({super.key, required this.title});

  @override
  State<GraphScreen> createState() => _GraphScreenState();
}

class _GraphScreenState extends State<GraphScreen> {
  Color _bgColor1 = Colors.blue;
  Color _bgColor2 = Colors.green;
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
      if (bgColor1Value != null) _bgColor1 = Color(bgColor1Value);
      if (bgColor2Value != null) _bgColor2 = Color(bgColor2Value);
      _isLoading = false;
    });
  }

  void _navigateToScreen(BuildContext context, String key) {
    if (key == 'voters_by_booth') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => BoothGraphScreen()),
      );
    } else if (key == 'voters_by_part') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => GraphPartScreen()),
      );
    } else if (key == 'voters_by_surname') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => SurnameGraphScreen()),
      );
    } else if (key == 'voters_by_town') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => TownGraphScreen()),
      );
    } else if (key == 'voters_by_age') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => AgeGraphScreen()),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ChartScreen(title: key)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> items = [
      {'key': 'voters_by_gender', 'icon': Icons.male, 'color': _bgColor1},
      {
        'key': 'voters_by_town',
        'icon': Icons.location_city,
        'color': _bgColor1,
      },
      {
        'key': 'voters_by_age',
        'icon': Icons.calendar_today,
        'color': _bgColor1,
      },
      {
        'key': 'voters_by_surname',
        'icon': Icons.family_restroom,
        'color': _bgColor1,
      },
      {
        'key': 'voters_by_part',
        'icon': Icons.format_list_numbered,
        'color': _bgColor1,
      },
      {
        'key': 'voters_by_booth',
        'icon': Icons.beach_access,
        'color': _bgColor1,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: _bgColor1,
        foregroundColor: Colors.white,
        leading: const BackButton(),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_bgColor2, _bgColor1],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: items.map((item) {
            final String key = item['key'] as String;
            final String label = languageProvider
                .getText(key)
                .replaceAll('_', ' ')
                .split(' ')
                .map(
                  (word) => word.isNotEmpty
                      ? '${word[0].toUpperCase()}${word.substring(1)}'
                      : '',
                )
                .join(' ');
            return GestureDetector(
              onTap: () => _navigateToScreen(context, key),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(item['icon'], size: 50, color: item['color']),
                    const SizedBox(height: 12),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
