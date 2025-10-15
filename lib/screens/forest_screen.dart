import 'package:flutter/material.dart';
import 'package:matadarraja/screens/home_screen.dart';

class ForestScreen extends StatefulWidget {
  final String title;
  const ForestScreen({super.key, required this.title});

  @override
  State<ForestScreen> createState() => _ForestScreenState();
}

class _ForestScreenState extends State<ForestScreen> {
  String _selectedLanguage = 'English';

  @override
  void initState() {
    super.initState();
    // Show the dialog when the screen is first opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showLanguageDialog();
    });
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text(
                languageProvider.getText('select_your_language'),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<String>(
                    title: Text(languageProvider.getText('english')),
                    value: 'English',
                    groupValue: _selectedLanguage,
                    onChanged: (String? value) {
                      setState(() {
                        _selectedLanguage = value!;
                      });
                    },
                    activeColor: Colors.deepOrange,
                  ),
                  RadioListTile<String>(
                    title: Text(languageProvider.getText('marathi')),
                    value: 'Marathi',
                    groupValue: _selectedLanguage,
                    onChanged: (String? value) {
                      setState(() {
                        _selectedLanguage = value!;
                      });
                    },
                    activeColor: Colors.deepOrange,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    languageProvider.getText('cancel'),
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    languageProvider.changeLanguage(_selectedLanguage);
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${languageProvider.getText('language_changed_to')} ${languageProvider.getText(_selectedLanguage.toLowerCase())}',
                        ),
                        backgroundColor: Colors.deepOrange,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(languageProvider.getText('save')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.lightGreen,
                borderRadius: BorderRadius.circular(100),
              ),
              child: const Icon(Icons.forest, size: 100, color: Colors.white),
            ),
            const SizedBox(height: 20),
            Text(
              'Welcome to ${widget.title}',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Discover the peace of nature',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _showLanguageDialog,
              icon: const Icon(Icons.language),
              label: Text(languageProvider.getText('change_language')),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
