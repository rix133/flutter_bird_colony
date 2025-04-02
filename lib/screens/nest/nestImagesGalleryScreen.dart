import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../galleryViewerScreen.dart';

/// This widget retrieves a list of image URLs from the nest document's
/// 'images' subcollection and displays them in a grid. Each grid image shows a
/// progress indicator until it finishes loading.
class NestImagesGalleryScreen extends StatelessWidget {
  final DocumentReference nestDoc;
  final FirebaseFirestore firestore;

  const NestImagesGalleryScreen({
    Key? key,
    required this.nestDoc,
    required this.firestore,
  }) : super(key: key);

  Future<List<String>> _getImageUrls() async {
    final snapshot = await nestDoc
        .collection('images')
        .orderBy('timestamp', descending: true)
        .get();
    return snapshot.docs
        .map(
            (doc) => (doc.data() as Map<String, dynamic>)['imageUrl'] as String)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: _getImageUrls(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Scaffold(
              appBar: AppBar(title: const Text('Nest Images')),
              body: Center(child: Text('No images available')));
        }
        final imageUrls = snapshot.data!;
        return Scaffold(
          appBar: AppBar(title: const Text('Nest Images')),
          body: GridView.builder(
            padding: const EdgeInsets.all(8.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemCount: imageUrls.length,
            itemBuilder: (context, index) {
              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GalleryViewerScreen(
                        imageUrls: imageUrls,
                        initialIndex: index,
                      ),
                    ),
                  );
                },
                child: Image.network(
                  imageUrls[index],
                  fit: BoxFit.cover,
                  // Display a progress indicator while the image is downloading.
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.error),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
