import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:matadarraja/screens/twon_voter_list_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TownGraphScreen extends StatefulWidget {
  @override
  _TownGraphScreenState createState() => _TownGraphScreenState();
}

class _TownGraphScreenState extends State<TownGraphScreen> {
  List<Map<String, dynamic>> towns = [];
  int _currentPage = 0;
  final int _itemsPerPage = 10;
  Color bgColor1 = const Color(0xFFFB8C00);
  Color bgColor2 = const Color(0xFFF4511E);
  int totalCount = 0;
  bool isLoading = true;
  bool isFetchingMore = false;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    loadColors();
    fetchTowns();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 100 &&
          !isFetchingMore &&
          (_currentPage + 1) * _itemsPerPage < totalCount) {
        _loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> loadColors() async {
    final prefs = await SharedPreferences.getInstance();
    final savedBg1 = prefs.getInt('bgColor1');
    final savedBg2 = prefs.getInt('bgColor2');

    if (savedBg1 != null && savedBg2 != null) {
      setState(() {
        bgColor1 = Color(savedBg1);
        bgColor2 = Color(savedBg2);
      });
    }
  }

  Future<void> fetchTowns({bool append = false}) async {
    try {
      final url =
          "http://api.aoinfotech.com/api/GetTownWiseVoterCount?pageindex=$_currentPage&pagesize=$_itemsPerPage&Search_Data=";
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

        setState(() {
          if (append) {
            towns.addAll(
              List<Map<String, dynamic>>.from(data["TownWizeVoterCount"]),
            );
          } else {
            towns = List<Map<String, dynamic>>.from(data["TownWizeVoterCount"]);
          }
          totalCount = data["TownCount"] ?? 0;
          isLoading = false;
          isFetchingMore = false;
        });
      } else {
        throw Exception("Failed to load towns");
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        isFetchingMore = false;
      });
      print("Error fetching towns: $e");
    }
  }

  void _loadMore() {
    setState(() {
      isFetchingMore = true;
      _currentPage++;
    });
    fetchTowns(append: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Voters by Town"),
        backgroundColor: bgColor1,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [bgColor2, bgColor1],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: isLoading
            ? Center(child: CircularProgressIndicator(color: Colors.white))
            : ListView.builder(
                controller: _scrollController,
                itemCount: towns.length + (isFetchingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == towns.length) {
                    return Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    );
                  }
                  final town = towns[index];
                  return ListTile(
                    title: Text(
                      "${town['TownNameEnglish']} (${town['TownNameMarathi']})",
                      style: TextStyle(color: Colors.white),
                    ),
                    subtitle: LinearProgressIndicator(
                      value: (town['Percentage'] ?? 0) / 100,
                      minHeight: 8,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                    ),
                    trailing: Text(
                      "${town['VoterCount']} voters",
                      style: TextStyle(color: Colors.white),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TownVoterListScreen(
                            townName: town['TownNameEnglish'],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}
