import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../galleryViewerScreen.dart';

class NestImagesGalleryScreen extends StatefulWidget {
  final DocumentReference nestDoc;
  final FirebaseFirestore firestore;

  const NestImagesGalleryScreen({
    Key? key,
    required this.nestDoc,
    required this.firestore,
  }) : super(key: key);

  @override
  _NestImagesGalleryScreenState createState() =>
      _NestImagesGalleryScreenState();
}

class _NestImagesGalleryScreenState extends State<NestImagesGalleryScreen> {
  late Future<List<String>> _imageUrlsFuture;

  Future<List<String>> _getImageUrls() async {
    final snapshot = await widget.nestDoc
        .collection('images')
        .orderBy('timestamp', descending: true)
        .get();
    return snapshot.docs
        .map(
            (doc) => (doc.data() as Map<String, dynamic>)['imageUrl'] as String)
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _imageUrlsFuture = _getImageUrls();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: _imageUrlsFuture,
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
                child: CachedNetworkImage(
                  imageUrl: imageUrls[index],
                  fit: BoxFit.cover,
                  placeholder: (context, url) =>
                      const Center(child: CircularProgressIndicator()),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
