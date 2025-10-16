import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:matadarraja/screens/surname_list_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SurnameGraphScreen extends StatefulWidget {
  const SurnameGraphScreen({Key? key}) : super(key: key);

  @override
  _SurnameGraphScreenState createState() => _SurnameGraphScreenState();
}

class _SurnameGraphScreenState extends State<SurnameGraphScreen> {
  List<Map<String, dynamic>> surnames = [];
  int _currentPage = 0;
  final int _itemsPerPage = 10;
  int totalCount = 0;

  bool isLoading = true;
  bool isFetchingMore = false;
  String searchQuery = "";

  Color bgColor1 = const Color(0xFF2196F3);
  Color bgColor2 = const Color(0xFF1565C0);

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  Timer? _debounce;
  DateTime? _lastFetchTime;

  @override
  void initState() {
    super.initState();
    loadColors();
    fetchSurnames();

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
    _searchController.dispose();
    _debounce?.cancel();
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

  /// ---------------------------
  /// API Fetch
  /// ---------------------------
  Future<void> fetchSurnames({bool append = false}) async {
    // --- Throttle: allow only 1 fetch every 500ms
    if (_lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!) <
            const Duration(milliseconds: 500)) {
      return;
    }
    _lastFetchTime = DateTime.now();

    try {
      final url =
          "http://api.aoinfotech.com/api/GetSurnameWiseVoterCount?pageindex=$_currentPage&pagesize=$_itemsPerPage&Search_Data=$searchQuery";
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
            surnames.addAll(
              List<Map<String, dynamic>>.from(data["SurnameWizeVoterCount"]),
            );
          } else {
            surnames = List<Map<String, dynamic>>.from(
              data["SurnameWizeVoterCount"],
            );
          }
          totalCount = data["SurnameCount"] ?? 0;
          isLoading = false;
          isFetchingMore = false;
        });
      } else {
        throw Exception("Failed to load surnames");
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        isFetchingMore = false;
      });
      debugPrint("Error fetching surnames: $e");
    }
  }

  void _loadMore() {
    setState(() {
      isFetchingMore = true;
      _currentPage++;
    });
    fetchSurnames(append: true);
  }

  /// ---------------------------
  /// Search with Debounce
  /// ---------------------------
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 400), () {
      setState(() {
        searchQuery = query.trim();
        _currentPage = 0;
        surnames.clear();
        isLoading = true;
      });
      fetchSurnames();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Voters by Surname"),
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
            // Search bar
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Please search here",
                  hintStyle: const TextStyle(color: Colors.white70),
                  prefixIcon: const Icon(Icons.search, color: Colors.white),
                  filled: true,
                  fillColor: Colors.black26,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      itemCount: surnames.length + (isFetchingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == surnames.length) {
                          return const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            ),
                          );
                        }
                        final surname = surnames[index];
                        return ListTile(
                          title: Text(
                            surname['SurnameNameEnglish'] ?? "",
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: LinearProgressIndicator(
                            value: ((surname['Percentage'] ?? 0) / 100)
                                .toDouble(),
                            minHeight: 8,
                            backgroundColor: Colors.grey[300],
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.green,
                            ),
                          ),
                          trailing: Text(
                            "${surname['VoterCount']} voters",
                            style: const TextStyle(color: Colors.white),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SurnameListScreen(
                                  surname: surname['SurnameNameEnglish'],
                                ),
                              ),
                            );
                          },
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
