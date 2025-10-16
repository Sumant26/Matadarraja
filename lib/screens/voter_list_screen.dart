import 'dart:async';
import 'dart:convert';
import 'package:async/async.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:matadarraja/screens/voter_details_screen.dart';
import 'package:matadarraja/screens/home_screen.dart'; // ✅ Import LanguageProvider

class BeachScreen extends StatefulWidget {
  final String title;
  const BeachScreen({super.key, required this.title});

  @override
  State<BeachScreen> createState() => _BeachScreenState();
}

class _BeachScreenState extends State<BeachScreen> {
  final TextEditingController searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  Color bgColor1 = const Color(0xFFFB8C00);
  Color bgColor2 = const Color(0xFFF4511E);

  bool hasMore = true;
  bool isLoading = true;
  bool isFetching = false;

  int pageIndex = 0;
  final int pageSize = 30;
  String searchQuery = "";

  List<Map<String, dynamic>> voters = [];

  Timer? _debounce;
  CancelableOperation? _ongoingRequest;
  int _lastRequestId = 0;
  final Map<String, List<Map<String, dynamic>>> _cache = {};

  @override
  void initState() {
    super.initState();
    loadColors();
    Future.microtask(() => fetchVoters(reset: true));
    _scrollController.addListener(_scrollListener);
  }

  Future<void> loadColors() async {
    final prefs = await SharedPreferences.getInstance();
    final savedBg1 = prefs.getInt('bgColor1');
    final savedBg2 = prefs.getInt('bgColor2');

    if (savedBg1 != null && savedBg2 != null) {
      bgColor1 = Color(savedBg1);
      bgColor2 = Color(savedBg2);
    }

    if (mounted) setState(() => isLoading = false);
  }

  Future<void> fetchVoters({bool reset = false}) async {
    if (isFetching) return;

    if (reset) {
      pageIndex = 0;
      hasMore = true;
      voters.clear();
      _cache.remove(searchQuery);
      setState(() {});
    } else if (!hasMore) {
      return;
    }

    setState(() => isFetching = true);

    _ongoingRequest?.cancel();
    final requestId = ++_lastRequestId;

    final url =
        "https://api.aoinfotech.com/api/SearchVoters?pageindex=$pageIndex&pagesize=$pageSize&Search_Data=$searchQuery";

    _ongoingRequest = CancelableOperation.fromFuture(
      _performFetch(url, requestId, reset),
    );
  }

  Future<void> _performFetch(String url, int requestId, bool reset) async {
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: const {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "X-ApiKey": "552556497339462MH16BZbr2024",
          "X-MobNo": "8830228583",
        },
      );

      if (requestId != _lastRequestId || !mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = await compute(_parseResponse, response.body);
        final List<dynamic> data = decoded['voterList'] ?? [];

        if (!mounted) return;

        setState(() {
          if (reset) voters.clear();
          voters.addAll(data.map((v) => Map<String, dynamic>.from(v)));
          hasMore = data.length == pageSize;
          pageIndex++;
        });

        if (reset) _cache[searchQuery] = List.from(voters);
      } else {
        _handleHttpError(response.statusCode);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Connection failed: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isFetching = false);
    }
  }

  void _handleHttpError(int statusCode) {
    if (!mounted) return;
    String message;
    Color color = Colors.red;

    if (statusCode == 404) {
      message = "No data found.";
      color = Colors.orange;
      voters.clear();
      hasMore = false;
    } else {
      message = "Error $statusCode: Something went wrong.";
      hasMore = false;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));

    setState(() {});
  }

  static Map<String, dynamic> _parseResponse(String responseBody) =>
      json.decode(responseBody) as Map<String, dynamic>;

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 50), () {
      if (!mounted) return;
      searchQuery = query.trim();
      _scrollController.jumpTo(0);
      fetchVoters(reset: true);
    });
  }

  void _scrollListener() {
    if (!hasMore || isFetching) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      fetchVoters();
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    _ongoingRequest?.cancel();
    super.dispose();
  }

  String removeUnderscores(String key) => key.replaceAll('_', ' ');

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator(color: bgColor1)),
      );
    }

    // ✅ Wrap with ListenableBuilder to dynamically translate text
    return ListenableBuilder(
      listenable: languageProvider,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(languageProvider.getText('search')),
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
                // 🔍 Search Bar
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

                // 📋 Voter List
                Expanded(
                  child: voters.isEmpty && !isFetching
                      ? Center(
                          child: Text(
                            "No results were found for your search.",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        )
                      : ListView.separated(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          itemCount: voters.length + (hasMore ? 1 : 0),
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            if (index == voters.length) {
                              return Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: bgColor1,
                                  ),
                                ),
                              );
                            }

                            final voter = voters[index];
                            return GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      VoterDetailsScreen(voter: voter),
                                ),
                              ),
                              child: Card(
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
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              languageProvider
                                                          .currentLanguage ==
                                                      "Marathi"
                                                  ? voter['FullNameMarathi'] ??
                                                        "Unknown"
                                                  : voter['FullNameEnglish'] ??
                                                        "Unknown",
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              languageProvider
                                                          .currentLanguage ==
                                                      "Marathi"
                                                  ? (voter['VAddressMarathi'] ??
                                                        "")
                                                  : (voter['VAddressEnglish'] ??
                                                        ""),
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      ElevatedButton(
                                        onPressed: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                VoterDetailsScreen(
                                                  voter: voter,
                                                ),
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: bgColor1,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          languageProvider.getText(
                                            'voter_details',
                                          ),
                                        ),
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
      },
    );
  }
}
