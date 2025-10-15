import 'package:flutter/material.dart';
import 'package:matadarraja/screens/advanced_search_result_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:matadarraja/screens/home_screen.dart';

class AdvancedSeacrhScreen extends StatefulWidget {
  final String title;
  const AdvancedSeacrhScreen({super.key, required this.title});

  @override
  State<AdvancedSeacrhScreen> createState() => _AdvancedSeacrhScreenState();
}

class _AdvancedSeacrhScreenState extends State<AdvancedSeacrhScreen> {
  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _fromAgeController = TextEditingController();
  final _toAgeController = TextEditingController();
  final _mobileNumberController = TextEditingController();
  final _partNumberController = TextEditingController();
  final _voterIdController = TextEditingController();
  final _houseNumberController = TextEditingController();

  Color _primaryColor = Colors.deepOrange;
  Color _textOnPrimary = Colors.white;
  Color _backgroundColor = Colors.white;
  Color _iconColor = Colors.black;
  Color _bgColor1 = Colors.blue;
  Color _bgColor2 = Colors.green;
  bool _isLoading = true;

  String? _globalError; // inline error message

  @override
  void initState() {
    super.initState();
    _loadColorsFromPrefs();
  }

  Future<void> _loadColorsFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final bgColor1Value = prefs.getInt('bgColor1');
    final bgColor2Value = prefs.getInt('bgColor2');

    setState(() {
      if (bgColor1Value != null) {
        _bgColor1 = Color(bgColor1Value);
      }
      if (bgColor2Value != null) {
        _bgColor2 = Color(bgColor2Value);
      }
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _surnameController.dispose();
    _fromAgeController.dispose();
    _toAgeController.dispose();
    _mobileNumberController.dispose();
    _partNumberController.dispose();
    _voterIdController.dispose();
    _houseNumberController.dispose();
    super.dispose();
  }

  bool _atLeastOneFieldFilled() {
    return _firstNameController.text.isNotEmpty ||
        _middleNameController.text.isNotEmpty ||
        _surnameController.text.isNotEmpty ||
        _fromAgeController.text.isNotEmpty ||
        _toAgeController.text.isNotEmpty ||
        _mobileNumberController.text.isNotEmpty ||
        _partNumberController.text.isNotEmpty ||
        _voterIdController.text.isNotEmpty ||
        _houseNumberController.text.isNotEmpty;
  }

  void _performSearch() {
    setState(() {
      _globalError = null;
    });

    if (!_atLeastOneFieldFilled()) {
      setState(() {
        // _globalError = "⚠ Please fill at least one field to search";
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill at least one field to search"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      final params = {
        "FirstName": _firstNameController.text,
        "MiddleName": _middleNameController.text,
        "Lastname": _surnameController.text,
        "FromAge": _fromAgeController.text,
        "ToAge": _toAgeController.text,
        "MobileNo": _mobileNumberController.text,
        "PartNo": _partNumberController.text,
        "EpicNo": _voterIdController.text,
        "HouseNo": _houseNumberController.text,
      };
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AdvancedSearchResultScreen(params: params),
        ),
      );
    }
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
      prefixIcon: Icon(icon, color: _iconColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: languageProvider,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: Text(languageProvider.getText('advanced_search')),
            backgroundColor: _bgColor1,
            foregroundColor: _textOnPrimary,
          ),
          body: Container(
            height: MediaQuery.of(context).size.height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_bgColor2, _bgColor1],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // First Name
                    TextFormField(
                      controller: _firstNameController,
                      decoration:
                          _inputDecoration(
                            languageProvider.getText('first_name'),
                            Icons.person,
                          ).copyWith(
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.6),
                          ),
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          if (value.length < 2) {
                            return 'First name must be at least 2 characters';
                          }
                          if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
                            return 'Only letters and spaces allowed';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Middle Name
                    TextFormField(
                      controller: _middleNameController,
                      decoration:
                          _inputDecoration(
                            languageProvider.getText('middle_name'),
                            Icons.person_outline,
                          ).copyWith(
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.6),
                          ),
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
                            return 'Only letters and spaces allowed';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Surname
                    TextFormField(
                      controller: _surnameController,
                      decoration:
                          _inputDecoration(
                            languageProvider.getText('surname'),
                            Icons.person,
                          ).copyWith(
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.6),
                          ),
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          if (value.length < 2) {
                            return 'Surname must be at least 2 characters';
                          }
                          if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
                            return 'Only letters and spaces allowed';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Age fields
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _fromAgeController,
                            keyboardType: TextInputType.number,
                            decoration:
                                _inputDecoration(
                                  languageProvider.getText('from_age'),
                                  Icons.calendar_today,
                                ).copyWith(
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.6),
                                ),
                            validator: (value) {
                              if (value != null && value.isNotEmpty) {
                                final age = int.tryParse(value);
                                if (age == null || age < 0 || age > 150) {
                                  return 'Enter valid age (0-150)';
                                }
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _toAgeController,
                            keyboardType: TextInputType.number,
                            decoration:
                                _inputDecoration(
                                  languageProvider.getText('to_age'),
                                  Icons.calendar_today,
                                ).copyWith(
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.6),
                                ),
                            validator: (value) {
                              if (value != null && value.isNotEmpty) {
                                final age = int.tryParse(value);
                                if (age == null || age < 0 || age > 150) {
                                  return 'Enter valid age (0-150)';
                                }
                                final fromAge = int.tryParse(
                                  _fromAgeController.text,
                                );
                                if (fromAge != null && age < fromAge) {
                                  return 'To age must be >= From age';
                                }
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Mobile number
                    TextFormField(
                      controller: _mobileNumberController,
                      keyboardType: TextInputType.phone,
                      decoration:
                          _inputDecoration(
                            languageProvider.getText('mobile_number'),
                            Icons.phone,
                          ).copyWith(
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.6),
                          ),
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          if (!RegExp(r'^[0-9]{10}$').hasMatch(value)) {
                            return 'Must be 10 digits';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Part number
                    TextFormField(
                      controller: _partNumberController,
                      keyboardType: TextInputType.number,
                      decoration:
                          _inputDecoration(
                            languageProvider.getText('part_number'),
                            Icons.numbers,
                          ).copyWith(
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.6),
                          ),
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                            return 'Only numbers allowed';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Voter ID
                    TextFormField(
                      controller: _voterIdController,
                      decoration:
                          _inputDecoration(
                            languageProvider.getText('voter_id'),
                            Icons.credit_card,
                          ).copyWith(
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.6),
                          ),
                      validator: (value) {
                        if (value != null &&
                            value.isNotEmpty &&
                            value.length < 3) {
                          return 'At least 3 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // House number
                    TextFormField(
                      controller: _houseNumberController,
                      decoration:
                          _inputDecoration(
                            languageProvider.getText('house_number'),
                            Icons.home,
                          ).copyWith(
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.6),
                          ),
                    ),
                    const SizedBox(height: 24),

                    // Inline global error
                    if (_globalError != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          _globalError!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                    // Search Button
                    ElevatedButton.icon(
                      onPressed: _performSearch,
                      icon: const Icon(Icons.search, color: Colors.white),
                      label: Text(
                        languageProvider.getText('search'),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _textOnPrimary,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _bgColor1,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
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
    );
  }
}
