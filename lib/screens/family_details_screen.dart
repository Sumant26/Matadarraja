import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:matadarraja/screens/add_voter_list_screen.dart';
import 'package:matadarraja/screens/voter_details_screen.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:url_launcher/url_launcher.dart';

class FamilyDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> voter;

  const FamilyDetailsScreen({super.key, required this.voter});

  @override
  State<FamilyDetailsScreen> createState() => _FamilyDetailsScreenState();
}

class _FamilyDetailsScreenState extends State<FamilyDetailsScreen> {
  List<dynamic> _allMembers = [];
  List<dynamic> _familyMembers = [];
  List<dynamic> _addedMembers = [];
  List<dynamic> _deletedMembers = [];

  bool isLoading = true;
  bool isFetchingMore = false;
  int pageIndex = 0;
  final int pageSize = 10;

  String searchQuery = '';
  Timer? _debounce;
  late ScrollController _scrollController;

  Color bgColor1 = Colors.blue;
  Color bgColor2 = Colors.green;

  final ScreenshotController screenshotController = ScreenshotController();

  String _selectedShareOption = "without";
  final TextEditingController _numberController = TextEditingController();

  String get voterIdKey => widget.voter['VoterId'].toString();
  String? slipPrintPath;

  String? language;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    loadColorsFromPrefs();
    loadFamilyFromPrefs();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _debounce?.cancel();
    _numberController.dispose();
    super.dispose();
  }

  Future<void> loadColorsFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final bgColor1Value = prefs.getInt('bgColor1');
    final bgColor2Value = prefs.getInt('bgColor2');
    slipPrintPath = prefs.getString('BannerPath');
    language = prefs.getString('language');

    setState(() {
      if (bgColor1Value != null) bgColor1 = Color(bgColor1Value);
      if (bgColor2Value != null) bgColor2 = Color(bgColor2Value);
    });
  }

  Future<void> loadFamilyFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    final storedFamily = prefs.getString('family_$voterIdKey');
    final storedAdded = prefs.getString('added_$voterIdKey');
    final storedDeleted = prefs.getString('deleted_$voterIdKey');

    if (storedFamily != null) {
      _allMembers = jsonDecode(storedFamily);
      _addedMembers = storedAdded != null ? jsonDecode(storedAdded) : [];
      _deletedMembers = storedDeleted != null ? jsonDecode(storedDeleted) : [];

      _applySearch();
      setState(() => isLoading = false);
    } else {
      fetchFamilyMembers(reset: true);
    }
  }

  Future<void> saveFamilyToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('family_$voterIdKey', jsonEncode(_allMembers));
    await prefs.setString('added_$voterIdKey', jsonEncode(_addedMembers));
    await prefs.setString('deleted_$voterIdKey', jsonEncode(_deletedMembers));
  }

  Future<Map<String, dynamic>?> fetchVoterDetails(int voterId) async {
    try {
      final url =
          "https://api.aoinfotech.com/api/GetVoterDetails?voterid=$voterId";

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

        // ✅ Add booth map link
        final boothName = data['BoothNameEnglish'] ?? '';
        if (boothName.isNotEmpty) {
          data['MapLink'] =
              "https://www.google.com/maps/search/${Uri.encodeComponent(boothName)}";
        }

        return data;
      } else {
        debugPrint("Failed to fetch voter details: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      debugPrint("Error fetching voter details: $e");
      return null;
    }
  }

  Future<void> fetchFamilyMembers({bool reset = false}) async {
    if (reset) {
      setState(() {
        isLoading = true;
        pageIndex = 0;
        _allMembers.clear();
        _familyMembers.clear();
      });
    }

    try {
      final voterId = widget.voter['VoterId'];
      final response = await http.get(
        Uri.parse(
          "https://api.aoinfotech.com/api/GetFamilyVoters?pageindex=$pageIndex&pagesize=$pageSize&voterId=$voterId",
        ),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "X-ApiKey": "552556497339462MH16BZbr2024",
          "X-MobNo": "8830228583",
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResp = json.decode(response.body);
        final List<dynamic> data = jsonResp['voterList'] ?? [];

        // 🔹 Fetch full details from GetVoterDetails for each member concurrently
        final detailedMembers = await Future.wait(
          data.map((member) async {
            final voterId = member['VoterId'];
            final details = await fetchVoterDetails(voterId);
            if (details != null) {
              // Merge basic family info with full voter details
              final boothName = details['BoothNameEnglish'] ?? '';
              if (boothName.isNotEmpty) {
                details['MapLink'] =
                    "https://www.google.com/maps/search/${Uri.encodeComponent(boothName)}";
              }
              return {...member, ...details};
            }
            return member;
          }).toList(),
        );

        setState(() {
          if (reset) {
            _allMembers = detailedMembers;
          } else {
            _allMembers.addAll(detailedMembers);
          }
          _applySearch();
          isLoading = false;
          isFetchingMore = false;
        });

        await saveFamilyToPrefs();
      } else {
        setState(() {
          isLoading = false;
          isFetchingMore = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        isFetchingMore = false;
      });
    }
  }

  void _applySearch() {
    if (searchQuery.isEmpty) {
      _familyMembers = List.from(_allMembers);
    } else {
      _familyMembers = _allMembers.where((member) {
        final name = (member['FullNameEnglish'] ?? '').toLowerCase();
        final addr = (member['VAddressEnglish'] ?? '').toLowerCase();
        final epic = (member['EpicNo'] ?? '').toLowerCase();
        final query = searchQuery.toLowerCase();
        return name.contains(query) ||
            addr.contains(query) ||
            epic.contains(query);
      }).toList();
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      setState(() {
        searchQuery = query;
        _applySearch();
      });
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !isFetchingMore &&
        !isLoading) {
      setState(() {
        isFetchingMore = true;
        pageIndex++;
      });
      fetchFamilyMembers();
    }
  }

  void _deleteFamilyMember(int index) async {
    setState(() {
      final member = _familyMembers[index];
      _allMembers.remove(member);
      _addedMembers.removeWhere((m) => m['VoterId'] == member['VoterId']);
      _deletedMembers.add(member);
      _familyMembers.removeAt(index);
    });
    await saveFamilyToPrefs();
  }

  Future<void> _performShare() async {
    try {
      print("All Members : $_allMembers");

      // 🔹 Generate text for all family members, each voter separated
      final allFamilyDetails = _allMembers
          .map((member) {
            // Ensure MapLink is set
            String mapLink = member['MapLink'] ?? '';
            final boothName = member['BoothNameEnglish'] ?? '';
            if (boothName.isNotEmpty && mapLink.isEmpty) {
              mapLink =
                  "https://www.google.com/maps/search/${Uri.encodeComponent(boothName)}";
              member['MapLink'] = mapLink; // update in the list for share/print
            }

            return 'Name: ${language == "English" ? member['FullNameEnglish'] ?? '' : member['FullNameMarathi'] ?? ''}\n'
                'EPIC: ${member['EpicNo'] ?? ''}\n'
                'Address: ${language == "English" ? member['VAddressEnglish'] ?? '' : member['VAddessMarathi'] ?? ''}\n'
                'Booth: ${language == "English" ? member['BoothNameEnglish'] ?? '' : member['BoothNameMarathi'] ?? ''}\n'
                'Age: ${member['Age'] ?? ''}\n'
                'Gender: ${member['Gender'] ?? ''}\n'
                '${mapLink.isNotEmpty ? '🗺 Map: $mapLink\n' : ''}---';
          })
          .join('\n\n'); // ✅ separate blocks for each voter

      XFile? imageFile;

      if (slipPrintPath != null && slipPrintPath!.isNotEmpty) {
        final response = await http.get(Uri.parse(slipPrintPath!));
        if (response.statusCode == 200) {
          final tempDir = await getTemporaryDirectory();
          final filePath = '${tempDir.path}/voter_image.jpg';
          final file = File(filePath);
          await file.writeAsBytes(response.bodyBytes);
          imageFile = XFile(file.path);
        }
      }

      final shareText = '📋 *Family Details:*\n\n$allFamilyDetails';
      print("shareText : $shareText");

      if (_selectedShareOption == "with") {
        if (_numberController.text.isEmpty) {
          _showSnack("Please enter a number to share with.");
          return;
        }
        final phone = _numberController.text.trim();
        final whatsappUrl =
            "https://wa.me/$phone?text=${Uri.encodeComponent(shareText)}";

        if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
          await launchUrl(
            Uri.parse(whatsappUrl),
            mode: LaunchMode.externalApplication,
          );
        } else {
          _showSnack("Could not open WhatsApp.");
        }
      } else {
        if (imageFile != null) {
          await Share.shareXFiles([imageFile], text: shareText);
        } else {
          await Share.share(shareText);
        }
      }
    } catch (e) {
      debugPrint("Error sharing family details: $e");
      _showSnack("Something went wrong while sharing.");
    }
  }

  void _showShareOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Share Options",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  RadioListTile(
                    title: const Text("Share without number"),
                    value: "without",
                    groupValue: _selectedShareOption,
                    onChanged: (val) {
                      setModalState(() => _selectedShareOption = val!);
                    },
                  ),
                  RadioListTile(
                    title: const Text("Share with number"),
                    value: "with",
                    groupValue: _selectedShareOption,
                    onChanged: (val) {
                      setModalState(() => _selectedShareOption = val!);
                    },
                  ),
                  if (_selectedShareOption == "with")
                    TextField(
                      controller: _numberController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: "Enter WhatsApp Number",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _performShare();
                    },
                    icon: const Icon(Icons.share),
                    label: const Text("Share"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _printFamilyDetails() async {
    final text = _allMembers
        .map((member) {
          final mapLink = member['MapLink'] ?? '';
          return 'Name: ${language == "English" ? member['FullNameEnglish'] ?? '' : member['FullNameMarathi'] ?? ''}\n'
              'EPIC: ${member['EpicNo'] ?? ''}\n'
              'Address: ${language == "English" ? member['VAddressEnglish'] ?? '' : member['VAddressMarathi'] ?? ''}\n'
              'Booth: ${member['BoothName'] ?? ''} (${member['BoothNo'] ?? ''})\n'
              'Age: ${member['Age'] ?? ''}\n'
              'Gender: ${member['Gender'] ?? ''}\n'
              'Father: ${member['FatherName'] ?? ''}\n'
              'Mother: ${member['MotherName'] ?? ''}\n'
              '${mapLink.isNotEmpty ? 'Map: $mapLink\n' : ''}---';
        })
        .join('\n');

    Printing.layoutPdf(
      onLayout: (format) => Printing.convertHtml(
        format: format,
        html:
            "<h1>Family Details</h1><pre>${text.replaceAll('\n', '<br>')}</pre>",
      ),
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Family Details'),
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  onChanged: _onSearchChanged,
                  decoration: const InputDecoration(
                    hintText: "Please search here",
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
            ),
            Expanded(
              child: isLoading
                  ? Center(child: CircularProgressIndicator(color: bgColor1))
                  : Screenshot(
                      controller: screenshotController,
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16.0),
                        itemCount: _familyMembers.length,
                        itemBuilder: (context, index) {
                          final member = _familyMembers[index];
                          return GestureDetector(
                            onTap: () async {
                              // Navigate to VoterDetailsScreen and pass full member details
                              final details = await fetchVoterDetails(
                                member['VoterId'],
                              );
                              if (details != null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => VoterDetailsScreen(
                                      voter: {...member, ...details},
                                    ),
                                  ),
                                );
                              } else {
                                _showSnack(
                                  "No results were found for your search.",
                                );
                              }
                            },
                            child: Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      language == "English"
                                          ? member['FullNameEnglish'] ?? ''
                                          : member['FullNameMarathi'] ?? '',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text("EPIC: ${member['EpicNo'] ?? ''}"),
                                    Text(
                                      "Address: ${language == "English" ? member['VAddressEnglish'] ?? '' : member['VAddressMarathi'] ?? ''}",
                                    ),
                                    if (member['BoothName'] != null)
                                      Text("Booth: ${member['BoothName']}"),
                                    if (member['BoothNo'] != null)
                                      Text("Booth No: ${member['BoothNo']}"),
                                    if (member['Age'] != null)
                                      Text("Age: ${member['Age']}"),
                                    if (member['Gender'] != null)
                                      Text("Gender: ${member['Gender']}"),
                                    if (member['FatherName'] != null)
                                      Text("Father: ${member['FatherName']}"),
                                    if (member['MotherName'] != null)
                                      Text("Mother: ${member['MotherName']}"),
                                    if (member['MapLink'] != null &&
                                        member['MapLink'].toString().isNotEmpty)
                                      GestureDetector(
                                        onTap: () async {
                                          final url = member['MapLink'];
                                          if (await canLaunchUrl(
                                            Uri.parse(url),
                                          )) {
                                            await launchUrl(
                                              Uri.parse(url),
                                              mode: LaunchMode
                                                  .externalApplication,
                                            );
                                          }
                                        },
                                        child: Text(
                                          "View Booth Map",
                                          style: TextStyle(
                                            color: Colors.blue,
                                            decoration:
                                                TextDecoration.underline,
                                          ),
                                        ),
                                      ),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        onPressed: () =>
                                            _deleteFamilyMember(index),
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
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _printFamilyDetails,
                      icon: const Icon(Icons.print),
                      label: const Text("Print"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: bgColor1,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _showShareOptions,
                      icon: const Icon(Icons.share),
                      label: const Text("Share"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: bgColor1,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddVoterListScreen(
                              title: "Add Family",
                              targetVoterId: widget.voter['VoterId'].toString(),
                            ),
                          ),
                        );

                        if (result == true) {
                          setState(() => isLoading = true);

                          // Reload family from prefs (includes newly added members)
                          final prefs = await SharedPreferences.getInstance();
                          final storedFamily = prefs.getString(
                            'family_$voterIdKey',
                          );
                          _allMembers = storedFamily != null
                              ? jsonDecode(storedFamily)
                              : [];

                          // Fetch details for all members that don't have full voter info yet
                          for (int i = 0; i < _allMembers.length; i++) {
                            final member = _allMembers[i];

                            // If member already has BoothName or Age, assume details fetched
                            if (member['BoothNameEnglish'] == null) {
                              final details = await fetchVoterDetails(
                                member['VoterId'],
                              );
                              if (details != null) {
                                _allMembers[i] = {...member, ...details};
                              }
                            }
                          }

                          _applySearch();
                          await saveFamilyToPrefs();

                          setState(() => isLoading = false);

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Family list updated with full voter details",
                              ),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.add),
                      label: const Text("Add"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: bgColor1,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
