import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:matadarraja/screens/voter_details_screen.dart';

class SurnameListScreen extends StatefulWidget {
  final String surname;
  const SurnameListScreen({Key? key, required this.surname}) : super(key: key);

  @override
  State<SurnameListScreen> createState() => _SurnameListScreenState();
}

class _SurnameListScreenState extends State<SurnameListScreen> {
  final TextEditingController searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  Color bgColor1 = const Color(0xFF2196F3);
  Color bgColor2 = const Color(0xFF1565C0);

  bool isLoading = true;
  bool isFetching = false;
  bool hasMore = true;

  int pageIndex = 0;
  final int pageSize = 10;
  int totalCount = 0;
  String searchQuery = "";

  List<dynamic> voters = [];
  Timer? _debounce;
  int _lastRequestId = 0;
  String? language;
  @override
  void initState() {
    super.initState();
    loadColors();
    fetchVoters(reset: true);
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
    setState(() => isLoading = false);
  }

  Future<void> fetchVoters({bool reset = false}) async {
    if (isFetching) return;
    if (!hasMore && !reset) return;

    if (reset) {
      setState(() {
        pageIndex = 0;
        voters.clear();
        hasMore = true;
      });
    }

    setState(() => isFetching = true);

    final int requestId = ++_lastRequestId;
    final url =
        "http://api.aoinfotech.com/api/GetVotersBySurname?pageindex=$pageIndex&pagesize=$pageSize&Surname=${widget.surname}&Search_Data=$searchQuery";

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

      if (requestId != _lastRequestId) return; // ignore outdated responses

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        final List<dynamic> data = body['voterList'] ?? [];
        totalCount = body['VoterCount'] ?? 0;

        setState(() {
          if (data.length < pageSize ||
              voters.length + data.length >= totalCount) {
            hasMore = false;
          }
          voters.addAll(data);
          pageIndex++;
        });
      } else {
        debugPrint("API Error: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      debugPrint("API Exception: $e");
    }

    if (mounted) {
      setState(() => isFetching = false);
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 300), () {
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

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator(color: bgColor1)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Voters: ${widget.surname}"),
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
                                    voter['FullNameEnglish'] ?? "Unknown",
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
                              child: const Text("View Details"),
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
