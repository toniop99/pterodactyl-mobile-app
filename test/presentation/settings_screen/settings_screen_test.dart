import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pterodactyl_app/presentation/settings_screen/settings_screen.dart';
import 'package:sizer/sizer.dart';

void main() {
  group('SettingsScreen', () {
    testWidgets('renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        Sizer(
          builder: (context, orientation, deviceType) {
            return MaterialApp(
              home: SettingsScreen(),
            );
          },
        ),
      );

      expect(find.byType(SettingsScreen), findsOneWidget);
    });
  });
}
