import 'dart:math';

import 'package:flutter/material.dart';
import 'package:sm_app/widgets/custom_image.dart';

class Photo extends StatelessWidget {
  final String photoUrl;
  final double aspectRatio;
  final String type;

  Photo({
    required this.photoUrl,
    required this.aspectRatio,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              clipBehavior: Clip.none,
              minScale: 1,
              maxScale: 3,
              child: type == "profile"
                  ? Hero(
                      tag: photoUrl,
                      child: ClipOval(
                        clipper: Circle(),
                        child: cachedNetworkImage(photoUrl),
                      ),
                    )
                  : cachedNetworkImage(photoUrl),
            ),
          ),
          Positioned(
            top: 50,
            left: 20,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Icon(
                Icons.close,
                size: 30,
                color: Theme.of(context).colorScheme.onBackground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class Circle extends CustomClipper<Rect> {
  Rect getClip(Size size) {
    return Rect.fromCircle(
      center: Offset(size.width / 2, size.height / 2),
      radius: min(size.width / 2, size.height / 2),
    );
  }

  bool shouldReclip(oldClipper) {
    return false;
  }
}
