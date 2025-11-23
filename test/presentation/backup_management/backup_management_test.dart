import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pterodactyl_app/presentation/backup_management/backup_management.dart';
import 'package:sizer/sizer.dart';

import '../../test_helper.dart';

void main() {
  group('BackupManagement Screen', () {
    setUp(() async {
      await setupTestServiceProvider();
    });
    testWidgets('renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        Sizer(
          builder: (context, orientation, deviceType) {
            return MaterialApp(
              initialRoute: '/',
              routes: {
                '/': (context) => BackupManagement(),
              },
              onGenerateRoute: (settings) {
                if (settings.name == '/') {
                  return MaterialPageRoute(
                      builder: (_) => BackupManagement(),
                      settings: RouteSettings(arguments: 'test_server'));
                }
                return null;
              },
            );
          },
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(BackupManagement), findsOneWidget);
    });
  });
}
