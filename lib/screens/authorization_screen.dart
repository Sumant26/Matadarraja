import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:matadarraja/screens/login_screen.dart';

/// ✅ Custom HttpOverrides to allow self-signed certificates
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final HttpClient client = super.createHttpClient(context);
    // ⚠️ Only use in development/testing — NOT for production
    client.badCertificateCallback =
        (X509Certificate cert, String host, int port) => true;
    return client;
  }
}

class AuthorizationScreen extends StatefulWidget {
  const AuthorizationScreen({super.key});

  @override
  State<AuthorizationScreen> createState() => _AuthorizationScreenState();
}

class _AuthorizationScreenState extends State<AuthorizationScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _loading = false;
  bool _noInternet = false;

  @override
  void initState() {
    super.initState();
    // ✅ Apply the override once when app starts
    HttpOverrides.global = MyHttpOverrides();
  }

  Future<void> _fetchCandidateDetails() async {
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
      return;
    } else {
      setState(() {
        _noInternet = false;
      });
    }

    final activationKey = _controller.text.trim().toUpperCase();

    if (activationKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter activation code"),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final url =
        "https://api.aoinfotech.com/api/GetCandidateDetailsByActivationKey?activationKey=$activationKey";

    try {
      setState(() => _loading = true);

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
        dynamic data;
        try {
          data = json.decode(response.body);
        } catch (_) {
          data = {};
        }

        if (data == null || data is! Map) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Invalid response from server"),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }

        final slipPrintEnglish = data['SlipPrintMsgEnglish'];
        final bannerPath = data['BannerPath'];

        if (slipPrintEnglish != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('SlipPrintEnglish', slipPrintEnglish);
          await prefs.setString('BannerPath', bannerPath);
          debugPrint("✅ SlipPrintEnglish stored: $slipPrintEnglish");
          debugPrint("✅ Banner Path stored: $bannerPath");
        } else {
          debugPrint("⚠️ SlipPrintEnglish not found in API response");
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Activation Successful!"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        await Future.delayed(const Duration(seconds: 1));

        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => LoginScreen(candidateData: data)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Invalid Activation Key or Server Error"),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
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
      print("Error : $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Something went wrong: $e"),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFFFB8C00), Color(0xFFF4511E)],
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: constraints.maxWidth < 600
                        ? double.infinity
                        : 400,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
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
                        const SizedBox(height: 10),
                        const Text(
                          "Election Voter Search Application",
                          style: TextStyle(color: Colors.white, fontSize: 20),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _controller,
                          style: const TextStyle(color: Colors.black),
                          textCapitalization: TextCapitalization.characters,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(8),
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[A-Z0-9]'),
                            ),
                          ],
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            hintText: "Enter Activation Key",
                            hintStyle: const TextStyle(color: Colors.grey),
                            floatingLabelBehavior: FloatingLabelBehavior.never,
                            prefixIcon: const Icon(
                              Icons.vpn_key,
                              color: Color(0xFFFB8C00),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 20.0,
                              horizontal: 16.0,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: Colors.white),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: Color(0xFFFB8C00),
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFFFB8C00),
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onPressed: _loading ? null : _fetchCandidateDetails,
                            child: _loading
                                ? const CircularProgressIndicator(
                                    color: Color(0xFFFB8C00),
                                  )
                                : const Text(
                                    'Activate',
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
            );
          },
        ),
      ),
    );
  }
}
