import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:universal_html/html.dart' as html;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class GalleryViewerScreen extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const GalleryViewerScreen({
    Key? key,
    required this.imageUrls,
    required this.initialIndex,
  }) : super(key: key);

  @override
  _GalleryViewerScreenState createState() => _GalleryViewerScreenState();
}

class _GalleryViewerScreenState extends State<GalleryViewerScreen> {
  late int currentIndex;
  bool showControls = true;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
  }

  void toggleControls() {
    setState(() {
      showControls = !showControls;
    });
  }

  void goNext() {
    if (currentIndex < widget.imageUrls.length - 1) {
      setState(() {
        currentIndex++;
      });
    }
  }

  void goPrevious() {
    if (currentIndex > 0) {
      setState(() {
        currentIndex--;
      });
    }
  }

  Future<void> saveAndShareImageFile(String imageUrl) async {
    setState(() {
      _isDownloading = true;
    });
    // Create a file name with a timestamp.
    String fName = "nest_image_" + DateTime.now().toIso8601String() + ".jpg";

    if (!kIsWeb) {
      // If the platform is not web, get a temporary directory.
      final directory = await getTemporaryDirectory();
      final path = directory.path;
      final filePath = join(path, fName);

      try {
        // Download the image bytes from the URL.
        final response = await http.get(Uri.parse(imageUrl));
        if (response.statusCode == 200) {
          // Write the bytes to a file.
          final file = File(filePath);
          await file.create(recursive: true);
          await file.writeAsBytes(response.bodyBytes);

          // Share the image file.
          await Share.shareXFiles([XFile(filePath)],
              text: 'Nest Image from app');

          // Optionally delete the temporary file.
          await file.delete();
        } else {
          print('Download failed: HTTP ${response.statusCode}');
        }
      } catch (e) {
        print('Error downloading or sharing image: $e');
      }
    } else {
      // For web, sharing the URL directly is a common fallback.
      triggerDownload(imageUrl, fName);
    }
    setState(() {
      _isDownloading = false;
    });
  }

  void triggerDownload(String url, String filename) {
    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", filename)
      ..click();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Image ${currentIndex + 1} of ${widget.imageUrls.length}'),
        actions: [
          _isDownloading
              ? Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(),
                )
              : IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: () {
                    saveAndShareImageFile(widget.imageUrls[currentIndex]);
                  },
                ),
        ],
      ),
      body: Stack(
        children: [
          GestureDetector(
            onTap: toggleControls,
            child: PhotoViewGallery.builder(
              itemCount: widget.imageUrls.length,
              builder: (context, index) {
                return PhotoViewGalleryPageOptions(
                  imageProvider: NetworkImage(widget.imageUrls[index]),
                  initialScale: PhotoViewComputedScale.contained,
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 2,
                );
              },
              pageController: PageController(initialPage: currentIndex),
              onPageChanged: (index) {
                setState(() {
                  currentIndex = index;
                });
              },
              loadingBuilder: (context, event) => const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ),
          if (currentIndex > 0)
            Positioned(
              left: 16,
              top: MediaQuery.of(context).size.height / 2 - 30,
              child: IconButton(
                icon:
                    const Icon(Icons.arrow_back, color: Colors.white, size: 40),
                onPressed: goPrevious,
              ),
            ),
          if (currentIndex < widget.imageUrls.length - 1)
            Positioned(
              right: 16,
              top: MediaQuery.of(context).size.height / 2 - 30,
              child: IconButton(
                icon: const Icon(Icons.arrow_forward,
                    color: Colors.white, size: 40),
                onPressed: goNext,
              ),
            ),
        ],
      ),
    );
  }
}
