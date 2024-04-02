import 'package:flutter/material.dart';
import 'package:flutter_bird_colony/design/homepageButton.dart';
import 'package:flutter_test/flutter_test.dart';
import 'mocks/mockAuthService.dart';

void main() {
  testWidgets('HomePageButton  logged in test', (WidgetTester tester) async {
    // Create a mock AuthService
    final authService = MockAuthService();

    // Build the HomePageButton widget
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Column(children: [
      HomePageButton(
        route: '/test',
        icon: Icons.home,
        label: 'Test',
        color: Colors.blue,
        auth: authService,
      )
    ]))));
    await tester.pumpAndSettle();

    // Verify the label text is present
    expect(find.text('Test'), findsOneWidget);
  });

  testWidgets('HomePageButton  not logged in test',
      (WidgetTester tester) async {
    // Create a mock AuthService
    final authService = MockAuthService();
    authService.isLoggedIn = false;

    // Build the HomePageButton widget
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
          body: Column(children: [
        HomePageButton(
          route: '/test',
          icon: Icons.home,
          label: 'Test',
          color: Colors.blue,
          auth: authService,
        )
      ])),
      routes: {
        '/settings': (context) => Scaffold(
              body: Text('Settings'),
            )
      },
    ));
    await tester.pumpAndSettle();

    // Verify the label text is present
    expect(find.text('Test'), findsOneWidget);

    // Tap the button
    await tester.tap(find.byType(HomePageButton));
    await tester.pumpAndSettle();
    expect(find.text('Not Logged In'), findsOneWidget);

    //tap go to settings
    await tester.tap(find.text('Go to Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);
  });
}
