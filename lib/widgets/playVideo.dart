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
  bool isPlayingVolume = true;

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

    _controller.setVolume(1);

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
                    size: 70.0,
                  ),
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: IconButton(
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  icon: Icon(
                    isPlayingVolume
                        ? Icons.volume_up_outlined
                        : Icons.volume_off_outlined,
                    color: Theme.of(context).colorScheme.secondary,
                    size: 30.0,
                  ),
                  onPressed: () {
                    if (isPlayingVolume) {
                      setState(() {
                        isPlayingVolume = false;
                        _controller.setVolume(0.0);
                      });
                    } else {
                      setState(() {
                        isPlayingVolume = true;
                        _controller.setVolume(1.0);
                      });
                    }
                  },
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
