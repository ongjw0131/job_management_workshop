/// @author [Chong Jun Xiang]
/// @email [chongjx-wm22@student.tarc.edu.my]
/// @create date 2025-09-20 15:52:14
/// @modify date 2025-09-20 15:52:14
/// @desc [ImageGridWidget: A reusable widget to display a grid of images with remove functionality.]
library;

import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

enum ImageDisplayMode { grid, list, carousel }

class ImageGridWidget extends StatelessWidget {
  final List<String> images;
  final void Function(int index)? onRemove;
  final int crossAxisCount;
  final double spacing;
  final ImageDisplayMode mode;
  final bool showRemove;
  final String emptyMessage;

  const ImageGridWidget({
    super.key,
    required this.images,
    this.onRemove,
    this.crossAxisCount = 3,
    this.spacing = 8.0,
    this.mode = ImageDisplayMode.grid,
    this.showRemove = true,
    this.emptyMessage = 'No images uploaded yet',
  });

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return Center(child: Text(emptyMessage));
    }

    switch (mode) {
      case ImageDisplayMode.carousel:
        return PageView.builder(
          itemCount: images.length,
          controller: PageController(viewportFraction: 0.8),
          itemBuilder: (context, index) {
            final imgPath = images[index];
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.black12,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: imgPath.startsWith('http')
                    ? CachedNetworkImage(
                        imageUrl: imgPath,
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            const Center(child: CircularProgressIndicator()),
                        errorWidget: (context, url, error) =>
                            const Center(child: Icon(Icons.broken_image)),
                      )
                    : Image.file(File(imgPath), fit: BoxFit.cover),
              ),
            );
          },
        );

      case ImageDisplayMode.list:
        return ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          itemBuilder: (c, i) {
            final url = images[i];
            return Container(
              width: 240,
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.black12,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: url.isEmpty
                    ? const Center(child: Icon(Icons.broken_image))
                    : (url.startsWith('http')
                          ? CachedNetworkImage(
                              imageUrl: url,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                              errorWidget: (context, url, error) =>
                                  const Center(child: Icon(Icons.broken_image)),
                            )
                          : Image.file(File(url), fit: BoxFit.cover)),
              ),
            );
          },
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemCount: images.length,
        );

      case ImageDisplayMode.grid:
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
          ),
          itemCount: images.length,
          itemBuilder: (context, index) {
            final imgPath = images[index];
            return Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: imgPath.startsWith('http')
                      ? CachedNetworkImage(
                          imageUrl: imgPath,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          placeholder: (context, url) =>
                              const Center(child: CircularProgressIndicator()),
                          errorWidget: (context, url, error) =>
                              const Center(child: Icon(Icons.broken_image)),
                        )
                      : Image.file(
                          File(imgPath),
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                ),
                if (showRemove && onRemove != null)
                  Positioned(
                    right: 4,
                    top: 4,
                    child: GestureDetector(
                      onTap: () => onRemove!(index),
                      child: const Icon(
                        Icons.remove_circle,
                        color: Colors.red,
                        size: 24,
                      ),
                    ),
                  ),
              ],
            );
          },
        );
    }
  }
}
