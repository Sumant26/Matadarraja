import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'voter_details_screen.dart';

class AdvancedSearchResultScreen extends StatefulWidget {
  final Map<String, String> params;
  const AdvancedSearchResultScreen({super.key, required this.params});

  @override
  State<AdvancedSearchResultScreen> createState() =>
      _AdvancedSearchResultScreenState();
}

class _AdvancedSearchResultScreenState
    extends State<AdvancedSearchResultScreen> {
  final TextEditingController searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  Color bgColor1 = const Color(0xFFFB8C00);
  Color bgColor2 = const Color(0xFFF4511E);

  bool isLoading = true;
  bool isFetching = false;
  bool hasMore = true;

  int pageIndex = 0;
  final int pageSize = 10;
  Timer? _debounce;
  int _lastRequestId = 0;

  List<Map<String, dynamic>> voters = [];

  @override
  void initState() {
    super.initState();

    // Build a readable search string from params
    String searchText = widget.params["Search_Data"] ?? "";

    if (searchText.isEmpty) {
      final first = widget.params["FirstName"] ?? "";
      final middle = widget.params["MiddleName"] ?? "";
      final last = widget.params["Lastname"] ?? "";
      final epic = widget.params["EpicNo"] ?? "";
      final house = widget.params["HouseNo"] ?? "";
      final mobile = widget.params["MobileNo"] ?? "";

      if (first.isNotEmpty || middle.isNotEmpty || last.isNotEmpty) {
        searchText = [
          last,
          middle,
          first,
        ].where((part) => part.isNotEmpty).join(" ");
      } else if (epic.isNotEmpty) {
        searchText = epic;
      } else if (house.isNotEmpty) {
        searchText = house;
      } else if (mobile.isNotEmpty) {
        searchText = mobile;
      }
    }

    // Autofill the search bar
    searchController.text = searchText;

    loadColors();
    fetchVoters(reset: true);
    _scrollController.addListener(_scrollListener);
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

    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        setState(() => isFetching = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "No internet connection. Please check and try again.",
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final int requestId = ++_lastRequestId;
      final searchQuery = searchController.text.trim();

      final uri = Uri.parse(
        "https://api.aoinfotech.com/api/AdvanceSearchVoters"
        "?pageindex=$pageIndex&pagesize=$pageSize"
        "&FirstName=${Uri.encodeComponent(widget.params["FirstName"] ?? "")}"
        "&MiddleName=${Uri.encodeComponent(widget.params["MiddleName"] ?? "")}"
        "&Lastname=${Uri.encodeComponent(widget.params["Lastname"] ?? "")}"
        "&FromAge=${widget.params["FromAge"]?.isEmpty ?? true ? "0" : widget.params["FromAge"]}"
        "&ToAge=${widget.params["ToAge"]?.isEmpty ?? true ? "150" : widget.params["ToAge"]}"
        "&MobileNo=${widget.params["MobileNo"] ?? ""}"
        "&PartNo=${widget.params["PartNo"] ?? ""}"
        "&EpicNo=${widget.params["EpicNo"] ?? ""}"
        "&HouseNo=${Uri.encodeComponent(widget.params["HouseNo"] ?? "")}"
        "&Search_Data=${Uri.encodeComponent(searchQuery)}",
      );

      final response = await http
          .get(
            uri,
            headers: {
              "Content-Type": "application/json",
              "Accept": "application/json",
              "X-ApiKey": "552556497339462MH16BZbr2024",
              "X-MobNo": "8830228583",
            },
          )
          .timeout(const Duration(seconds: 15)); // ✅ timeout

      print("Response : ${response.body}");

      if (requestId != _lastRequestId) return; // ignore outdated responses

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = json.decode(response.body);

        // ✅ Handle both cases: List or Map
        final List<dynamic> data = decoded is List
            ? decoded
            : (decoded['voterList'] ?? []);

        setState(() {
          if (data.length < pageSize) hasMore = false;
          voters.addAll(data.map((v) => Map<String, dynamic>.from(v)));
          pageIndex++;
        });
      } else {
        String message;
        switch (response.statusCode) {
          case 400:
            message = "Bad request. Please check your input.";
            break;
          case 401:
          case 403:
            message = "Unauthorized. Please log in again.";
            break;
          case 404:
            message = "No voters found.";
            break;
          case 500:
          default:
            message = "Server error: ${response.statusCode}. Please try later.";
            break;
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), backgroundColor: Colors.red),
          );
        }
        setState(() => hasMore = false);
      }
    } on TimeoutException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Request timed out. Please try again."),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => hasMore = false);
    } catch (e) {
      if (mounted) {
        print("Error : $e");
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error fetching voters: $e")));
      }
      setState(() => hasMore = false);
    }

    if (mounted) {
      setState(() => isFetching = false);
    }
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !isFetching) {
      fetchVoters();
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      fetchVoters(reset: true);
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  String _displayName(Map<String, dynamic> voter) {
    return voter['FullNameEnglish'] ?? voter['FullNameMarathi'] ?? "Unknown";
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
        title: const Text("Search Results"),
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

            // Results
            Expanded(
              child: voters.isEmpty && !isFetching
                  ? const Center(child: Text("No results found."))
                  : ListView.builder(
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _displayName(voter),
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          voter['VAddressEnglish'] ?? "",
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
