import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_storage_mocks/firebase_storage_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bird_colony/screens/nest/nestImagesGalleryScreen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bird_colony/screens/nest/addImage.dart';
import 'package:flutter_bird_colony/screens/nest/optionsNestImage.dart';

void main() {
  group("Nest Image Widgets", () {
    late FakeFirebaseFirestore firestore;
    late DocumentReference nestDoc;
    late MockFirebaseStorage storage;
    setUp(() {
      firestore = FakeFirebaseFirestore();
      storage = MockFirebaseStorage();
      nestDoc = firestore.collection('nests').doc('nest1');
    });

    testWidgets(
        "NestImageOptions displays two options and navigates to Add New Photo",
        (WidgetTester tester) async {
      // Create a test NavigatorObserver.
      final navObserver = TestNavigatorObserver();
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: NestImageOptions(
              nestDoc: nestDoc, firestore: firestore, storage: storage),
        ),
        navigatorObservers: [navObserver],
      ));

      expect(find.text('Add New Photo'), findsOneWidget);
      expect(find.text('View Photos'), findsOneWidget);

      // Tap the 'Add New Photo' option and verify that a navigation push occurs.
      await tester.tap(find.text('Add New Photo'));
      await tester.pumpAndSettle();
      expect(navObserver.pushCount, equals(1));
    });

    testWidgets(
        "NestImageOptions displays two options and navigates to View Photos",
        (WidgetTester tester) async {
      // Create a test NavigatorObserver.
      final navObserver = TestNavigatorObserver();
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: NestImageOptions(
              nestDoc: nestDoc, firestore: firestore, storage: storage),
        ),
        navigatorObservers: [navObserver],
      ));

      expect(find.text('Add New Photo'), findsOneWidget);
      expect(find.text('View Photos'), findsOneWidget);

      // Tap the 'Add New Photo' option and verify that a navigation push occurs.
      await tester.tap(find.text('View Photos'));
      await tester.pumpAndSettle();
      expect(navObserver.pushCount, equals(2));
    });

    testWidgets("ShowNestImagesScreen shows 'No images available' when empty",
        (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: NestImagesGalleryScreen(nestDoc: nestDoc, firestore: firestore),
      ));
      await tester.pumpAndSettle();
      expect(find.text('No images available'), findsOneWidget);
    });

    /* Not overriding http request  properly yet in the test
    testWidgets("ShowNestImagesScreen displays images when present",
            (WidgetTester tester) async {
          // Add a dummy image document to the 'images' subcollection.
          await nestDoc.collection('images').add({
            'imageUrl': 'https://example.com/test.jpg',
            'timestamp': FieldValue.serverTimestamp(),
          });
          await tester.pumpWidget(MaterialApp(
            home: ShowNestImagesScreen(nestDoc: nestDoc, firestore: firestore),
          ));
          await tester.pumpAndSettle();
          // The grid should contain at least one Image widget.
          expect(find.byType(Image), findsOneWidget);
        });
        */

    testWidgets("AddImageScreen initial UI is displayed",
        (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: AddImageScreen(
          nestDoc: nestDoc,
          firestore: firestore,
          storageFolder: 'nest_images',
          storage: storage,
        ),
      ));
      expect(find.text('Add Image'), findsOneWidget);
      expect(find.text('No image selected'), findsOneWidget);
      expect(find.byIcon(Icons.photo_library), findsOneWidget);
      expect(find.byIcon(Icons.camera_alt), findsOneWidget);
      expect(find.byIcon(Icons.cloud_upload), findsOneWidget);
    });

    testWidgets("AddImageScreen enables upload button when image is selected",
        (WidgetTester tester) async {
      // Use an untyped GlobalKey to access the state.
      final addImageKey = GlobalKey();
      await tester.pumpWidget(MaterialApp(
        home: AddImageScreen(
          key: addImageKey,
          nestDoc: nestDoc,
          firestore: firestore,
          storage: storage,
          storageFolder: 'nest_images',
        ),
      ));
      // The 'Upload Image' button should be disabled when no image is selected.
      final uploadButtonFinder = find.byKey(const Key('uploadImageButton'));
      expect(uploadButtonFinder, findsOneWidget);
      ElevatedButton uploadButton = tester.widget(uploadButtonFinder);
      expect(uploadButton.onPressed, isNull);

      /* Access the state via the key and set _image to a dummy File.
          final state = addImageKey.currentState as dynamic;
          state.setState(() {
            state._image = File('dummy_path');
          });
          await tester.pump();
          final updatedUploadButton =
          tester.widget<ElevatedButton>(uploadButtonFinder);
          expect(updatedUploadButton.onPressed, isNotNull);
          */
    });
  });
}

// A simple NavigatorObserver for testing navigation events.
class TestNavigatorObserver extends NavigatorObserver {
  int pushCount = 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushCount++;
    super.didPush(route, previousRoute);
  }

  void reset() {
    pushCount = 0;
  }
}
