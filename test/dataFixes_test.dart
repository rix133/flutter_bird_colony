import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bird_colony/screens/dataFixes.dart';
import 'package:flutter_bird_colony/utils/year.dart';
import 'package:flutter_test/flutter_test.dart';

import 'mocks/mockSharedPreferencesService.dart';
import 'testApp.dart';

Finder _findField(String label) {
  return find.ancestor(
    of: find.text(label),
    matching: find.byType(TextFormField),
  );
}

void main() {
  late FakeFirebaseFirestore firestore;
  final sharedPreferencesService = MockSharedPreferencesService();
  late Widget app;

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    final year = DateTime.now().year;
    final collection = yearToNestCollectionName(year);

    await firestore.collection(collection).doc('N1').set({
      'discover_date': Timestamp.fromDate(DateTime(year, 1, 1)),
      'last_modified': Timestamp.fromDate(DateTime(year, 1, 2)),
    });
    await firestore.collection(collection).doc('N2').set({
      'discover_date': Timestamp.fromDate(DateTime(year, 1, 1)),
      'last_modified': Timestamp.fromDate(DateTime(year, 1, 2)),
    });

    await firestore
        .collection(collection)
        .doc('N1')
        .collection('egg')
        .doc('N1 egg 1')
        .set({
      'discover_date': Timestamp.fromDate(DateTime(year, 1, 1)),
      'last_modified': Timestamp.fromDate(DateTime(year, 1, 2)),
      'responsible': 'Test User',
      'ring': 'AA123',
      'status': 'hatched',
      'experiments': [],
      'measures': [],
    });

    await firestore
        .collection(collection)
        .doc('N1')
        .collection('egg')
        .doc('N1 egg 1')
        .collection('changelog')
        .doc(DateTime(year, 1, 2).toIso8601String())
        .set({
      'status': 'hatched',
    });
    await firestore
        .collection(collection)
        .doc('N1')
        .collection('egg')
        .doc('N1 egg 1')
        .collection('changelog')
        .doc(DateTime(year, 1, 1).toIso8601String())
        .set({
      'status': 'intact',
    });

    await firestore
        .collection(collection)
        .doc('N2')
        .collection('egg')
        .doc('N2 egg 2')
        .set({
      'discover_date': Timestamp.fromDate(DateTime(year, 1, 1)),
      'last_modified': Timestamp.fromDate(DateTime(year, 1, 2)),
      'responsible': 'Test User',
      'ring': null,
      'status': 'intact',
      'experiments': [],
      'measures': [],
    });

    await firestore.collection('Birds').doc('AA123').set({
      'ringed_date': Timestamp.fromDate(DateTime(year, 1, 5)),
      'ringed_as_chick': true,
      'band': 'AA123',
      'nest': 'N1',
      'nest_year': year,
      'egg': '1',
      'responsible': 'Test User',
      'experiments': [],
      'measures': [],
    });

    app = TestApp(
      firestore: firestore,
      sps: sharedPreferencesService,
      app: MaterialApp(
        home: Scaffold(
          body: DataFixes(firestore: firestore),
        ),
      ),
    );
  });

  testWidgets('move chick updates bird and eggs', (WidgetTester tester) async {
    final year = DateTime.now().year;
    final collection = yearToNestCollectionName(year);

    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    await tester.enterText(_findField('Bird band'), 'AA123');
    await tester.enterText(_findField('New nest ID'), 'N2');
    await tester.enterText(_findField('New egg number'), '2');

    final moveButton = find.text('Move chick');
    expect(moveButton, findsOneWidget);
    await tester.ensureVisible(moveButton);
    await tester.tap(moveButton);
    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(find.text('Confirm'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    final birdSnap = await firestore.collection('Birds').doc('AA123').get();
    expect(birdSnap.get('nest'), 'N2');
    expect(birdSnap.get('egg'), '2');
    expect(birdSnap.get('nest_year'), year);

    final oldEggSnap = await firestore
        .collection(collection)
        .doc('N1')
        .collection('egg')
        .doc('N1 egg 1')
        .get();
    expect(oldEggSnap.get('ring'), isNull);
    expect(oldEggSnap.get('status'), 'intact');

    final newEggSnap = await firestore
        .collection(collection)
        .doc('N2')
        .collection('egg')
        .doc('N2 egg 2')
        .get();
    expect(newEggSnap.get('ring'), 'AA123');
    expect(newEggSnap.get('status'), 'hatched');
  });
}
