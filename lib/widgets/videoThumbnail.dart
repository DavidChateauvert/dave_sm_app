import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sm_app/widgets/progress.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class VideoThumbnailWidget extends StatefulWidget {
  final String videoPath;

  VideoThumbnailWidget({required this.videoPath});

  @override
  _VideoThumbnailWidgetState createState() => _VideoThumbnailWidgetState();
}

class _VideoThumbnailWidgetState extends State<VideoThumbnailWidget> {
  String? _thumbnailPath;

  @override
  void initState() {
    super.initState();
    _generateThumbnail();
  }

  Future<void> _generateThumbnail() async {
    final thumbnail = await VideoThumbnail.thumbnailFile(
      video: widget.videoPath,
      imageFormat: ImageFormat.JPEG,
      quality: 10,
    );
    setState(() {
      _thumbnailPath = thumbnail;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _thumbnailPath == null
        ? circularProgress()
        : Stack(
            alignment: Alignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    fit: BoxFit.cover,
                    image: FileImage(File(_thumbnailPath!)),
                  ),
                ),
              ),
              Positioned.fill(
                child: Icon(
                  CupertinoIcons.play_fill,
                  color: Theme.of(context).colorScheme.secondary,
                  size: 54.0,
                ),
              ),
            ],
          );
  }
}
