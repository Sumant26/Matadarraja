import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:matadarraja/screens/voter_web_search_screen.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:matadarraja/screens/advanced_seacrh_screen.dart';
import 'package:matadarraja/screens/voter_list_screen.dart';
import 'package:matadarraja/screens/desert_screen.dart';
import 'package:matadarraja/screens/graph_screen.dart';
import 'package:matadarraja/screens/profile_screen.dart';
import 'package:matadarraja/screens/snow_screen.dart';
import 'package:matadarraja/screens/waterfall_screen.dart';
import 'package:matadarraja/screens/authorization_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 🌐 Language Provider
class LanguageProvider extends ChangeNotifier {
  String _currentLanguage = 'English';
  String get currentLanguage => _currentLanguage;

  void changeLanguage(String language) {
    _currentLanguage = language;
    notifyListeners();
  }

  static const Map<String, String> english = {
    'advanced_search': 'Advanced Search',
    'search': 'Search',
    'graph': 'Graph',
    'logout': 'Log Out',
    'language': 'Language',
    'candidate_profile': 'Candidate Profile',
    'about_soa': 'About SOA',
    'user_logs': 'User Logs',
    'election_voter_search_application':
        'Election Voter Search Application by SOA Technologies',
    'select_your_language': 'Select Your Language',
    'english': 'English',
    'marathi': 'Marathi',
    'cancel': 'Cancel',
    'save': 'Save',
    'language_changed_to': 'Language changed to',
    'welcome_to': 'Welcome to',
    'voter_web_search': 'Voter Web Search',
    'voter_details': 'Voter Details',
    'voter information': 'voter information',
  };

  static const Map<String, String> marathi = {
    'advanced_search': 'विस्तृत शोध',
    'search': 'शोधा',
    'graph': 'शहर दिवे',
    'logout': 'लॉगआउट',
    'language': 'भाषा',
    'candidate_profile': 'उमेदवार प्रोफाइल',
    'about_soa': 'SOA बद्दल',
    'user_logs': 'वापरकर्ता लॉग्स',
    'election_voter_search_application':
        'एसओए टेक्नॉलॉजीज द्वारा निवडणूक मतदार शोध अनुप्रयोग',
    'select_your_language': 'तुमची भाषा निवडा',
    'english': 'इंग्रजी',
    'marathi': 'मराठी',
    'cancel': 'रद्द करा',
    'save': 'जतन करा',
    'language_changed_to': 'भाषा बदलली',
    'welcome_to': 'स्वागत आहे',
    'voter_web_search': 'मतदार वेब शोध',
    'voter_details': 'तपशील पहा',
    'voter_information': 'मतदार माहिती',
  };

  String getText(String key) {
    if (_currentLanguage == 'Marathi') {
      return marathi[key] ?? english[key] ?? key;
    }
    return english[key] ?? key;
  }
}

