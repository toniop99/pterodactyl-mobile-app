import 'package:pterodactyl_app/core/logger.dart';

import 'package:dio/dio.dart';
import '../models/backup_model.dart';
import '../models/file_model.dart';
import '../models/server_model.dart';

class PterodactylClientApiService {
  late final Dio _dio;
  final String pterodactylBaseUrl;
  final String clientApiKey;

  PterodactylClientApiService({
    required this.pterodactylBaseUrl,
    required this.clientApiKey,
  }) {
    _dio = Dio(
      BaseOptions(
        baseUrl: pterodactylBaseUrl,
        headers: {
          'Accept': 'Application/vnd.pterodactyl.v1+json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $clientApiKey',
        },
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );

    // Add interceptors for logging and error handling
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          AppLogger.debug('🌐 API Request: ${options.method} ${options.path}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          AppLogger.info(
              '✅ API Response: ${response.statusCode} ${response.requestOptions.path}');
          return handler.next(response);
        },
        onError: (error, handler) {
          AppLogger.error('❌ API Error: ${error.response?.statusCode} ${error.message}');
          return handler.next(error);
        },
      ),
    );
  }

  /// Get list of all servers for the authenticated user
  Future<List<ServerModel>> getServers() async {
    try {
      final response = await _dio.get('/api/client');
      final data = response.data['data'] as List;

      final serverModels = await Future.wait(
        data.map((json) async {
          final server = ServerModel.fromJson(json);
          final resources = await getServerResources(server.identifier);

          return server.copyWith(
            resources: resources, 
            status: ServerStatus.fromString(resources.currentState)
          );
        })
      );

      serverModels.sort(
        (a, b) {
          final aPriority = ServerStatus.getPriority(a.status);
          final bPriority = ServerStatus.getPriority(b.status);
          if (aPriority != bPriority) {
            return aPriority.compareTo(bPriority);
          }
          return a.name.compareTo(b.name);
        }
      );

      return serverModels;

    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get details of a specific server
  Future<ServerModel> getServer(String identifier) async {
    try {
      final response = await _dio.get('/api/client/servers/$identifier');
      return ServerModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get server resource usage
  Future<ServerResourceUsage> getServerResources(String identifier) async {
    try {
      final response =
          await _dio.get('/api/client/servers/$identifier/resources');
      return ServerResourceUsage.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Send power action to server (start, stop, restart, kill)
  Future<void> sendPowerAction(String identifier, String action) async {
    try {
      await _dio.post(
        '/api/client/servers/$identifier/power',
        data: {'signal': action},
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Send command to server console
  Future<void> sendCommand(String identifier, String command) async {
    try {
      await _dio.post(
        '/api/client/servers/$identifier/command',
        data: {'command': command},
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get WebSocket authentication details
  Future<Map<String, dynamic>> getWebSocketAuth(String identifier) async {
    try {
      final response =
          await _dio.get('/api/client/servers/$identifier/websocket');
      return response.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get list of backups for a server
  Future<List<BackupModel>> getBackups(String identifier) async {
    try {
      final response =
          await _dio.get('/api/client/servers/$identifier/backups');
      final data = response.data['data'] as List;
      return data.map((json) => BackupModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Create a new backup
  Future<BackupModel> createBackup(String identifier, String name) async {
    try {
      final response = await _dio.post(
        '/api/client/servers/$identifier/backups',
        data: {'name': name},
      );
      return BackupModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Delete a backup
  Future<void> deleteBackup(String identifier, String backupUuid) async {
    try {
      await _dio.delete(
        '/api/client/servers/$identifier/backups/$backupUuid',
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get download URL for a backup
  Future<String> getBackupDownloadUrl(
      String identifier, String backupUuid) async {
    try {
      final response = await _dio.get(
        '/api/client/servers/$identifier/backups/$backupUuid/download',
      );
      return response.data['attributes']['url'] as String;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// List files in a directory
  Future<List<FileModel>> listFiles(String identifier,
      {String directory = '/'}) async {
    try {
      final response = await _dio.get(
        '/api/client/servers/$identifier/files/list',
        queryParameters: {'directory': directory},
      );
      final data = response.data['data'] as List;
      return data.map((json) => FileModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get file contents
  Future<String> getFileContents(String identifier, String filePath) async {
    try {
      final response = await _dio.get(
        '/api/client/servers/$identifier/files/contents',
        queryParameters: {'file': filePath},
      );
      return response.data as String;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Write file contents
  Future<void> writeFileContents(
      String identifier, String filePath, String content) async {
    try {
      await _dio.post(
        '/api/client/servers/$identifier/files/write',
        queryParameters: {'file': filePath},
        data: content,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Delete files
  Future<void> deleteFiles(String identifier, List<String> files) async {
    try {
      await _dio.post(
        '/api/client/servers/$identifier/files/delete',
        data: {
          'root': '/',
          'files': files,
        },
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Create directory
  Future<void> createDirectory(String identifier, String path) async {
    try {
      await _dio.post(
        '/api/client/servers/$identifier/files/create-folder',
        data: {
          'root': '/',
          'name': path,
        },
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Rename file or directory
  Future<void> renameFile(String identifier, String from, String to) async {
    try {
      await _dio.put(
        '/api/client/servers/$identifier/files/rename',
        data: {
          'root': '/',
          'files': [
            {'from': from, 'to': to}
          ],
        },
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get upload URL
  Future<String> getUploadUrl(String identifier) async {
    try {
      final response = await _dio.get(
        '/api/client/servers/$identifier/files/upload',
      );
      return response.data['attributes']['url'] as String;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Error handler
  String _handleError(DioException error) {
    if (error.response != null) {
      final statusCode = error.response!.statusCode;
      final data = error.response!.data;

      switch (statusCode) {
        case 400:
          return 'Bad Request: ${data['errors']?[0]?['detail'] ?? 'Invalid request'}';
        case 401:
          return 'Unauthorized: Invalid API key or session expired';
        case 403:
          return 'Forbidden: You do not have permission to perform this action';
        case 404:
          return 'Not Found: The requested resource does not exist';
        case 429:
          return 'Too Many Requests: Please slow down your requests';
        case 500:
          return 'Server Error: An internal server error occurred';
        default:
          return 'API Error: ${data['errors']?[0]?['detail'] ?? error.message}';
      }
    }

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return 'Connection Timeout: Unable to connect to the server';
    }

    return 'Network Error: ${error.message}';
  }
}
