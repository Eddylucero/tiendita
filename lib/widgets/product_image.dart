import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class ProductImage extends StatelessWidget {
  final String imagePath;
  final Widget fallback;

  const ProductImage({
    super.key,
    required this.imagePath,
    required this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRect(
          child: ImageFiltered(
            imageFilter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Image.file(
              File(imagePath),
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),
        ),
        Image.file(
          File(imagePath),
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => fallback,
        ),
      ],
    );
  }
}
