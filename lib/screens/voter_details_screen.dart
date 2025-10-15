import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:matadarraja/screens/family_details_screen.dart';
import 'package:matadarraja/screens/same_address_voter_list_screen.dart';
import 'package:matadarraja/screens/same_booth_voter_list_screen.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:permission_handler/permission_handler.dart'; // ✅ Added
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:image/image.dart' as img;
import 'package:matadarraja/screens/home_screen.dart'; // ✅ Import LanguageProvider

class VoterDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> voter;

  const VoterDetailsScreen({super.key, required this.voter});

  @override
  State<VoterDetailsScreen> createState() => _VoterDetailsScreenState();
}

class _VoterDetailsScreenState extends State<VoterDetailsScreen> {
  Color bgColor1 = Colors.blue;
  Color bgColor2 = Colors.green;
  bool isLoading = true;
  String? slipPrintPath;
  String? language;
  int _shareCount = 0;
  int _printCount = 0;

  final ScreenshotController screenshotController = ScreenshotController();
  String _selectedShareOption = "without";
  final TextEditingController _numberController = TextEditingController();

  Map<String, dynamic>? voterDetails;

  @override
  void initState() {
    super.initState();
    loadColorsFromPrefs();
    fetchVoterDetails();
  }

  Future<void> fetchVoterDetails() async {
    try {
      final voterId = widget.voter['VoterId'] ?? 1001;
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
        print("Data : $data");
        if (mounted) {
          setState(() {
            voterDetails = data;
            isLoading = false;
          });
        }
      } else {
        debugPrint("Failed to fetch voter details: ${response.statusCode}");
        if (mounted) setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint("Error fetching voter details: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> loadColorsFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final bgColor1Value = prefs.getInt('bgColor1');
    final bgColor2Value = prefs.getInt('bgColor2');
    slipPrintPath = prefs.getString('BannerPath');
    language = prefs.getString('language');
    print("Language : $language");
    if (mounted) {
      setState(() {
        if (bgColor1Value != null) bgColor1 = Color(bgColor1Value);
        if (bgColor2Value != null) bgColor2 = Color(bgColor2Value);
      });
    }
  }

  Future<void> _incrementShareCount() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _shareCount++);
    await prefs.setInt('shareCount', _shareCount);
  }

