import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _basePterodactylUrl = 'basePterodactylUrl';
  static const String _clientApiKey = 'clientApiKey';
  static const String _applicationApiKey = 'applicationApiKey';

  Future<void> saveSettings(String baseUrl, String clientApiKey, String applicationApiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_basePterodactylUrl, baseUrl);
    await prefs.setString(_clientApiKey, clientApiKey);
    await prefs.setString(_applicationApiKey, applicationApiKey);
  }

  Future<Map<String, String?>> getSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final basePterodactylUrl = prefs.getString(_basePterodactylUrl);
    final clientApiKey = prefs.getString(_clientApiKey);
    final applicationApiKey = prefs.getString(_applicationApiKey);
    return {
      'basePterodactylUrl': basePterodactylUrl,
      'clientApiKey': clientApiKey,
      'applicationApiKey': applicationApiKey,
    };
  }

  Future<bool> hasRequiredSettings() async {
    final settings = await getSettings();
    return settings['basePterodactylUrl'] != null && settings['clientApiKey'] != null;
  }
}
