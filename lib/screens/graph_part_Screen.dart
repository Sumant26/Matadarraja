import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:matadarraja/screens/twon_voter_list_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GraphPartScreen extends StatefulWidget {
  @override
  _GraphPartScreenState createState() => _GraphPartScreenState();
}

class _GraphPartScreenState extends State<GraphPartScreen> {
  List<Map<String, dynamic>> voters = [];
  int _currentPage = 0;
  final int _itemsPerPage = 10;
  int totalCount = 0;

  bool isLoading = true;
  bool isFetchingMore = false;

  Color bgColor1 = const Color(0xFFFB8C00);
  Color bgColor2 = const Color(0xFFF4511E);

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    loadColors();
    fetchVoters();

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

  Future<void> fetchVoters({bool append = false}) async {
    try {
      final url =
          "http://api.aoinfotech.com/api/GetVotersByPartNo?pageindex=$_currentPage&pagesize=$_itemsPerPage&acNo=210&PartNo=201&Search_Data=";

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
            voters.addAll(List<Map<String, dynamic>>.from(data["voterList"]));
          } else {
            voters = List<Map<String, dynamic>>.from(data["voterList"]);
          }
          totalCount = data["VoterCount"] ?? 0;
          isLoading = false;
          isFetchingMore = false;
        });
      } else {
        throw Exception("Failed to load voters");
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        isFetchingMore = false;
      });
      print("Error fetching voters: $e");
    }
  }

  void _loadMore() {
    setState(() {
      isFetchingMore = true;
      _currentPage++;
    });
    fetchVoters(append: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Voters by Part No"),
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
                itemCount: voters.length + (isFetchingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == voters.length) {
                    return Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    );
                  }

                  final voter = voters[index];
                  return Card(
                    color: Colors.white.withOpacity(0.9),
                    margin: const EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 10,
                    ),
                    child: ListTile(
                      title: Text(
                        "${voter['FullNameEnglish']} (${voter['FullNameMarathi']})",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      subtitle: Text(
                        "Epic: ${voter['EpicNo']} | Address: ${voter['VAddressEnglish']} (${voter['VAddessMarathi']})",
                        style: TextStyle(color: Colors.black54),
                      ),
                      trailing: Text(
                        "#${voter['SlNoInPart']}",
                        style: TextStyle(color: Colors.deepOrange),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TownVoterListScreen(
                              townName: voter['VAddressEnglish'],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
      ),
    );
  }
}
