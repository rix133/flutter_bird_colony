import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bird_colony/icons/my_flutter_app_icons.dart';
import 'package:flutter_bird_colony/screens/bird/listBirds.dart';
import 'package:flutter_bird_colony/screens/experiment/listExperiments.dart';
import 'package:flutter_bird_colony/screens/listDatas.dart';
import 'package:flutter_bird_colony/screens/nest/listNests.dart';
import 'package:flutter_test/flutter_test.dart';

import 'mocks/mockSharedPreferencesService.dart';
import 'testApp.dart';

void main() {
  final sharedPreferencesService = MockSharedPreferencesService();
  final firestore = FakeFirebaseFirestore();

  late TestApp myApp;
  group('ListDatas', () {
    setUpAll(() {
      myApp = TestApp(
          firestore: firestore,
          sps: sharedPreferencesService,
          app: MaterialApp(home: ListDatas(firestore: firestore)));
    });

    testWidgets('renders the correct number of tabs',
        (WidgetTester tester) async {
      await tester.pumpWidget(myApp);

      expect(find.byType(Tab), findsNWidgets(3));
    });

    testWidgets('renders the correct tab icons and texts',
        (WidgetTester tester) async {
      await tester.pumpWidget(myApp);

      expect(find.byIcon(Icons.science), findsOneWidget);
      expect(find.text('Experiments'), findsOneWidget);

      expect(find.byIcon(Icons.home), findsOneWidget);
      expect(find.text('Nests'), findsOneWidget);

      expect(find.text('Birds'), findsOneWidget);
    });

    testWidgets('renders the correct default tab view',
        (WidgetTester tester) async {
      await tester.pumpWidget(myApp);

      expect(find.byType(ListExperiments), findsOneWidget);
    });

    testWidgets('changes tab when a tab is tapped',
        (WidgetTester tester) async {
      await tester.pumpWidget(myApp);

      expect(find.byType(ListExperiments), findsOneWidget);
      expect(find.byType(ListNests), findsNothing);
      expect(find.byType(ListBirds), findsNothing);

      await tester.tap(find.byIcon(Icons.home));
      await tester.pumpAndSettle();

      expect(find.byType(ListExperiments), findsNothing);
      expect(find.byType(ListNests), findsOneWidget);
      expect(find.byType(ListBirds), findsNothing);

      await tester.tap(find.byIcon(CustomIcons.bird));
      await tester.pumpAndSettle();

      expect(find.byType(ListExperiments), findsNothing);
      expect(find.byType(ListNests), findsNothing);
      expect(find.byType(ListBirds), findsOneWidget);
    });
  });
}
