import 'package:flutter/material.dart';

import '../../../widgets/property_photo.dart';

class PhotoGallery extends StatefulWidget {
  final List<int> photoSeeds;

  const PhotoGallery({super.key, required this.photoSeeds});

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
    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          controller: _controller,
          itemCount: seeds.length,
          onPageChanged: (i) => setState(() => _page = i),
          itemBuilder: (context, i) => PropertyPhoto(seed: seeds[i]),
        ),
        if (seeds.length > 1)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(seeds.length, (i) {
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
