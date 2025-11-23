import 'package:pterodactyl_app/data/services/pterodactyl_service_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'mocks/mock_pterodactyl_client_api_service.mocks.dart';

late MockPterodactylClientApiService mockPterodactylClientApiService;

Future<void> setupTestServiceProvider() async {
  SharedPreferences.setMockInitialValues({});
  mockPterodactylClientApiService = MockPterodactylClientApiService();
  PterodactylServiceProvider.initialize(
      pterodactylBaseUrl: 'https://example.com',
      clientApiKey: 'test_api_key',
      apiService: mockPterodactylClientApiService);
}
