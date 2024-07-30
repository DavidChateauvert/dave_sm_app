import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:sm_app/widgets/progress.dart';
import 'package:video_player/video_player.dart';

// ignore: must_be_immutable
class OnboardingScreen2 extends StatefulWidget {
  String locale;
  OnboardingScreen2({Key? key, required this.locale}) : super(key: key);

  @override
  _OnboardingScreen2State createState() => _OnboardingScreen2State();
}

class _OnboardingScreen2State extends State<OnboardingScreen2> {
  late VideoPlayerController _controller;
  late Future<void> _initializeVideoPlayerFuture;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset(widget.locale == "en"
        ? "assets/onboarding/video-screen-2-en.mp4"
        : "assets/onboarding/video-screen-2-fr.mp4");

    _initializeVideoPlayerFuture = _controller.initialize();
    _controller.setLooping(true);

    _controller.setVolume(0);
    _controller.play();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  buildVideo() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8.0),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.6,
        child: FutureBuilder(
          future: _initializeVideoPlayerFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              );
            } else {
              return circularProgress(context);
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.secondary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.1,
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                AppLocalizations.of(context)!.onboarding_screen_2_top,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.normal,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            SizedBox(
              height: widget.locale == "en" ? 32 : 16,
            ),
            buildVideo(),
            SizedBox(
              height: widget.locale == "en" ? 32 : 16,
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                AppLocalizations.of(context)!.onboarding_screen_2_bottom,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.normal,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
