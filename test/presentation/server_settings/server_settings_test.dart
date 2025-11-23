import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pterodactyl_app/presentation/server_settings/server_settings.dart';
import 'package:sizer/sizer.dart';

import '../../test_helper.dart';

void main() {
  group('ServerSettings Screen', () {
    setUp(() async {
      await setupTestServiceProvider();
    });
    testWidgets('renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        Sizer(
          builder: (context, orientation, deviceType) {
            return MaterialApp(
              home: ServerSettings(),
            );
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ServerSettings), findsOneWidget);
    });
  });
}
