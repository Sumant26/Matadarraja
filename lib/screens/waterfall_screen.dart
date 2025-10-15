import 'package:flutter/material.dart';
import 'package:matadarraja/screens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WaterfallScreen extends StatefulWidget {
  final String title;
  final Map<String, dynamic>? candidateData;
  const WaterfallScreen({
    super.key,
    required this.title,
    required this.candidateData,
  });

  @override
  State<WaterfallScreen> createState() => WaterfallScreenState();
}

class WaterfallScreenState extends State<WaterfallScreen> {
  Color bgColor1 = Colors.blue;
  Color bgColor2 = Colors.green;
  bool isLoading = true;
  int _shareCount = 0;
  int _printCount = 0;
  @override
  void initState() {
    super.initState();
    print("Candiate Data : ${widget.candidateData}");
    loadColorsFromPrefs();
  }

  /// Load saved counter from SharedPreferences
  Future<void> _loadCount() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _shareCount = prefs.getInt('shareCount') ?? 0;
      _printCount = prefs.getInt('printCount') ?? 0;
    });
  }

  Future<void> loadColorsFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final bgColor1Value = prefs.getInt('bgColor1');
    final bgColor2Value = prefs.getInt('bgColor2');

    setState(() {
      if (bgColor1Value != null) {
        bgColor1 = Color(bgColor1Value);
      }
      if (bgColor2Value != null) {
        bgColor2 = Color(bgColor2Value);
      }
      isLoading = false;
    });
  }

  /// Helper to remove underscores from the fetched text
  String removeUnderscores(String key) {
    return languageProvider.getText(key).replaceAll('_', ' ');
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: languageProvider,
      builder: (context, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(removeUnderscores('user_log')),
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(height: MediaQuery.of(context).size.height / 11),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        removeUnderscores('Print_and_Share_Count'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),

                      Text(
                        widget.candidateData!['CandidateNameEnglish'] ?? "",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),

                      Text(
                        widget.candidateData!['PhNo'] ?? "",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 30),

                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(
                            children: [
                              Card(
                                child: Container(
                                  width: MediaQuery.sizeOf(context).width,
                                  height: 150,
                                  decoration: BoxDecoration(color: bgColor1),
                                  child: Center(
                                    child: Text(
                                      _shareCount.toString(),
                                      style: TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                removeUnderscores('share_report'),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          Divider(),
                          SizedBox(height: 15),
                          Column(
                            children: [
                              Container(
                                width: MediaQuery.sizeOf(context).width,
                                height: 150,
                                decoration: BoxDecoration(color: bgColor1),
                                child: Center(
                                  child: Text(
                                    _printCount.toString(),
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                removeUnderscores('print_report'),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 5),
                Text(removeUnderscores('election_voter_search_application')),
              ],
            ),
          ),
        );
      },
    );
  }
}