final languageProvider = LanguageProvider();

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _candidateData;
  String _selectedLanguage = 'English';

  bool _isLoading = true;
  Color bgColor1 = Colors.blue;
  Color bgColor2 = Colors.green;
  String? slipPrintPath;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await loadColorsFromPrefs();
    await _loadCandidateData();
    setState(() {
      _isLoading = false; // ✅ Ensure loading completes
    });
  }

  Future<void> _loadCandidateData() async {
    final prefs = await SharedPreferences.getInstance();
    final candidateString = prefs.getString('candidateData');

    if (candidateString != null) {
      setState(() {
        _candidateData = Map<String, dynamic>.from(jsonDecode(candidateString));
      });
      print("Slip : $_candidateData");
    } else {
      print("❌ No candidate data found in SharedPreferences!");
      setState(() => _isLoading = false);
    }
  }

  Future<void> loadColorsFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final bgColor1Value = prefs.getInt('bgColor1');
    print("bgColor1 : $bgColor1Value");
    final bgColor2Value = prefs.getInt('bgColor2');
    print("bgColor2 : $bgColor2Value");
    slipPrintPath = prefs.getString('BannerPath');
    print("slipPrintPath : $slipPrintPath");
    setState(() {
      if (bgColor1Value != null) bgColor1 = Color(bgColor1Value);
      if (bgColor2Value != null) bgColor2 = Color(bgColor2Value);
    });
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text(languageProvider.getText('select_your_language')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<String>(
                    title: Text(languageProvider.getText('english')),
                    value: 'English',
                    groupValue: _selectedLanguage,
                    onChanged: (String? value) {
                      setState(() => _selectedLanguage = value!);
                    },
                  ),
                  RadioListTile<String>(
                    title: Text(languageProvider.getText('marathi')),
                    value: 'Marathi',
                    groupValue: _selectedLanguage,
                    onChanged: (String? value) {
                      setState(() => _selectedLanguage = value!);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(languageProvider.getText('cancel')),
                ),
                ElevatedButton(
                  onPressed: () async {
                    languageProvider.changeLanguage(_selectedLanguage);
                    print("Selected Language : $_selectedLanguage");
                    Navigator.of(context).pop();
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString("language", _selectedLanguage);
                  },
                  child: Text(languageProvider.getText('save')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> logoutUser(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("isLoggedIn", false);
    await prefs.remove('activation_token');
    await prefs.remove('bgColor1');
    await prefs.remove('bgColor2');
    await prefs.remove('candidateData');

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthorizationScreen()),
      (route) => false,
    );
  }

  Future<void> _navigateToScreen(BuildContext context, String title) async {
    switch (title.toLowerCase()) {
      case 'advanced search':
      case 'विस्तृत शोध':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AdvancedSeacrhScreen(title: title)),
        );
        break;

      case 'search':
      case 'शोधा':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => BeachScreen(title: title)),
        );
        break;

      case 'graph':
      case 'शहर दिवे':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => GraphScreen(title: title)),
        );
        break;

      case 'voter web search':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const VoterWebSearchScreen()),
        );
        break;

      case 'log out':
      case 'लॉगआउट':
        await logoutUser(context);
        return;

      case 'language':
      case 'भाषा':
        _showLanguageDialog(context);
        break;

      case 'candidate profile':
      case 'उमेदवार प्रोफाइल':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProfileScreen(candidateData: _candidateData),
          ),
        );
        break;

      case 'about soa':
      case 'वाळवंट':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DesertScreen(title: title)),
        );
        break;

      case 'user logs':
      case 'वापरकर्ता लॉग्स':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                WaterfallScreen(title: title, candidateData: _candidateData),
          ),
        );
        break;

      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${languageProvider.getText('welcome_to')} $title'),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
          ),
        ),
      );
    }

    if (_candidateData == null) {
      return Scaffold(
        body: Center(
          child: Text(
            "No candidate data found. Please login again.",
            style: TextStyle(fontSize: 18),
          ),
        ),
      );
    }

    double screenH = MediaQuery.of(context).size.height;
    double screenW = MediaQuery.of(context).size.width;

    return Stack(
      children: [
        ListenableBuilder(
          listenable: languageProvider,
          builder: (context, _) {
            final items = [
              {
                'title': languageProvider.getText('language'),
                'icon': Icons.language,
                'color': bgColor1,
              },
              {
                'title': languageProvider.getText('candidate_profile'),
                'icon': Icons.account_circle,
                'color': bgColor1,
              },
              {
                'title': languageProvider.getText('about_soa'),
                'icon': Icons.info_outline,
                'color': bgColor1,
              },
              {
                'title': languageProvider.getText('user_logs'),
                'icon': Icons.note,
                'color': bgColor1,
              },
              {
                'title': languageProvider.getText('logout'),
                'icon': Icons.logout,
                'color': bgColor1,
              },
            ];

            final searchItems = [
              {
                'title': languageProvider.getText('search'),
                'icon': Icons.search,
                'color': bgColor1,
              },
              {
                'title': languageProvider.getText('advanced_search'),
                'icon': Icons.manage_search,
                'color': bgColor1,
              },
              {
                'title': languageProvider.getText('graph'),
                'icon': Icons.graphic_eq,
                'color': bgColor1,
              },
              {
                'title': languageProvider.getText('voter_web_search'),
                'icon': Icons.public,
                'color': bgColor1,
              },
            ];

            return Scaffold(
              body: Stack(
                children: [
                  Column(
                    children: [
                      SizedBox(
                        height: 400,
                        width: double.infinity,
                        child: Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomRight,
                                  end: Alignment.bottomLeft,
                                  colors: [bgColor1, bgColor2],
                                ),
                              ),
                              width: double.infinity,
                              height: double.infinity,
                              child: Center(
                                child: Image.network(
                                  _candidateData!['BannerPath'] ?? "",
                                  fit: BoxFit.contain,
                                  width: double.infinity,
                                  height: double.infinity,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 16,
                              right: 16,
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ProfileScreen(
                                        candidateData: _candidateData,
                                      ),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(30),
                                child: CircleAvatar(
                                  radius: 12,
                                  backgroundColor: Colors.white.withOpacity(
                                    0.8,
                                  ),
                                  child: const Icon(
                                    Icons.person,
                                    color: Colors.black87,
                                    size: 26,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [bgColor2, bgColor1],
                            ),
                          ),
                          child: Column(
                            children: [
                              Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 4,
                                margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                    horizontal: 8,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: searchItems.map((item) {
                                      return GestureDetector(
                                        onTap: () => _navigateToScreen(
                                          context,
                                          item['title'] as String,
                                        ),
                                        child: Column(
                                          children: [
                                            Container(
                                              width: screenW * 0.13,
                                              height: screenW * 0.13,
                                              decoration: BoxDecoration(
                                                color: item['color'] as Color,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Icon(
                                                item['icon'] as IconData,
                                                color: Colors.white,
                                                size: screenW * 0.07,
                                              ),
                                            ),
                                            SizedBox(height: screenH * 0.005),
                                            Text(
                                              item['title'] as String,
                                              style: TextStyle(
                                                fontSize: screenW * 0.03,
                                              ),
                                              textAlign: TextAlign.center,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),

                              // ✅ Candidate Profile, User Logs, About SOA (equal height)
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    12,
                                    0,
                                    12,
                                    12,
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          for (var key in [
                                            'candidate_profile',
                                            'user_logs',
                                            'about_soa',
                                          ])
                                            Expanded(
                                              child: GestureDetector(
                                                onTap: () => _navigateToScreen(
                                                  context,
                                                  languageProvider.getText(key),
                                                ),
                                                child: SizedBox(
                                                  height: screenH * 0.15,
                                                  child: Card(
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                                    elevation: 4,
                                                    margin:
                                                        const EdgeInsets.all(6),
                                                    child: Padding(
                                                      padding: EdgeInsets.all(
                                                        screenW * 0.04,
                                                      ),
                                                      child: Column(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          Icon(
                                                            items.firstWhere(
                                                                  (e) =>
                                                                      e['title'] ==
                                                                      languageProvider
                                                                          .getText(
                                                                            key,
                                                                          ),
                                                                )['icon']
                                                                as IconData,
                                                            size:
                                                                screenW * 0.09,
                                                            color: bgColor1,
                                                          ),
                                                          SizedBox(
                                                            height:
                                                                screenH * 0.01,
                                                          ),
                                                          Text(
                                                            languageProvider
                                                                .getText(key),
                                                            textAlign: TextAlign
                                                                .center,
                                                            style: TextStyle(
                                                              fontSize:
                                                                  screenW *
                                                                  0.035,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      SizedBox(height: screenH * 0.01),

                                      // ✅ Language and Logout (equal height too)
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          for (var key in [
                                            'language',
                                            'logout',
                                          ])
                                            Expanded(
                                              child: GestureDetector(
                                                onTap: () => _navigateToScreen(
                                                  context,
                                                  languageProvider.getText(key),
                                                ),
                                                child: SizedBox(
                                                  height: screenH * 0.13,
                                                  child: Card(
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                                    elevation: 4,
                                                    margin:
                                                        const EdgeInsets.all(6),
                                                    child: Padding(
                                                      padding: EdgeInsets.all(
                                                        screenW * 0.04,
                                                      ),
                                                      child: Column(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          Icon(
                                                            items.firstWhere(
                                                                  (e) =>
                                                                      e['title'] ==
                                                                      languageProvider
                                                                          .getText(
                                                                            key,
                                                                          ),
                                                                )['icon']
                                                                as IconData,
                                                            size:
                                                                screenW * 0.08,
                                                            color: bgColor1,
                                                          ),
                                                          SizedBox(
                                                            height:
                                                                screenH * 0.01,
                                                          ),
                                                          Text(
                                                            languageProvider
                                                                .getText(key),
                                                            textAlign: TextAlign
                                                                .center,
                                                            style: TextStyle(
                                                              fontSize:
                                                                  screenW *
                                                                  0.032,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        color: Colors.white,
                        padding: EdgeInsets.all(screenW * 0.03),
                        child: Text(
                          languageProvider.getText(
                            'election_voter_search_application',
                          ),
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: screenW * 0.035),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
