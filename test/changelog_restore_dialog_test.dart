import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bird_colony/design/changelogRestoreDialog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Restore dialog writes snapshot to document',
      (WidgetTester tester) async {
    final firestore = FakeFirebaseFirestore();
    final docRef = firestore.collection('Birds').doc('B123');

    await docRef.set({
      'band': 'B123',
      'color_band': 'red',
      'last_modified': DateTime(2025, 2, 1),
    });

    await docRef.collection('changelog').doc('2025-01-01 00:00:00.000').set({
      'band': 'B123',
      'color_band': 'blue',
      'last_modified': DateTime(2025, 1, 1),
    });

    await docRef.collection('changelog').doc('deleted_2024-12-01 00:00:00.000').set({
      'band': 'B123',
      'color_band': 'green',
      'last_modified': DateTime(2024, 12, 1),
    });

    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: ElevatedButton(
            onPressed: () => RestoreFromChangelogDialog.show(
              context,
              itemRef: docRef,
              title: 'Restore bird B123',
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Restore bird B123'), findsOneWidget);
    expect(find.textContaining('2025-01-01'), findsOneWidget);
    expect(find.textContaining('2024-12-01'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'View').first);
    await tester.pumpAndSettle();

    final snapshotDialog = find.widgetWithText(AlertDialog, 'Changelog snapshot');
    expect(snapshotDialog, findsOneWidget);

    await tester.tap(
        find.descendant(of: snapshotDialog, matching: find.text('Restore')));
    await tester.pumpAndSettle();

    final confirmDialog = find.widgetWithText(AlertDialog, 'Restore version?');
    expect(confirmDialog, findsOneWidget);

    await tester.tap(
        find.descendant(of: confirmDialog, matching: find.text('Restore')));
    await tester.pumpAndSettle();

    final restoredDoc = await docRef.get();
    final data = restoredDoc.data() as Map<String, dynamic>;
    expect(data['band'], 'B123');
    expect(data['color_band'], 'blue');

    final changelogSnapshot = await docRef.collection('changelog').get();
    expect(changelogSnapshot.docs.length, 3);
  });
}
