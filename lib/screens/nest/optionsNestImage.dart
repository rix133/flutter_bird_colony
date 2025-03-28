import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bird_colony/screens/nest/showNestImages.dart';

import 'addImage.dart';

class NestImageOptions extends StatelessWidget {
  final DocumentReference nestDoc;
  final FirebaseFirestore firestore;

  const NestImageOptions({
    Key? key,
    required this.nestDoc,
    required this.firestore,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Wrap(
      children: [
        ListTile(
          leading: const Icon(Icons.camera_alt),
          title: const Text('Add New Photo'),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddImageScreen(
                    nestDoc: nestDoc,
                    firestore: firestore,
                    storageFolder: 'nest_images'),
              ),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.photo_library),
          title: const Text('View Photos'),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ShowNestImagesScreen(
                    nestDoc: nestDoc, firestore: firestore),
              ),
            );
          },
        ),
      ],
    );
  }
}
