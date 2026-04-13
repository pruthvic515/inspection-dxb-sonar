import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_video_thumbnail_plus/flutter_video_thumbnail_plus.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:patrol_system/controls/loading_indicator_dialog.dart';
import 'package:patrol_system/controls/text.dart';
import 'package:patrol_system/utils/color_const.dart';
import 'package:video_player/video_player.dart';

class CaptureImagesScreen extends StatefulWidget {
  final bool isSelectionMode;
  final bool isFromDraft;

  const CaptureImagesScreen({
    super.key,
    this.isSelectionMode = false,
    this.isFromDraft = false,
  });

  @override
  State<CaptureImagesScreen> createState() => _CaptureImagesScreenState();
}

class _CaptureImagesScreenState extends State<CaptureImagesScreen> {
  final ImagePicker _picker = ImagePicker();
  static const int _maxAttachments = 10;
  static const Duration _maxVideoDuration = Duration(seconds: 10);

  List<XFile> cachedImages = []; // temporary cache

  Set<String> selectedPaths = {};
  bool _isSubmitting = false;

  void _submitSelection(XFile image) {
    if (_isSubmitting) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    Get.back(result: image);
  }

  @override
  void initState() {
    super.initState();
    loadImages();
  }

  Future<void> captureImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);

    if (image != null) {
      if (cachedImages.length >= _maxAttachments) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Max 10 attachments allowed")),
        );
        return;
      }

      final Directory dir = Platform.isAndroid
          ? await getExternalStorageDirectory().then((value) => value!)
          : await getApplicationDocumentsDirectory();

      final String newPath =
          "${dir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg";

      final File newImage = await File(image.path).copy(newPath);

      setState(() {
        cachedImages.add(XFile(newImage.path)); // ✅ correct
      });
    }
  }

  Future<void> captureVideo() async {
    if (cachedImages.length >= _maxAttachments) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Max 10 attachments allowed")),
      );
      return;
    }

    final XFile? video = await _picker.pickVideo(
      source: ImageSource.camera,
      maxDuration: _maxVideoDuration,
    );

    if (video == null) {
      return;
    }

    final Directory dir = Platform.isAndroid
        ? await getExternalStorageDirectory().then((value) => value!)
        : await getApplicationDocumentsDirectory();

    final String newPath =
        "${dir.path}/${DateTime.now().millisecondsSinceEpoch}.mp4";

    final File newVideo = await File(video.path).copy(newPath);

    if (!mounted) {
      return;
    }

    setState(() {
      cachedImages.add(XFile(newVideo.path));
    });
  }

  Future<void> loadImages() async {
    final Directory dir = Platform.isAndroid
        ? await getExternalStorageDirectory().then((value) => value!)
        : await getApplicationDocumentsDirectory();

    final files = dir.listSync();

    List<XFile> loadedImages = [];

    for (var file in files) {
      final lowerPath = file.path.toLowerCase();
      if (lowerPath.endsWith(".jpg") ||
          lowerPath.endsWith(".jpeg") ||
          lowerPath.endsWith(".mp4")) {
        loadedImages.add(XFile(file.path));
      }
    }

    setState(() {
      cachedImages = loadedImages;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.white,
      appBar: AppBar(
        backgroundColor: AppTheme.white,
        title: const Text("Capture Images"),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            /// 📸 Capture Button alway show whatever

            const SizedBox(height: 10),

            /// 🖼️ Preview Images
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: GridView.builder(
                  itemCount: cachedImages.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 5,
                    mainAxisSpacing: 5,
                  ),
                  itemBuilder: (context, index) {
                    final currentItem = cachedImages[index];
                    return GestureDetector(
                      onTap: () {
                        final isVideo = _isVideoPath(currentItem.path);
                        if (isVideo || widget.isSelectionMode) {
                          openImagePreview(currentItem);
                        }
                      },
                      child: Stack(
                        children: [
                          _buildAttachmentTile(currentItem.path),

                          /// ❌ Remove (only in capture mode)
                          if (!widget.isSelectionMode)
                            Positioned(
                              top: 5,
                              right: 5,
                              child: GestureDetector(
                                onTap: () {
                                  _confirmRemoveImage(currentItem);
                                },
                                child:
                                    const Icon(Icons.close, color: Colors.red),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  /// 📸 Image Button
                  Visibility(
                    visible: !widget.isFromDraft,
                    child: Expanded(
                      child: GestureDetector(
                        onTap: captureImage,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(25),
                            color: AppTheme.colorPrimary.withOpacity(0.8),
                          ),
                          child: CText(
                            text: "Image",
                            textAlign: TextAlign.center,
                            textColor: AppTheme.white,
                            fontSize: AppTheme.medium,
                            fontWeight: FontWeight.w600,
                            fontFamily: AppTheme.urbanist,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  /// 🎥 Video Button
                  Visibility(
                    visible: !widget.isFromDraft, /*&& !widget.isSelectionMode,*/
                    child: Expanded(
                      child: GestureDetector(
                        onTap: captureVideo,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(25),
                            color: AppTheme.colorPrimary.withOpacity(0.8),
                          ),
                          child: CText(
                            text: "Video",
                            textAlign: TextAlign.center,
                            textColor: AppTheme.white,
                            fontSize: AppTheme.medium,
                            fontWeight: FontWeight.w600,
                            fontFamily: AppTheme.urbanist,
                          ),
                        ),
                      ),
                    ),
                  ),

                  /*/// ✅ Submit Button
                  Expanded(
                    child: GestureDetector(
                      onTap: selectedPaths.isEmpty ? null : showBulkSubmitPopup,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(25),
                          color: selectedPaths.isEmpty
                              ? Colors.grey.shade400 // disabled
                              : AppTheme.colorPrimary,
                        ),
                        child: CText(
                          text: "Submit (${selectedPaths.length})",
                          textAlign: TextAlign.center,
                          textColor: AppTheme.white,
                          fontSize: AppTheme.medium,
                          fontWeight: FontWeight.w600,
                          fontFamily: AppTheme.urbanist,
                        ),
                      ),
                    ),
                  ),*/
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }


  Future<void> removeMultipleImages(List<XFile> images) async {
    for (var image in images) {
      final file = File(image.path);

      if (await file.exists()) {
        await file.delete();
      }
    }

    setState(() {
      cachedImages.removeWhere((img) => selectedPaths.contains(img.path));
      selectedPaths.clear();
    });
  }

  bool _isVideoPath(String path) {
    final lowerPath = path.toLowerCase();
    return lowerPath.endsWith(".mp4") ||
        lowerPath.endsWith(".mov") ||
        lowerPath.endsWith(".m4v");
  }

  Future<String?> _generateVideoThumbnail(String videoPath) async {
    final Directory dir = Platform.isAndroid
        ? await getExternalStorageDirectory().then((value) => value!)
        : await getApplicationDocumentsDirectory();

    return FlutterVideoThumbnailPlus.thumbnailFile(
      video: videoPath,
      thumbnailPath: dir.absolute.path,
      imageFormat: ImageFormat.jpeg,
      quality: 70,
    );
  }

  Widget _buildAttachmentTile(String path) {
    if (_isVideoPath(path)) {
      return FutureBuilder<String?>(
        future: _generateVideoThumbnail(path),
        builder: (context, snapshot) {
          final thumbPath = snapshot.data;
          return Stack(
            fit: StackFit.expand,
            children: [
              if (thumbPath != null && thumbPath.isNotEmpty)
                Image.file(
                  File(thumbPath),
                  fit: BoxFit.cover,
                )
              else
                Container(color: Colors.black12),
              const Center(
                child: Icon(
                  Icons.play_circle_fill,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ],
          );
        },
      );
    }

    return Image.file(
      File(path),
      fit: BoxFit.cover,
      width: double.infinity,
    );
  }

  void openImagePreview(XFile image) {
    if (_isVideoPath(image.path)) {
      showDialog(
        context: context,
        builder: (_) => _LocalVideoPreviewDialog(
          videoPath: image.path,
          onDelete: () async {
            Navigator.pop(context);
            await removeImage(image);
          },
          onSubmit: () {
            Navigator.pop(context);
            _submitSelection(image);
          },
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.white,
        child: Stack(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                /// 🖼️ Big Image
                Image.file(
                  File(image.path),
                  fit: BoxFit.cover,
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height * 0.65,
                ),
                const SizedBox(height: 10),

                /// Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () async {
                        Navigator.pop(context);

                        await removeImage(image);
                      },
                      child: const Text("Delete"),
                    ),
                    TextButton(
                      onPressed: () async {
                        Navigator.pop(context);

                        // await removeImage(image);

                        _submitSelection(image); // ✅ return single image
                      },
                      child: const Text("Submit"),
                    ),
                  ],
                ),
              ],
            ),

            /// ❌ Close Icon (Top Left)
            Positioned(
              top: 8,
              left: 8,
              child: InkWell(
                onTap: () => Navigator.pop(context),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(6),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmRemoveImage(XFile image) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Are you sure you want to delete?"),
        content: const Text("This action is irreversible."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await removeImage(image);
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  Future<void> removeImage(XFile image) async {
    final file = File(image.path);

    if (await file.exists()) {
      await file.delete();
    }

    setState(() {
      cachedImages.removeWhere((e) => e.path == image.path);
    });
  }
}

class _LocalVideoPreviewDialog extends StatefulWidget {
  final String videoPath;
  final VoidCallback onSubmit;
  final Future<void> Function() onDelete;

  const _LocalVideoPreviewDialog({
    required this.videoPath,
    required this.onSubmit,
    required this.onDelete,
  });

  @override
  State<_LocalVideoPreviewDialog> createState() =>
      _LocalVideoPreviewDialogState();
}

class _LocalVideoPreviewDialogState extends State<_LocalVideoPreviewDialog> {
  late final VideoPlayerController _controller;
  late final Future<void> _initializeFuture;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.videoPath));
    _initializeFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      child: Stack(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FutureBuilder<void>(
                future: _initializeFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const SizedBox(
                      height: 280,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  return AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        VideoPlayer(_controller),
                        IconButton(
                          iconSize: 48,
                          color: Colors.white,
                          icon: Icon(
                            _controller.value.isPlaying
                                ? Icons.pause_circle_filled
                                : Icons.play_circle_fill,
                          ),
                          onPressed: () {
                            setState(() {
                              if (_controller.value.isPlaying) {
                                _controller.pause();
                              } else {
                                _controller.play();
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: widget.onDelete,
                    child: const Text("Delete"),
                  ),
                  TextButton(
                    onPressed: widget.onSubmit,
                    child: const Text("Submit"),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            top: 8,
            left: 8,
            child: InkWell(
              onTap: () => Navigator.pop(context),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(6),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
