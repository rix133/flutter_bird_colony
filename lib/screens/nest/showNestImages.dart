import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ShowNestImagesScreen extends StatelessWidget {
  final DocumentReference nestDoc;
  final FirebaseFirestore firestore;

  const ShowNestImagesScreen({
    Key? key,
    required this.nestDoc,
    required this.firestore,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nest Images')),
      body: StreamBuilder<QuerySnapshot>(
        stream: nestDoc
            .collection('images')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading images'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No images available'));
          }

          return GridView.builder(
            padding: const EdgeInsets.all(8.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8.0,
              mainAxisSpacing: 8.0,
            ),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              return Image.network(
                data['imageUrl'],
                fit: BoxFit.cover,
              );
            },
          );
        },
      ),
    );
  }
}
