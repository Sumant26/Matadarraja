import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:matadarraja/screens/voter_details_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GenderVoterListScreen extends StatefulWidget {
  final String title;
  final List<dynamic> voters;

  const GenderVoterListScreen({
    super.key,
    required this.title,
    required this.voters,
  });

  @override
  State<GenderVoterListScreen> createState() => _GenderVoterListScreenState();
}

class _GenderVoterListScreenState extends State<GenderVoterListScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  List<dynamic> voters = [];
  int pageIndex = 0;
  final int pageSize = 20;
  bool isFetching = false;
  bool hasMore = true;
  String searchQuery = "";
  Timer? _debounce;

  Color bgColor1 = const Color(0xFFFB8C00);
  Color bgColor2 = const Color(0xFFF4511E);
  int totalCount = 0;
  bool isLoading = true;
  String? language;
  @override
  void initState() {
    super.initState();
    loadColors();
    fetchVoters();
    _scrollController.addListener(_onScroll);
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
    if (isFetching || !hasMore) return;

    setState(() => isFetching = true);

    if (reset) {
      pageIndex = 0;
      hasMore = true;
      voters.clear();
    }

    String gender = widget.title == "Male" ? "M" : "F";
    final url =
        "https://api.aoinfotech.com/api/GetVotersByGender?pageindex=$pageIndex&pagesize=$pageSize&Gender=$gender&Search_Data=$searchQuery";

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

        final List<dynamic> newVoters = data['voterList'] ?? [];
        final int count = data['VoterCount'] ?? 0;

        setState(() {
          totalCount = count;
          voters.addAll(newVoters);
          pageIndex++;
          if (newVoters.length < pageSize) hasMore = false;
        });
      } else {
        throw Exception("Failed to load voters");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      setState(() => isFetching = false);
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !isFetching &&
        hasMore) {
      fetchVoters();
    }
  }

  void _onSearchChanged(String query) {
    // Cancel any previous debounce
    if (_debounce?.isActive ?? false) _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        searchQuery = query.trim();
        pageIndex = 0;
        hasMore = true;
        voters.clear();
      });

      // Fetch voters based on current search query (empty or non-empty)
      fetchVoters(reset: true);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
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
        title: Text("${widget.title} Voters"),
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
            // Show total voter count like a header
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "Total Voters: $totalCount",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),

            // Search box like BeachScreen
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
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

            // Voter list with BeachScreen design
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
                          builder: (_) => VoterDetailsScreen(voter: voter),
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
                                    builder: (_) =>
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
