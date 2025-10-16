import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

// ---------------- MOCK API ----------------
// Simulates an API call with pagination, type, and search.
// ---------------- MOCK API ----------------
Future<Map<String, dynamic>> mockApiFetchVoters({
  required String type,
  required String value,
  required int page,
  required String search,
}) async {
  await Future.delayed(const Duration(milliseconds: 600)); // simulate delay

  // Generate fake voters
  final allVoters = List.generate(
    200,
    (index) => {
      "id": index,
      "name": "$value Voter $index",
      "age": 18 + (index % 60),
      "town": "Town ${['A', 'B', 'C'][index % 3]}",
      "gender": (index % 2 == 0) ? "male" : "female",
    },
  );

  // Apply search safely with casting
  final filtered = allVoters.where((v) {
    final name = v['name'] as String;
    final age = v['age'] as int;
    return name.toLowerCase().contains(search.toLowerCase()) ||
        age.toString().contains(search);
  }).toList();

  // Pagination
  const int pageSize = 20;
  final start = (page - 1) * pageSize;
  final end = (start + pageSize) > filtered.length
      ? filtered.length
      : (start + pageSize);
  final results = start < filtered.length ? filtered.sublist(start, end) : [];

  return {"results": results, "pageSize": pageSize};
}

// ---------------- END MOCK API ----------------

class VoterListGraph extends StatefulWidget {
  final String type; // e.g. "gender", "town", "age"
  final String value; // e.g. "male", "Town A", "18-25"

  const VoterListGraph({super.key, required this.type, required this.value});

  @override
  State<VoterListGraph> createState() => _VoterListGraphState();
}

class _VoterListGraphState extends State<VoterListGraph> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  List voters = [];
  int page = 1;
  bool isLoading = false;
  bool hasMore = true;

  Timer? _debounce;
  DateTime _lastFetch = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    fetchVoters();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> fetchVoters({bool reset = false}) async {
    if (isLoading || !hasMore) return;

    // ---- throttle: at least 500ms gap between API calls ----
    if (DateTime.now().difference(_lastFetch) <
        const Duration(milliseconds: 500)) {
      return;
    }
    _lastFetch = DateTime.now();

    setState(() => isLoading = true);

    if (reset) {
      page = 1;
      voters.clear();
      hasMore = true;
    }

    final query = _searchController.text.trim();

    final data = await mockApiFetchVoters(
      type: widget.type,
      value: widget.value,
      page: page,
      search: query,
    );

    setState(() {
      voters.addAll(data['results']);
      page++;
      hasMore = data['results'].length == data['pageSize'];
      isLoading = false;
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      fetchVoters();
    }
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      fetchVoters(reset: true); // debounce search
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("${widget.value.toUpperCase()} VOTERS")),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: "Please search here",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          // Voter list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: voters.length + (isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index < voters.length) {
                  final voter = voters[index];
                  return ListTile(
                    leading: CircleAvatar(child: Text(voter['name'][0])),
                    title: Text(voter['name']),
                    subtitle: Text(
                      "Age: ${voter['age']} | Town: ${voter['town']}",
                    ),
                  );
                } else {
                  return const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