  Future<void> _incrementPrintCount() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _printCount++);
    await prefs.setInt('printCount', _printCount);
  }

  String _buildVoterText() {
    final v = voterDetails ?? widget.voter;
    final mapLink =
        "https://www.google.com/maps/search/${Uri.encodeComponent(v['BoothNameEnglish'] ?? '')}";
    return '''
Voter Information

Name (English): ${language == "English" ? v['FullNameEnglish'] ?? '' : v['FullNameMarathi'] ?? ''}
Epic No: ${v['EpicNo'] ?? ''}
Serial ID: ${v['SlNoInPart'] ?? ''}
Part No: ${v['PartNo'] ?? ''}
Booth Address: ${language == "English" ? v['BoothNameEnglish'] ?? '' : v['BoothNameMarathi'] ?? ''}
Sl No In Part: ${v['SlNoInPart'] ?? ''}
Booth Map Link: $mapLink
''';
  }

  Future<void> _performShare() async {
    _incrementShareCount();
    try {
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

      final voterText = _buildVoterText();
      String locationLink = "";
      if (widget.voter['Latitude'] != null &&
          widget.voter['Longitude'] != null) {
        final lat = widget.voter['Latitude'];
        final lng = widget.voter['Longitude'];
        locationLink =
            "\nLocation: https://www.google.com/maps/search/?api=1&query=$lat,$lng";
      }

      if (_selectedShareOption == "with") {
        if (_numberController.text.isEmpty) {
          showSnack(context, "Please enter a number to share with.");
          return;
        }
        final phone = _numberController.text.trim();
        String finalText;
        if (imageFile != null) {
          finalText = "$voterText$locationLink";
        } else {
          finalText =
              "${widget.voter['SlipPrintEnglish'] ?? ''}\n$voterText$locationLink";
        }

        final whatsappUrl =
            "https://wa.me/$phone?text=${Uri.encodeComponent(finalText)}";
        if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
          await launchUrl(
            Uri.parse(whatsappUrl),
            mode: LaunchMode.externalApplication,
          );
        } else {
          showSnack(context, "Could not open WhatsApp.");
        }
      } else {
        if (imageFile != null) {
          await Share.shareXFiles([imageFile], text: "$voterText$locationLink");
        } else {
          final slipText = widget.voter['SlipPrintEnglish'] ?? '';
          await Share.share("$slipText\n$voterText$locationLink");
        }
      }
    } catch (e) {
      debugPrint("Error sharing voter details: $e");
      showSnack(context, "Error sharing voter details");
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
                      setModalState(() {
                        _selectedShareOption = val!;
                      });
                    },
                  ),
                  RadioListTile(
                    title: const Text("Share with number"),
                    value: "with",
                    groupValue: _selectedShareOption,
                    onChanged: (val) {
                      setModalState(() {
                        _selectedShareOption = val!;
                      });
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

  // ✅ Request Bluetooth + Nearby Permissions
  Future<bool> _checkBluetoothPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetooth,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.location,
    ].request();

    bool allGranted = statuses.values.every((status) => status.isGranted);

    if (!allGranted) {
      bool permanentlyDenied = statuses.values.any(
        (status) => status.isPermanentlyDenied,
      );
      if (permanentlyDenied) {
        showSnack(
          context,
          "Bluetooth permission permanently denied. Open settings.",
        );
        await openAppSettings();
      } else {
        showSnack(context, "Bluetooth permission denied.");
      }
      return false;
    }
    return true;
  }

  // ✅ Updated Print Method with permission handling
  // ✅ Updated Print Method with image + text
  Future<void> _printVoterDetails() async {
    _incrementPrintCount();

    bool hasPermission = await _checkBluetoothPermissions();
    if (!hasPermission) return;

    try {
      final textToPrint = _buildVoterText();
      List<BluetoothInfo> devices =
          await PrintBluetoothThermal.pairedBluetooths;

      if (devices.isEmpty) {
        showSnack(context, "No Bluetooth printers found.");
        return;
      }

      if (!mounted) return;
      BluetoothInfo? selectedPrinter = await showDialog<BluetoothInfo>(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Select Printer"),
            content: SizedBox(
              width: double.maxFinite,
              height: 250,
              child: ListView.builder(
                itemCount: devices.length,
                itemBuilder: (context, index) {
                  final printer = devices[index];
                  return ListTile(
                    title: Text(printer.name ?? "Unknown Printer"),
                    subtitle: Text(printer.macAdress ?? ""),
                    onTap: () => Navigator.pop(context, printer),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
            ],
          );
        },
      );

      if (selectedPrinter == null) {
        showSnack(context, "Printer selection cancelled.");
        return;
      }

      bool connected = await PrintBluetoothThermal.connect(
        macPrinterAddress: selectedPrinter.macAdress,
      );

      if (!connected) {
        showSnack(context, "Failed to connect to ${selectedPrinter.name}");
        return;
      }

      // ✅ Print image first, then voter details text
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm80, profile);
      List<int> bytes = [];

      try {
        if (slipPrintPath != null && slipPrintPath!.isNotEmpty) {
          final response = await http.get(Uri.parse(slipPrintPath!));
          if (response.statusCode == 200) {
            final imageBytes = response.bodyBytes;
            final decoded = img.decodeImage(imageBytes);
            if (decoded != null) {
              final resized = img.copyResize(decoded, width: 512);
              bytes += generator.image(resized);
              bytes += generator.feed(1); // small space after image
            }
          }
        }
      } catch (e) {
        debugPrint("❌ Error loading/printing image: $e");
      }

      // ✅ Then print voter details below the image
      bytes += generator.text(
        textToPrint,
        styles: PosStyles(
          align: PosAlign.left,
          height: PosTextSize.size1,
          width: PosTextSize.size1,
        ),
        linesAfter: 2,
      );

      // ✅ Feed paper a bit at the end
      bytes += generator.feed(3);

      final bool wrote = await PrintBluetoothThermal.writeBytes(bytes);
      if (wrote) {
        showSnack(context, "Printed successfully on ${selectedPrinter.name}");
      } else {
        showSnack(
          context,
          "Printer rejected data (writeBytes returned false).",
        );
      }

      await PrintBluetoothThermal.disconnect;
    } catch (e, st) {
      debugPrint("Error printing: $e\n$st");
      if (mounted) {
        showSnack(context, "Error printing details: $e");
      }
    }
  }

  // ------------------ UI PART ------------------
  @override
  Widget build(BuildContext context) {
    final voter = voterDetails ?? widget.voter;

    return ListenableBuilder(
      listenable: languageProvider,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(voter['FullNameEnglish'] ?? 'Voter Details'),
            backgroundColor: bgColor1,
            foregroundColor: Colors.white,
          ),
          body: isLoading
              ? const Center(child: CircularProgressIndicator())
              : Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [bgColor2, bgColor1],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Screenshot(
                          controller: screenshotController,
                          child: Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    languageProvider.getText(
                                      'voter_information',
                                    ),
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  buildDetailRow(
                                    'Epic No',
                                    voter['EpicNo'] ?? '',
                                  ),
                                  buildDetailRow(
                                    'Name',
                                    language == "English"
                                        ? voter['FullNameEnglish'] ?? ''
                                        : voter['FullNameMarathi'] ?? '',
                                  ),
                                  buildDetailRow(
                                    'Age',
                                    voter['Age']?.toString() ?? '',
                                  ),
                                  buildDetailRow(
                                    'Gender',
                                    voter['Gender'] ?? '',
                                  ),
                                  buildDetailRow(
                                    'Address',
                                    language == "English"
                                        ? voter['VAddressEnglish'] ?? ''
                                        : voter['VAddessMarathi'] ?? '',
                                  ),
                                  buildDetailRow(
                                    'Booth Address',
                                    language == "English"
                                        ? voter['BoothNameEnglish'] ?? ''
                                        : voter['BoothNameMarathi'] ?? '',
                                  ),
                                  buildDetailRow(
                                    'Booth ID',
                                    voter['BoothId']?.toString() ?? '',
                                  ),
                                  buildDetailRow(
                                    'Part Number',
                                    voter['PartNo']?.toString() ?? '',
                                  ),
                                  buildDetailRow(
                                    'Sl No In Part',
                                    voter['SlNoInPart']?.toString() ?? '',
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _showShareOptions,
                                icon: const Icon(Icons.share),
                                label: const Text('Share'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: bgColor1,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _printVoterDetails,
                                icon: const Icon(Icons.print),
                                label: const Text('Print'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: bgColor1,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Column(
                          children: [
                            buildNavButton(
                              Icons.family_restroom,
                              'Family Details',
                              () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        FamilyDetailsScreen(voter: voter),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 12),
                            buildNavButton(
                              Icons.location_on,
                              'Voters on Same Address',
                              () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        SameAddressVoterListScreen(
                                          title: "Voters on Same Address",
                                          voterId: voter['VoterId'],
                                        ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 12),
                            buildNavButton(
                              Icons.poll,
                              'Voters on Same Booth',
                              () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        SameBoothVoterListScreen(
                                          title: "Voters on Booth Address",
                                          voterId: voter['VoterId'],
                                        ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }

  Widget buildNavButton(IconData icon, String text, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(text),
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor1,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  void showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: "$label: ",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
                fontSize: 16,
              ),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(color: Colors.black, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
