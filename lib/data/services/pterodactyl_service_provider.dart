import 'pterodactyl_client_api_service.dart';
import './pterodactyl_websocket_service.dart';

/// Pterodactyl Service Provider
/// Singleton provider for API and WebSocket services
class PterodactylServiceProvider {
  static PterodactylServiceProvider? _instance;
  late PterodactylClientApiService apiService;
  late PterodactylWebSocketService webSocketService;

  PterodactylServiceProvider._internal(
      {required String pterodactylBaseUrl,
      required String clientApiKey,
      PterodactylClientApiService? apiService}) {
    this.apiService = apiService ??
        PterodactylClientApiService(
          pterodactylBaseUrl: pterodactylBaseUrl,
          clientApiKey: clientApiKey,
        );
    webSocketService = PterodactylWebSocketService(
      baseUrl: pterodactylBaseUrl,
      apiKey: clientApiKey,
    );
  }

  static void initialize(
      {required String pterodactylBaseUrl,
      required String clientApiKey,
      PterodactylClientApiService? apiService}) {
    _instance = PterodactylServiceProvider._internal(
        pterodactylBaseUrl: pterodactylBaseUrl,
        clientApiKey: clientApiKey,
        apiService: apiService);
  }

  /// Get singleton instance
  static PterodactylServiceProvider get instance {
    if (_instance == null) {
      throw Exception(
        'PterodactylClientApiServiceProvider not initialized. Call initialize() first.',
      );
    }
    return _instance!;
  }

  /// Check if provider is initialized
  static bool get isInitialized => _instance != null;

  /// Dispose services
  void dispose() {
    webSocketService.dispose();
    _instance = null;
  }
}
