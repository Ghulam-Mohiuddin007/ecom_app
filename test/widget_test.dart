import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecom_app/onboarding/onboarding_screen.dart';

void main() {
  testWidgets('OnboardingScreen renders Vibe selection UI', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: OnboardingScreen(),
      ),
    );

    expect(find.text('Choose Your Vibe'), findsOneWidget);
    expect(find.text('Explore Drops'), findsOneWidget);
    expect(find.text('Y2K Cyber'), findsOneWidget);
  });
}
