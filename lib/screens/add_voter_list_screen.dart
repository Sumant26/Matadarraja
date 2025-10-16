import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:matadarraja/screens/voter_details_screen.dart';

class AddVoterListScreen extends StatefulWidget {
  final String title;
  final String targetVoterId; // ✅ voter whose family we are adding to
  const AddVoterListScreen({
    super.key,
    required this.title,
    required this.targetVoterId,
  });

  @override
  State<AddVoterListScreen> createState() => _AddVoterListScreenState();
}

class _AddVoterListScreenState extends State<AddVoterListScreen> {
  final TextEditingController searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  Color bgColor1 = const Color(0xFFFB8C00);
  Color bgColor2 = const Color(0xFFF4511E);

  bool isLoading = true;
  bool isFetching = false;
  bool hasMore = true;

  int pageIndex = 0;
  final int pageSize = 10;
  String searchQuery = "";

  List<Map<String, dynamic>> voters = [];

  Timer? _debounce;
  int _lastRequestId = 0;

  List<Map<String, dynamic>> familyMembers = []; // ✅ local family list
  bool _noInternet = false;

  @override
  void initState() {
    super.initState();
    loadColors();
    loadFamilyFromPrefs();
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

  Future<void> loadFamilyFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('family_${widget.targetVoterId}');
    if (stored != null) {
      setState(() {
        familyMembers = List<Map<String, dynamic>>.from(jsonDecode(stored));
      });
    }
  }

  Future<void> saveFamilyToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'family_${widget.targetVoterId}',
      jsonEncode(familyMembers),
    );
  }

  Future<void> fetchVoters({bool reset = false}) async {
    // ✅ Check Internet first
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      setState(() {
        _noInternet = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No Internet Connection!"),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return; // 🚫 stop here if no internet
    } else {
      setState(() {
        _noInternet = false;
      });
    }
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
        "https://api.aoinfotech.com/api/SearchVoters?pageindex=$pageIndex&pagesize=$pageSize&Search_Data=$searchQuery";

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

      if (requestId != _lastRequestId) return;

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        final List<dynamic> data = body['voterList'] ?? [];

        setState(() {
          if (data.length < pageSize) hasMore = false;
          voters.addAll(data.map((v) => Map<String, dynamic>.from(v)));
          pageIndex++;
        });
      } else {
        debugPrint("API Error: ${response.statusCode} - ${response.body}");
      }
    } on SocketException {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No Internet Connection!"),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      setState(() {
        _noInternet = true;
      });
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

  void _addToFamily(Map<String, dynamic> voter) async {
    // ✅ Prevent duplicate entries
    if (familyMembers.any((m) => m['VoterId'] == voter['VoterId'])) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Already in family")));
      return;
    }

    setState(() {
      familyMembers.add(voter);
    });
    await saveFamilyToPrefs();

    // ✅ Show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("${voter['FullNameEnglish']} added to family")),
    );

    // ✅ Navigate back to FamilyDetailsScreen and trigger refresh
    Future.delayed(const Duration(milliseconds: 400), () {
      Navigator.pop(context, true); // 🔹 return true instead of familyMembers
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  String removeUnderscores(String key) {
    return key.replaceAll('_', ' '); // fallback if no language provider
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
        title: const Text('Search Family Voters'),
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
                  return Card(
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
                          IconButton(
                            icon: const Icon(
                              Icons.person_add,
                              color: Colors.green,
                            ),
                            tooltip: "Add to Family",
                            onPressed: () => _addToFamily(voter),
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
