import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sm_app/widgets/progress.dart';
import 'package:video_player/video_player.dart';

class PlayVideo extends StatefulWidget {
  PlayVideo(
      {Key? key,
      required this.videoUrl,
      required this.type,
      required this.file,
      required this.height})
      : super(key: key);
  final String videoUrl;
  final String type;
  final File? file;
  final int? height;

  @override
  _PlayVideoState createState() => _PlayVideoState();
}

class _PlayVideoState extends State<PlayVideo> {
  late VideoPlayerController _controller;
  late Future<void> _initializeVideoPlayerFuture;

  @override
  void initState() {
    super.initState();
    if (widget.type == "upload" && widget.file != null) {
      _controller = VideoPlayerController.file(widget.file!);
    } else {
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
      );
    }

    _initializeVideoPlayerFuture = _controller.initialize();
    _controller.setLooping(true);

    // Listen to the video controller for changes
    _controller.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initializeVideoPlayerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return Stack(
            alignment: Alignment.center,
            children: [
              AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: VideoProgressIndicator(
                  _controller,
                  allowScrubbing: false,
                  colors: VideoProgressColors(
                    playedColor: Theme.of(context).colorScheme.secondary,
                    bufferedColor: Colors.grey,
                    backgroundColor: Colors.transparent,
                  ),
                ),
              ),
              Positioned.fill(
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      if (_controller.value.isPlaying) {
                        _controller.pause();
                      } else {
                        _controller.play();
                      }
                    });
                  },
                  child: Icon(
                    _controller.value.isPlaying
                        ? null
                        : CupertinoIcons.play_fill,
                    color: Theme.of(context).colorScheme.secondary,
                    size: 80.0,
                  ),
                ),
              ),
            ],
          );
        } else {
          return Container(
            height: widget.height!.ceilToDouble() / 4,
            child: Center(
              child: circularProgress(),
            ),
          );
        }
      },
    );
  }
}
