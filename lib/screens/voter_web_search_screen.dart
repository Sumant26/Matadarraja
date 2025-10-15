import 'dart:io';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

class VoterWebSearchScreen extends StatefulWidget {
  const VoterWebSearchScreen({super.key});

  @override
  State<VoterWebSearchScreen> createState() => _VoterWebSearchScreenState();
}

class _VoterWebSearchScreenState extends State<VoterWebSearchScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController fatherNameController = TextEditingController();

  WebViewController? _controller; // nullable instead of late
  bool _isPageLoaded = false;

  @override
  void initState() {
    super.initState();

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() => _isPageLoaded = false);
          },
          onPageFinished: (url) {
            setState(() => _isPageLoaded = true);
          },
        ),
      )
      ..loadRequest(Uri.parse("https://electoralsearch.eci.gov.in/"));

    _controller = controller;
  }

  Future<void> _fillAndSearch() async {
    if (!_isPageLoaded || _controller == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please wait until the page loads")),
      );
      return;
    }

    final name = nameController.text;
    final father = fatherNameController.text;

    final jsCode =
        """
      (function(){
        const nameInput = document.querySelector('input[formcontrolname="name"]');
        const fatherInput = document.querySelector('input[formcontrolname="rln_name"]');
        if(nameInput) { nameInput.value = "$name"; nameInput.dispatchEvent(new Event('input')); }
        if(fatherInput) { fatherInput.value = "$father"; fatherInput.dispatchEvent(new Event('input')); }
        const btn = document.querySelector('button[type="submit"]');
        if(btn) btn.click();
      })();
    """;

    await _controller!.runJavaScript(jsCode);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Voter Web Search")),
      body: Column(
        children: [
          // Padding(
          //   padding: const EdgeInsets.all(8),
          //   child: Column(
          //     children: [
          //       TextFormField(
          //         controller: nameController,
          //         decoration: const InputDecoration(labelText: "Name"),
          //       ),
          //       TextFormField(
          //         controller: fatherNameController,
          //         decoration: const InputDecoration(labelText: "Father's Name"),
          //       ),
          //       const SizedBox(height: 8),
          //       ElevatedButton(
          //         onPressed: _fillAndSearch,
          //         child: const Text("Search"),
          //       ),
          //     ],
          //   ),
          // ),
          Expanded(
            child: _controller == null
                ? const Center(child: CircularProgressIndicator())
                : Stack(
                    children: [
                      WebViewWidget(controller: _controller!),
                      if (!_isPageLoaded)
                        const Center(child: CircularProgressIndicator()),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
