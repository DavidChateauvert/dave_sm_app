import 'package:flutter/material.dart';
import 'package:sm_app/widgets/custom_image.dart';

class Photo extends StatefulWidget {
  final String photoUrl;
  final double aspectRatio;
  final String type;

  Photo({
    required this.photoUrl,
    required this.aspectRatio,
    required this.type,
  });

  @override
  _PhotoState createState() => _PhotoState();
}

class _PhotoState extends State<Photo> {
  @override
  Widget build(BuildContext context) {
    print(widget.type);
    return Stack(
      children: [
        Center(
          child: InteractiveViewer(
            clipBehavior: Clip.none,
            minScale: 1,
            maxScale: 3,
            child: widget.type == "profile"
                ? ClipOval(
                    child: cachedNetworkImage(widget.photoUrl),
                  )
                : cachedNetworkImage(widget.photoUrl),
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
