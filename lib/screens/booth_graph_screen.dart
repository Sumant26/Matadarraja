import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:matadarraja/screens/booth_voter_list_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BoothGraphScreen extends StatefulWidget {
  const BoothGraphScreen({super.key});

  @override
  State<BoothGraphScreen> createState() => _BoothGraphScreenState();
}

class _BoothGraphScreenState extends State<BoothGraphScreen> {
  List<Map<String, dynamic>> booths = [];
  int _currentPage = 0;
  final int _itemsPerPage = 10;
  int totalCount = 0;
  bool isLoading = true;
  bool isFetchingMore = false;

  String _searchQuery = "";
  Timer? _debounce;

  Color bgColor1 = Colors.blue;
  Color bgColor2 = Colors.green;

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  bool _disposed = false; // track widget disposal

  @override
  void initState() {
    super.initState();
    loadColors();
    fetchBooths();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 100 &&
          !isFetchingMore &&
          (_currentPage + 1) * _itemsPerPage < totalCount) {
        _loadMore();
      }
    });

    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _disposed = true;
    _scrollController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> loadColors() async {
    final prefs = await SharedPreferences.getInstance();
    final savedBg1 = prefs.getInt('bgColor1');
    final savedBg2 = prefs.getInt('bgColor2');

    if (!_disposed && savedBg1 != null && savedBg2 != null) {
      if (!mounted) return;
      setState(() {
        bgColor1 = Color(savedBg1);
        bgColor2 = Color(savedBg2);
      });
    }
  }

  Future<void> fetchBooths({bool append = false}) async {
    try {
      final url =
          "http://api.aoinfotech.com/api/GetBoothWiseVoterCount?pageindex=$_currentPage&pagesize=$_itemsPerPage&Search_Data=$_searchQuery";

      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "X-ApiKey": "552556497339462MH16BZbr2024",
          "X-MobNo": "8830228583",
        },
      );

      if (!mounted || _disposed) return;
      print("Response : ${response.statusCode}");
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        setState(() {
          if (append) {
            booths.addAll(
              List<Map<String, dynamic>>.from(
                data["BoothWizeVoterCount"] ?? [],
              ),
            );
          } else {
            booths = List<Map<String, dynamic>>.from(
              data["BoothWizeVoterCount"] ?? [],
            );
          }
          totalCount = data["BoothCount"] ?? 0;
          isLoading = false;
          isFetchingMore = false;
        });

        if (booths.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("No data found"),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else if (response.statusCode == 404) {
        setState(() {
          isLoading = false;
          isFetchingMore = false;
          booths.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("No data found"),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        setState(() {
          isLoading = false;
          isFetchingMore = false;
          booths.clear();
        });
        String message = "Unexpected error (${response.statusCode})";
        switch (response.statusCode) {
          case 400:
            message = "Bad request (400)";
            break;
          case 401:
            message = "Unauthorized (401)";
            break;
          case 403:
            message = "Forbidden (403)";
            break;
          case 500:
            message = "Server error (500)";
            break;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (!mounted || _disposed) return;
      setState(() {
        isLoading = false;
        isFetchingMore = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Network error. Please try again."),
          duration: Duration(seconds: 2),
        ),
      );
      debugPrint("Error fetching booths: $e");
    }
  }

  void _loadMore() {
    if (_disposed) return;
    setState(() {
      isFetchingMore = true;
      _currentPage++;
    });
    fetchBooths(append: true);
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (_disposed || !mounted) return;

      setState(() {
        _searchQuery = _searchController.text.trim();
        _currentPage = 0;
        isLoading = true;
        booths.clear();
      });

      fetchBooths();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Voters by Booth"),
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
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Search Booth...",
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

            // Booth List
            Expanded(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : booths.isEmpty
                  ? const Center(
                      child: Text(
                        "No booths available",
                        style: TextStyle(color: Colors.white),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      itemCount: booths.length + (isFetchingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == booths.length) {
                          return const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            ),
                          );
                        }

                        final booth = booths[index];
                        return ListTile(
                          title: Text(
                            "${booth['BoothNameEnglish']} (ID: ${booth['BoothId']})",
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: LinearProgressIndicator(
                            value: (booth['Percentage'] ?? 0) / 100,
                            minHeight: 8,
                            backgroundColor: Colors.grey[300],
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.green,
                            ),
                          ),
                          trailing: Text(
                            "${booth['VoterCount']} voters",
                            style: const TextStyle(color: Colors.white),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BoothVoterListScreen(
                                  boothId: booth['BoothId'] ?? "",
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
