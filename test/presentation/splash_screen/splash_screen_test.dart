import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pterodactyl_app/presentation/splash_screen/splash_screen.dart';
import 'package:sizer/sizer.dart';

void main() {
  group('SplashScreen', () {
    testWidgets('renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        Sizer(
          builder: (context, orientation, deviceType) {
            return MaterialApp(
              home: SplashScreen(),
            );
          },
        ),
      );

      expect(find.byType(SplashScreen), findsOneWidget);
    });
  });
}
