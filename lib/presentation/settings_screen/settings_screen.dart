import 'package:flutter/material.dart';
import 'package:pterodactyl_app/data/services/settings_service.dart';
import 'package:pterodactyl_app/core/app_export.dart';
import 'package:pterodactyl_app/data/services/pterodactyl_service_provider.dart';
import 'package:sizer/sizer.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _basePterodactylBaseUrl = TextEditingController();
  final _clientApiKeyController = TextEditingController();
  final _applicationApiKeyController = TextEditingController();
  final SettingsService _settingsService = SettingsService();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await _settingsService.getSettings();
    _basePterodactylBaseUrl.text = settings['pterodactyBaseUrl'] ?? '';
    _clientApiKeyController.text = settings['clientApiKey'] ?? '';
    _applicationApiKeyController.text = settings['applicationApiKey'] ?? '';
  }

  Future<void> _saveSettings() async {
    if (_formKey.currentState!.validate()) {
      final pterodactyBaseUrl = _basePterodactylBaseUrl.text;
      final clientApiKey = _clientApiKeyController.text;
      final applicationApiKey = _applicationApiKeyController.text;

      await _settingsService.saveSettings(
        pterodactyBaseUrl,
        clientApiKey,
        applicationApiKey,
      );

      PterodactylServiceProvider.initialize(
        pterodactylBaseUrl: pterodactyBaseUrl,
        clientApiKey: clientApiKey,
      );

      Navigator.pushReplacementNamed(context, AppRoutes.serverDashboard);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 3.h),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _basePterodactylBaseUrl,
                decoration: InputDecoration(
                  labelText: 'Base URL',
                  hintText: 'e.g. https://panel.example.com',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the base URL';
                  }
                  if (!Uri.parse(value).isAbsolute) {
                    return 'Please enter a valid URL';
                  }
                  return null;
                },
              ),
              SizedBox(height: 2.h),
              TextFormField(
                controller: _clientApiKeyController,
                decoration: InputDecoration(
                  labelText: 'Client API Key',
                  hintText: 'Enter your Pterodactyl Client API key',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the Client API key';
                  }
                  return null;
                },
              ),
              SizedBox(height: 2.h),
              TextFormField(
                controller: _applicationApiKeyController,
                decoration: InputDecoration(
                  labelText: 'Application API Key',
                  hintText: 'Enter your Pterodactyl Application API key',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                obscureText: true,
                // validator: (value) {
                //   if (value == null || value.isEmpty) {
                //     return 'Please enter the Application API key';
                //   }
                //   return null;
                // },
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _saveSettings,
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 6.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text('Save and Connect'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
