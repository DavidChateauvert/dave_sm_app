import 'package:flutter/material.dart';
import 'package:sm_app/widgets/custom_image.dart';

class Photo extends StatefulWidget {
  final String photoUrl;
  final double aspectRatio;

  Photo({
    required this.photoUrl,
    required this.aspectRatio,
  });

  @override
  _PhotoState createState() => _PhotoState();
}

class _PhotoState extends State<Photo> {

 @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Center(
          child: InteractiveViewer(
            clipBehavior: Clip.none,
            minScale: 1,
            maxScale: 3,
            child: cachedNetworkImage(widget.photoUrl),
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
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
