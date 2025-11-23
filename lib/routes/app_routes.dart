import 'package:flutter/material.dart';
import '../presentation/splash_screen/splash_screen.dart';
import '../presentation/settings_screen/settings_screen.dart';
import '../presentation/server_dashboard/server_dashboard.dart';
import '../presentation/file_manager/file_manager.dart';
import '../presentation/backup_management/backup_management.dart';
import '../presentation/server_settings/server_settings.dart';
import '../presentation/server_console/server_console.dart';

class AppRoutes {
  static const String initial = '/';
  static const String splash = '/splash-screen';
  static const String settings = '/settings';
  static const String backupManagement = '/backup-management';
  static const String serverSettings = '/server-settings';
  static const String serverConsole = '/server-console';
  static const String serverDashboard = '/server-dashboard';
  static const String fileManager = '/file-manager';

  static Map<String, WidgetBuilder> routes = {
    initial: (context) => const SplashScreen(),
    splash: (context) => const SplashScreen(),
    settings: (context) => const SettingsScreen(),
    backupManagement: (context) => const BackupManagement(),
    serverSettings: (context) => const ServerSettings(),
    serverConsole: (context) => const ServerConsole(),
    serverDashboard: (context) => const ServerDashboard(),
    fileManager: (context) => const FileManager(),
  };
}
