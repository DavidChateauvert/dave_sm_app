import 'package:flutter/material.dart';
import 'package:sm_app/widgets/playVideo.dart';

class PlayVideoFullPage extends StatefulWidget {
  final String mediaUrl;
  final int height;
  final int width;

  const PlayVideoFullPage({
    required this.mediaUrl,
    required this.height,
    required this.width,
  });

  @override
  State<PlayVideoFullPage> createState() => _PlayVideoFullPageState();
}

class _PlayVideoFullPageState extends State<PlayVideoFullPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Stack(
      children: [
        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: PlayVideo(
                  videoUrl: widget.mediaUrl,
                  type: "message",
                  file: null,
                  height: widget.height,
                  width: widget.width,
                ),
              ),
            ],
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
    ));
  }
}
