import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:matadarraja/screens/age_voter_list_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';

class AgeGraphScreen extends StatefulWidget {
  const AgeGraphScreen({super.key});

  @override
  State<AgeGraphScreen> createState() => _AgeGraphScreenState();
}

class _AgeGraphScreenState extends State<AgeGraphScreen> {
  List<dynamic> _ageGroups = [];
  int _pageIndex = 0;
  final int _pageSize = 10;
  bool _isLoading = true;
  bool _hasMore = true;
  Color _bgColor1 = Colors.blue;
  Color _bgColor2 = Colors.green;
  int? _touchedIndex; // for highlighting selected slice

  @override
  void initState() {
    super.initState();
    _loadColorsFromPrefs();
    _fetchAgeGroups();
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
    });
  }

  Future<void> _fetchAgeGroups({bool reset = false}) async {
    if (!_hasMore && !reset) return;

    if (reset) {
      setState(() {
        _pageIndex = 0;
        _ageGroups.clear();
        _hasMore = true;
      });
    }

    setState(() => _isLoading = true);

    final url =
        "http://api.aoinfotech.com/api/GetAgeWiseVoterCount?pageindex=$_pageIndex&pagesize=$_pageSize&Search_Data=";

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "X-ApiKey": "552556497339462MH16BZbr2024",
          "X-MobNo": "8830228583",
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> newGroups = data["AgeWizeVoterCount"] ?? [];

        setState(() {
          if (newGroups.length < _pageSize) {
            _hasMore = false;
          }
          _ageGroups.addAll(newGroups);
          _pageIndex++;
        });
      } else {
        throw Exception("Failed to load data");
      }
    } catch (e) {
      print("Error fetching age data: $e");
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final List<Color> colorList = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.brown,
      Colors.cyan,
      Colors.indigo,
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Voters by Age"),
        foregroundColor: Colors.white,
        backgroundColor: _bgColor1,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_bgColor2, _bgColor1],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            if (_ageGroups.isNotEmpty)
              SizedBox(
                height: 300,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    sections: List.generate(_ageGroups.length, (index) {
                      final age = _ageGroups[index];
                      final count = (age['VoterCount'] as num).toDouble();
                      final isTouched = index == _touchedIndex;

                      return PieChartSectionData(
                        color: colorList[index % colorList.length],
                        value: count,
                        title: "${age['AgeGroup']}\n${age['Percentage']}%",
                        radius: isTouched ? 120 : 100, // highlight tapped slice
                        titleStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      );
                    }),
                    pieTouchData: PieTouchData(
                      touchCallback: (event, response) {
                        if (response != null &&
                            response.touchedSection != null) {
                          final index =
                              response.touchedSection!.touchedSectionIndex;

                          // ✅ Fix: only proceed if index is valid
                          if (index >= 0 && index < _ageGroups.length) {
                            setState(() {
                              _touchedIndex = index;
                            });

                            if (event is FlTapUpEvent) {
                              final age = _ageGroups[index];
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AgeVoterListScreen(
                                    ageGroup: age['AgeGroup'],
                                  ),
                                ),
                              );
                            }
                          }
                        } else {
                          setState(() {
                            _touchedIndex = null;
                          });
                        }
                      },
                    ),
                  ),
                ),
              ),
            Expanded(
              child: ListView.builder(
                itemCount: _ageGroups.length + (_isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index < _ageGroups.length) {
                    final age = _ageGroups[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      child: ListTile(
                        title: Text("${age['AgeGroup']}"),
                        subtitle: Text(
                          "Voters: ${age['VoterCount']} | ${age['Percentage']}%",
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  AgeVoterListScreen(ageGroup: age['AgeGroup']),
                            ),
                          );
                        },
                      ),
                    );
                  } else {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                },
              ),
            ),
            if (_hasMore && !_isLoading)
              ElevatedButton(
                onPressed: _fetchAgeGroups,
                child: const Text("Load More"),
              ),
          ],
        ),
      ),
    );
  }
}
