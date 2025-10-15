import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:matadarraja/screens/gender_voter_list_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class ChartScreen extends StatefulWidget {
  final String title;

  const ChartScreen({super.key, required this.title});

  @override
  State<ChartScreen> createState() => _ChartScreenState();
}

class _ChartScreenState extends State<ChartScreen> {
  double malePercent = 0;
  double femalePercent = 0;

  List<dynamic> maleList = [];
  List<dynamic> femaleList = [];

  Color _bgColor1 = Colors.blue;
  Color _bgColor2 = Colors.green;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    debugPrint("ChartScreen initState called ✅");
    _loadColorsFromPrefs();
    _fetchGenderWiseData(); // 👈 make sure it’s called
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

  Future<void> _fetchGenderWiseData() async {
    debugPrint("Fetching gender wise data...");
    try {
      final url =
          "http://api.aoinfotech.com/api/GetGenderWiseVoterCount?pageindex=0&pagesize=10&Search_Data=";
      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "X-ApiKey": "552556497339462MH16BZbr2024",
          "X-MobNo": "8830228583",
        },
      );
      debugPrint("API Response status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint("API Response: $data");

        final List<dynamic> genderList = data["GenderWizeVoterCount"];
        debugPrint("Gender List: $genderList");

        final male = genderList.firstWhere(
          (e) => e["Gender"] == "M",
          orElse: () => null,
        );
        final female = genderList.firstWhere(
          (e) => e["Gender"] == "F",
          orElse: () => null,
        );
        final other = genderList.firstWhere(
          (e) => e["Gender"] == "O",
          orElse: () => null,
        );

        final maleCount = male != null ? male["VoterCount"] as int : 0;
        final femaleCount = female != null ? female["VoterCount"] as int : 0;
        final otherCount = other != null ? other["VoterCount"] as int : 0;

        final total = maleCount + femaleCount + otherCount;

        setState(() {
          if (total > 0) {
            malePercent = (maleCount / total) * 100;
            femalePercent = (femaleCount / total) * 100;
          } else {
            malePercent = 0;
            femalePercent = 0;
          }

          /// store lists for navigation
          maleList = male != null ? male["VoterList"] ?? [] : [];
          femaleList = female != null ? female["VoterList"] ?? [] : [];

          _isLoading = false;
        });

        debugPrint("Male%: $malePercent | Female%: $femalePercent");
      } else {
        throw Exception("Failed to load data");
      }
    } catch (e) {
      debugPrint("Error fetching gender data: $e");
      setState(() => _isLoading = false);
    }
  }

  /// ✅ Gender UI (with navigation on tap)
  Widget _buildGenderFigures(double malePercent, double femalePercent) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    GenderVoterListScreen(title: "Male", voters: maleList),
              ),
            );
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Icon(Icons.man, size: 150, color: Colors.grey.shade300),
                  ClipRect(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      heightFactor: malePercent / 100,
                      child: const Icon(
                        Icons.man,
                        size: 150,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${malePercent.toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Male',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        const SizedBox(width: 60),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    GenderVoterListScreen(title: "Female", voters: femaleList),
              ),
            );
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Icon(Icons.woman, size: 150, color: Colors.grey.shade300),
                  ClipRect(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      heightFactor: femalePercent / 100,
                      child: const Icon(
                        Icons.woman,
                        size: 150,
                        color: Colors.pink,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${femalePercent.toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Female',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _bgColor1,
        title: Text(widget.title.replaceAll('_', ' ')),
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
          child: _isLoading
              ? const CircularProgressIndicator()
              : _buildGenderFigures(malePercent, femalePercent),
        ),
      ),
    );
  }
}
