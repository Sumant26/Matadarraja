import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:matadarraja/screens/home_screen.dart';

class LoginScreen extends StatefulWidget {
  final Map<String, dynamic>? candidateData;

  const LoginScreen({Key? key, required this.candidateData}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();

  final FocusNode _usernameFocusNode = FocusNode();
  final FocusNode _mobileFocusNode = FocusNode();

  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _candidateData;
  Color _bgColor1 = const Color(0xFFFB8C00);
  Color _bgColor2 = const Color(0xFFF4511E);
  List<Color> _buttonColors = [];
  Future<void> _login() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      setState(() {
        _errorMessage = "No Internet Connection!";
      });
      return;
    }

    if (_usernameController.text.trim().isEmpty ||
        _mobileController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = "Please enter username and mobile number!";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final String apiUrl = "http://api.aoinfotech.com/api/AppUser";

    final Map<String, dynamic> payload = {
      "VoterId": 0,
      "AppUserName": _usernameController.text.trim(),
      "MobileNo": _mobileController.text.trim(),
      "ActivationKey": widget.candidateData?["ActivationKey"] ?? "AO0001",
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "X-ApiKey": "552556497339462MH16BZbr2024",
          "X-MobNo": "8830228583",
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        SharedPreferences prefs = await SharedPreferences.getInstance();

        /// ✅ Always store candidateData (fallback to empty map if null)
        final candidateDataToSave = widget.candidateData ?? {};
        await prefs.setString("candidateData", jsonEncode(candidateDataToSave));

        await prefs.setBool("isLoggedIn", true);

        print("✅ Candidate Data Stored: $candidateDataToSave");
        print("✅ Login flag set to: ${prefs.getBool("isLoggedIn")}");
        setState(() {
          _candidateData = candidateDataToSave;
        });

        await _extractColorsFromAsset();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Login successful!"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        Future.delayed(const Duration(milliseconds: 500), () {
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => HomeScreen()),
          );
        });
      } else {
        setState(() {
          _errorMessage = "Login failed: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Error: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _extractColorsFromAsset() async {
    if (_candidateData == null) {
      setState(() => _isLoading = false);
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final savedBg1 = prefs.getInt('bgColor1');
    final savedBg2 = prefs.getInt('bgColor2');
    final savedButtons = prefs.getStringList('buttonColors');

    if (savedBg1 != null && savedBg2 != null && savedButtons != null) {
      setState(() {
        _bgColor1 = Color(savedBg2);
        _bgColor2 = Color(savedBg1);
        _buttonColors = savedButtons.map((c) => Color(int.parse(c))).toList();
        _isLoading = false;
      });

      // ✅ Print already saved colors
      print("🎨 Loaded Colors from SharedPreferences:");
      print("  bgColor1: $_bgColor1");
      print("  bgColor2: $_bgColor2");
      print("  buttonColors: $_buttonColors");
      return;
    }

    print("Banner Path : ${_candidateData!['BannerPath']}");

    if (_candidateData!['BannerPath'] != null &&
        _candidateData!['BannerPath'].toString().isNotEmpty) {
      final imageProvider = NetworkImage(_candidateData!['BannerPath']);

      try {
        // ✅ Directly generate palette (no Completer needed)
        final palette = await PaletteGenerator.fromImageProvider(
          imageProvider,
          size: const Size(200, 200),
          maximumColorCount: 8,
        );

        setState(() {
          _bgColor1 = palette.dominantColor?.color ?? const Color(0xFFFB8C00);
          _bgColor2 = palette.darkMutedColor?.color ?? const Color(0xFFF4511E);
          _buttonColors = [
            if (palette.lightVibrantColor != null)
              palette.lightVibrantColor!.color,
            if (palette.vibrantColor != null) palette.vibrantColor!.color,
            if (palette.darkVibrantColor != null)
              palette.darkVibrantColor!.color,
          ];
          if (_buttonColors.isEmpty) {
            _buttonColors = [_bgColor1, _bgColor2];
          }
          _isLoading = false;
        });

        // ✅ Save for reuse
        await prefs.setInt('bgColor1', _bgColor1.value);
        await prefs.setInt('bgColor2', _bgColor2.value);
        await prefs.setStringList(
          'buttonColors',
          _buttonColors.map((c) => c.value.toString()).toList(),
        );

        // ✅ Print extracted colors
        print("🎨 Extracted and Saved Colors:");
        print("  bgColor1: $_bgColor1");
        print("  bgColor2: $_bgColor2");
        print("  buttonColors: $_buttonColors");
      } catch (e) {
        debugPrint("❌ Failed to extract colors: $e");
        setState(() => _isLoading = false);
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _mobileController.dispose();
    _usernameFocusNode.dispose();
    _mobileFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFFFB8C00), Color(0xFFF4511E)],
          ),
        ),
        child: Center(
          child: _errorMessage != null
              ? Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                )
              : SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "SOA Technologies",
                        style: TextStyle(
                          fontSize: 30,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        "Election Voter Search Application",
                        style: TextStyle(color: Colors.white, fontSize: 20),
                      ),
                      const SizedBox(height: 10),
                      Stack(
                        alignment: Alignment.topCenter,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                              top: 50.0,
                              right: 15,
                              left: 15,
                            ),
                            child: Card(
                              elevation: 8,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SizedBox(height: 40),
                                    if (widget.candidateData != null) ...[
                                      Text(
                                        widget.candidateData!['CandidateNameEnglish'] ??
                                            "",
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.orangeAccent,
                                        ),
                                      ),
                                    ],
                                    TextField(
                                      controller: _usernameController,
                                      focusNode: _usernameFocusNode,
                                      textInputAction: TextInputAction.next,
                                      onSubmitted: (_) {
                                        FocusScope.of(
                                          context,
                                        ).requestFocus(_mobileFocusNode);
                                      },
                                      decoration: InputDecoration(
                                        filled: true,
                                        hintText: 'Username',
                                        fillColor: Colors.white,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    TextField(
                                      controller: _mobileController,
                                      focusNode: _mobileFocusNode,
                                      textInputAction: TextInputAction.done,
                                      onSubmitted: (_) => _login(),
                                      keyboardType: TextInputType.phone,
                                      decoration: InputDecoration(
                                        filled: true,
                                        hintText: 'Mobile Number',
                                        fillColor: Colors.white,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 30),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 16,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          backgroundColor: Colors.white,
                                          foregroundColor: const Color(
                                            0xFFFB8C00,
                                          ),
                                          textStyle: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        onPressed: _isLoading ? null : _login,
                                        child: _isLoading
                                            ? const CircularProgressIndicator(
                                                color: Color(0xFFFB8C00),
                                              )
                                            : const Text(
                                                'Login',
                                                style: TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.orange,
                            child: CircleAvatar(
                              radius: 46,
                              backgroundImage: NetworkImage(
                                widget.candidateData?['PhotoPath'] ?? "",
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
