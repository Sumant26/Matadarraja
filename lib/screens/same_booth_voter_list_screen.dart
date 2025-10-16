import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:matadarraja/screens/voter_details_screen.dart';
import 'package:matadarraja/screens/home_screen.dart'; // For languageProvider

class SameBoothVoterListScreen extends StatefulWidget {
  final String title;
  final int voterId; // ✅ pass voterId dynamically

  const SameBoothVoterListScreen({
    super.key,
    required this.title,
    required this.voterId,
  });

  @override
  State<SameBoothVoterListScreen> createState() => _BeachScreenState();
}

class _BeachScreenState extends State<SameBoothVoterListScreen> {
  final TextEditingController searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  Color bgColor1 = const Color(0xFFFB8C00);
  Color bgColor2 = const Color(0xFFF4511E);

  bool isLoading = true; // screen init loader
  bool isFetching = false; // api fetch state
  bool hasMore = true; // pagination control

  int pageIndex = 0;
  final int pageSize = 10;
  String searchQuery = "";

  List<Map<String, dynamic>> voters = [];
  int totalCount = 0; // ✅ use VoterCount from API

  Timer? _debounce;
  String? language;
  @override
  void initState() {
    super.initState();
    loadColors();
    fetchVoters(); // initial fetch
    _scrollController.addListener(_scrollListener);
  }

  Future<void> loadColors() async {
    final prefs = await SharedPreferences.getInstance();
    final savedBg1 = prefs.getInt('bgColor1');
    final savedBg2 = prefs.getInt('bgColor2');
    language = prefs.getString('language');

    if (savedBg1 != null && savedBg2 != null) {
      setState(() {
        bgColor1 = Color(savedBg1);
        bgColor2 = Color(savedBg2);
      });
    }
    setState(() {
      isLoading = false;
    });
  }

  Future<void> fetchVoters({bool reset = false}) async {
    if (isFetching || !hasMore) return;

    if (!mounted) return;
    setState(() => isFetching = true);

    if (reset) {
      pageIndex = 0;
      hasMore = true;
      voters.clear();
    }

    final url =
        "https://api.aoinfotech.com/api/GetVotersOnSameBooth?pageindex=$pageIndex&pagesize=$pageSize&voterId=${widget.voterId}&Search_Data=$searchQuery";

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
        final body = json.decode(response.body);
        debugPrint("API Response: $body");

        final List<dynamic> data = body['voterList'] ?? [];
        totalCount = body['VoterCount'] ?? 0;

        if (!mounted) return;
        setState(() {
          if (data.length < pageSize ||
              voters.length + data.length >= totalCount) {
            hasMore = false;
          }
          voters.addAll(data.map((v) => Map<String, dynamic>.from(v)));
          pageIndex++;
        });
      } else {
        debugPrint("API Error: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      debugPrint("API Exception: $e");
    }

    if (!mounted) return;
    setState(() => isFetching = false);
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() {
        searchQuery = query.trim();
      });
      fetchVoters(reset: true);
    });
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !isFetching) {
      fetchVoters();
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  String removeUnderscores(String key) {
    return languageProvider.getText(key).replaceAll('_', ' ');
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator(color: bgColor1)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
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
        child: Column(
          children: [
            // Search box
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: "Please search here",
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.9),
                ),
                onChanged: _onSearchChanged,
              ),
            ),

            // Voter list
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: voters.length + (hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == voters.length) {
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Center(
                        child: CircularProgressIndicator(color: bgColor1),
                      ),
                    );
                  }

                  final voter = voters[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              VoterDetailsScreen(voter: voter),
                        ),
                      );
                    },
                    child: Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    language == "English"
                                        ? voter['FullNameEnglish'] ?? "Unknown"
                                        : voter['FullNameMarathi'] ?? "Unknown",
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    language == "English"
                                        ? voter['VAddressEnglish'] ?? ""
                                        : voter['VAddressMarathi'] ?? "",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Epic No: ${voter['EpicNo'] ?? ''}",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        VoterDetailsScreen(voter: voter),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: bgColor1,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(removeUnderscores('view_details')),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
