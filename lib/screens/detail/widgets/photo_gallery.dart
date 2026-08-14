import 'package:flutter/material.dart';

import '../../../models/property_photo.dart';
import '../../../widgets/media_path_scope.dart';
import '../../../widgets/property_photo.dart';

class PhotoGallery extends StatefulWidget {
  final List<PropertyPhoto> photos;
  final List<int> photoSeeds;

  const PhotoGallery({
    super.key,
    required this.photos,
    required this.photoSeeds,
  });

  @override
  State<PhotoGallery> createState() => _PhotoGalleryState();
}

class _PhotoGalleryState extends State<PhotoGallery> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final seeds = widget.photoSeeds.isEmpty ? const [0] : widget.photoSeeds;
    final itemCount = widget.photos.isNotEmpty
        ? widget.photos.length
        : seeds.length;
    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          controller: _controller,
          itemCount: itemCount,
          onPageChanged: (i) => setState(() => _page = i),
          itemBuilder: (context, i) {
            final photo = widget.photos.isEmpty ? null : widget.photos[i];
            return PropertyPhotoView(
              filePath: MediaPathScope.resolve(context, photo?.relativePath),
              seed: seeds[i % seeds.length],
            );
          },
        ),
        if (itemCount > 1)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(itemCount, (i) {
                final active = i == _page;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: active ? 16 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: active ? 0.95 : 0.5),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }
}
