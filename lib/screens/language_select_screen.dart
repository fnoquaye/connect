import 'dart:developer';
import 'package:connect/models/languages.dart';
import 'package:connect/screens/homescreen.dart';
import 'package:flutter/material.dart';

import '../APIs/apis.dart';

class LanguageSelectScreen extends StatefulWidget {
  const LanguageSelectScreen({super.key});

  @override
  State<LanguageSelectScreen> createState() => _LanguageSelectScreenState();
}

class _LanguageSelectScreenState extends State<LanguageSelectScreen> {
  // bool _hasInitialized = false;
  String _selectedLang = ''; // default fallback
  void _saveLanguageAndContinue() async {
    if (_selectedLang.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a language before continuing')),
      );
      return;
    }
    await APIS.updateMyPreferredLanguage(_selectedLang);
    log('📤 Saving preferred language: $_selectedLang');
    Navigator.pushReplacement(context, MaterialPageRoute(
      builder: (_) => HomeScreen(), // Replace with your actual home screen
    ));
  }

  @override
  void initState() {
    super.initState();
    log('🌐 Showing Language Selector Screen');
  }


  @override
  Widget build(BuildContext context) {
    log('🧱 Building LanguageSelectScreen UI');
    return Scaffold(
      appBar: AppBar(title: Text('🌍 Select Language')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Choose your preferred language for chats:',
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 30),
            DropdownButton<String>(
              value: _selectedLang.isEmpty ? null : _selectedLang,
              hint: Text('Select a language'),
              isExpanded: true,
              items: LanguageConstants.languageCodes.map((langCode) {
                return DropdownMenuItem(
                  value: langCode,
                  child: Text(LanguageConstants.getFullDisplayName(langCode),
                      style: TextStyle(fontSize: 16)),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedLang = val);
                log('🌐 Language selected: $_selectedLang');
              },
            ),
            SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: _selectedLang.isEmpty ? null : _saveLanguageAndContinue,
              icon: Icon(Icons.check),
              label: Text('Continue'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
