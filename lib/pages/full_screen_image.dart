import 'package:fast_cached_network_image/fast_cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

import '../utils/color_const.dart';

class FullScreenImage extends StatefulWidget {
  final String imageUrl;

  const FullScreenImage({super.key, required this.imageUrl});

  @override
  State<FullScreenImage> createState() => _FullScreenImageState();
}

class _FullScreenImageState extends State<FullScreenImage> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.white,
      height: double.infinity,
      width: double.infinity,
      child: Stack(
        children: [
          PhotoView(
            backgroundDecoration: const BoxDecoration(color: AppTheme.white),
            minScale: PhotoViewComputedScale.contained,
            imageProvider: FastCachedImageProvider(
              widget.imageUrl,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 10),
            child: IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(
                  Icons.arrow_back,
                  size: 22,
                  color: AppTheme.black,
                )),
          ),
        ],
      ),
    );
  }
}
