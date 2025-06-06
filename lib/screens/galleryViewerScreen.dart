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
import 'package:cached_network_image/cached_network_image.dart';

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
  late PageController _pageController;
  bool showControls = true;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void toggleControls() {
    setState(() {
      showControls = !showControls;
    });
  }

  void goNext() {
    if (currentIndex < widget.imageUrls.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void goPrevious() {
    if (currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  String constructFileName(String url) {
    final uri = Uri.parse(url);
    final encodedPath = uri.path.split('/o/').last;
    final decodedPath = Uri.decodeComponent(encodedPath);
    final segments = decodedPath.split('/');

    if (segments.length < 4) {
      return "nest_image_${DateTime.now().toIso8601String()}.jpg";
    }

    final nestNumber = segments[2];
    final timestampStr = segments.last;
    final timestamp = int.tryParse(timestampStr);

    if (timestamp == null) {
      return "nest_image_${DateTime.now().toIso8601String()}.jpg";
    }

    final originalDate = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final isoDate = originalDate.toIso8601String();

    return "nest_${nestNumber}_$isoDate.jpg";
  }

  Future<void> saveAndShareImageFile(String imageUrl) async {
    setState(() {
      _isDownloading = true;
    });
    String fName = constructFileName(imageUrl);

    if (!kIsWeb) {
      final directory = await getTemporaryDirectory();
      final path = directory.path;
      final filePath = join(path, fName);

      try {
        final response = await http.get(Uri.parse(imageUrl));
        if (response.statusCode == 200) {
          final file = File(filePath);
          await file.create(recursive: true);
          await file.writeAsBytes(response.bodyBytes);
          await Share.shareXFiles([XFile(filePath)],
              text: 'Nest Image from app');
          await file.delete();
        } else {
          print('Download failed: HTTP ${response.statusCode}');
        }
      } catch (e) {
        print('Error downloading or sharing image: $e');
      }
    } else {
      await triggerDownload(imageUrl, fName);
    }
    setState(() {
      _isDownloading = false;
    });
  }

  Future<void> triggerDownload(String url, String filename) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final blob = html.Blob([response.bodyBytes]);
        final blobUrl = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: blobUrl)
          ..setAttribute('download', filename)
          ..click();
        html.Url.revokeObjectUrl(blobUrl);
      } else {
        print('Download failed: HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('Error during download: $e');
    }
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
                  icon: kIsWeb ? Icon(Icons.download) : Icon(Icons.share),
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
                  imageProvider:
                      CachedNetworkImageProvider(widget.imageUrls[index]),
                  initialScale: PhotoViewComputedScale.contained,
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 2,
                );
              },
              pageController: _pageController,
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
