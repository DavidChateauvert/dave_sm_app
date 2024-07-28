import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sm_app/widgets/custom_image.dart';

class Photo extends StatefulWidget {
  final String tag;
  final String photoUrl;
  final double aspectRatio;
  final String type;
  final double desiredTop;

  const Photo({
    required this.tag,
    required this.photoUrl,
    required this.aspectRatio,
    required this.type,
    required this.desiredTop,
  });

  @override
  _PhotoState createState() => _PhotoState();
}

class _PhotoState extends State<Photo> {
  double _top = 0;
  double _left = 0;
  double _initialTop = 0;
  double _initialLeft = 0;
  double _scale = 1.0;
  double _initialScale = 1.0;
  final double _dragThreshold = 200;
  bool isZooming = false;

  @override
  void initState() {
    super.initState();
    _top = widget.desiredTop;
    _initialTop = widget.desiredTop;
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    setState(() {
      isZooming = _scale != _initialScale;
    });
    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: _top,
            left: _left,
            child: GestureDetector(
              onDoubleTap: () {
                setState(() {});
              },
              onScaleStart: (details) {
                if (details.pointerCount == 1) {
                  _initialTop = _top;
                  _initialLeft = _left;
                } else {
                  _initialScale = _scale;
                }
              },
              onScaleUpdate: (details) {
                if (details.pointerCount == 1) {
                  setState(() {
                    _top += details.focalPointDelta.dy;
                    _left += details.focalPointDelta.dx;
                  });
                } else {
                  setState(() {
                    _scale = max(1.0, _initialScale * details.scale);
                    if (details.scale < 1.0) {
                      setState(() {
                        _scale = 1.0;
                        _top = widget.desiredTop;
                        _initialTop = widget.desiredTop;
                      });
                    }
                  });
                }
              },
              onScaleEnd: (details) {
                if (!isZooming) {
                  double distanceMoved = sqrt(
                    pow(_top - _initialTop, 2) + pow(_left - _initialLeft, 2),
                  );

                  if (distanceMoved > _dragThreshold) {
                    Navigator.pop(context);
                  } else {
                    setState(() {
                      _top = _initialTop;
                      _left = _initialLeft;
                    });
                  }
                }
              },
              child: Transform.scale(
                scale: _scale,
                child: Hero(
                  tag: widget.tag,
                  child: widget.type == "profile"
                      ? ClipOval(
                          clipper: Circle(),
                          child: Container(
                            width: MediaQuery.of(context).size.width,
                            child: cachedNetworkImage(widget.photoUrl),
                          ),
                        )
                      : Container(
                          width: MediaQuery.of(context).size.width,
                          child: cachedNetworkImage(widget.photoUrl),
                        ),
                ),
              ),
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
  @override
  Rect getClip(Size size) {
    return Rect.fromCircle(
      center: Offset(size.width / 2, size.height / 2),
      radius: min(size.width / 2, size.height / 2),
    );
  }

  @override
  bool shouldReclip(CustomClipper<Rect> oldClipper) {
    return false;
  }
}
