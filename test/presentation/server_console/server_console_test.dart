import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pterodactyl_app/data/models/server_model.dart';
import 'package:pterodactyl_app/presentation/server_console/server_console.dart';
import 'package:sizer/sizer.dart';

import '../../test_helper.dart';

void main() {
  group('ServerConsole Screen', () {
    setUp(() async {
      await setupTestServiceProvider();
    });
    testWidgets('renders correctly', (WidgetTester tester) async {
      final server = ServerModel(
        identifier: 'test',
        internalId: 1,
        uuid: 'test-uuid',
        name: 'Test Server',
        node: 'Test Node',
        sftpDetails: SftpDetails(ip: '127.0.0.1', port: 2022),
        description: 'A test server',
        status: ServerStatus.running,
        limits: ServerLimits(
            memoryInMBytes: 1024, swap: 0, disk: 5120, io: 500, cpu: 100),
        featureLimits:
            ServerFeatureLimits(databases: 1, allocations: 1, backups: 1),
        isServerOwner: true,
        isSuspended: false,
        isInstalling: false,
        isTransferring: false,
        allocation: ServerAllocation(
          id: 1,
          ip: '127.0.0.1',
          ipAlias: null,
          port: 25565,
          notes: null,
          isDefault: true,
        ),
      );

      await tester.pumpWidget(
        Sizer(
          builder: (context, orientation, deviceType) {
            return MaterialApp(
              initialRoute: '/',
              routes: {
                '/': (context) => ServerConsole(),
              },
              onGenerateRoute: (settings) {
                if (settings.name == '/') {
                  return MaterialPageRoute(
                      builder: (_) => ServerConsole(),
                      settings: RouteSettings(arguments: server));
                }
                return null;
              },
            );
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ServerConsole), findsOneWidget);
    });
  });
}
