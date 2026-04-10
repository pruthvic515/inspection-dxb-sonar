import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:patrol_system/controls/text.dart';
import 'package:patrol_system/utils/color_const.dart';

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

  List<XFile> cachedImages = []; // temporary cache

  Set<String> selectedPaths = {};

  @override
  void initState() {
    super.initState();
    loadImages();
  }

  Future<void> captureImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);

    if (image != null) {
      if (cachedImages.length >= 10) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Max 10 images allowed")),
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

  Future<void> loadImages() async {
    final Directory dir = Platform.isAndroid
        ? await getExternalStorageDirectory().then((value) => value!)
        : await getApplicationDocumentsDirectory();

    final files = dir.listSync();

    List<XFile> loadedImages = [];

    for (var file in files) {
      if (file.path.endsWith(".jpg")) {
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
      appBar: AppBar(
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
                    return GestureDetector(
                      onTap: () {
                        if (widget.isSelectionMode) {
                          openImagePreview(cachedImages[index]);
                        }
                      },
                      child: Stack(
                        children: [
                          Image.file(
                            File(cachedImages[index].path),
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),

                          /// ❌ Remove (only in capture mode)
                          if (!widget.isSelectionMode)
                            Positioned(
                              top: 5,
                              right: 5,
                              child: GestureDetector(
                                onTap: () {
                                  removeImage(cachedImages[index]);
                                  // setState(() {
                                  //   cachedImages.removeAt(index);
                                  // });
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
                  /// 📸 Capture Button
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
                            text: "Capture",
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

  void showBulkSubmitPopup() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Submit Images?"),
        content: Text("Submit ${selectedPaths.length} images?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              List<XFile> selectedImages = cachedImages
                  .where((img) => selectedPaths.contains(img.path))
                  .toList();

              await removeMultipleImages(selectedImages);

              Get.back(result: selectedImages); // ✅ return list
            },
            child: const Text("Submit"),
          ),
        ],
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

  void openImagePreview(XFile image) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: Column(
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
                  child: const Text("Close"),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(context);

                    // await removeImage(image);

                    Get.back(result: image); // ✅ return single image
                  },
                  child: const Text("Submit"),
                ),
              ],
            ),
          ],
        ),
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
