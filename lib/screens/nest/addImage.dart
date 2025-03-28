import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AddImageScreen extends StatefulWidget {
  final DocumentReference nestDoc;
  final FirebaseFirestore firestore;
  final String storageFolder;

  const AddImageScreen(
      {Key? key,
      required this.nestDoc,
      required this.firestore,
      required this.storageFolder})
      : super(key: key);

  @override
  _AddImageScreenState createState() => _AddImageScreenState();
}

class _AddImageScreenState extends State<AddImageScreen> {
  File? _image;
  bool _uploading = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _takePhoto() async {
    final pickedFile =
        await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _pickImage() async {
    final pickedFile =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _uploadImage() async {
    String year = DateTime.now().year.toString();
    if (_image == null) return;
    setState(() {
      _uploading = true;
    });

    try {
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final storageRef = FirebaseStorage.instance.ref().child(
          '${widget.storageFolder}/$year/${widget.nestDoc.id}/$fileName');
      print(storageRef.fullPath);
      final uploadTask = storageRef.putFile(_image!);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      await widget.nestDoc.collection('images').add({
        'imageUrl': downloadUrl,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image uploaded successfully')),
      );
      Navigator.pop(context);
    } catch (e) {
      print('Error uploading image: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e')),
      );
    } finally {
      setState(() {
        _uploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Image')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _image != null
                  ? Image.file(
                      _image!,
                      height: 300,
                      fit: BoxFit.contain,
                    )
                  : Container(
                      height: 300,
                      color: Colors.grey[300],
                      child: const Center(child: Text('No image selected')),
                    ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.photo_library),
                label: const Text('Pick Image'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _image == null ? null : Colors.white54,
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: _takePhoto,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Take Photo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _image == null ? null : Colors.white54,
                ),
              ),
              const SizedBox(height: 20),
              _uploading
                  ? const CircularProgressIndicator()
                  : ElevatedButton.icon(
                      key: const ValueKey('uploadImageButton'),
                      onPressed: _image == null ? null : _uploadImage,
                      icon: const Icon(Icons.cloud_upload),
                      label: const Text('Upload Image'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
