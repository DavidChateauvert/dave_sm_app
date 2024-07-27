import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';

class VideoControllerProvider extends ChangeNotifier {
  VideoPlayerController? _currentController;

  VideoPlayerController? get currentController => _currentController;

  void setController(VideoPlayerController controller) {
    if (_currentController != null && _currentController != controller) {
      _currentController!.pause();
    }
    _currentController = controller;
    notifyListeners();
  }
}
