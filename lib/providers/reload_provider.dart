import 'package:flutter/material.dart';

class ReloadNotifier extends ChangeNotifier {
  bool _shouldReloadMessageFeed = false;
  bool _shouldReloadActivityFeed = false;

  bool get shouldReloadMessageFeed => _shouldReloadMessageFeed;
  bool get shouldReloadActivityFeed => _shouldReloadActivityFeed;

  void setShouldReloadMessageFeed(bool value) {
    _shouldReloadMessageFeed = value;
    notifyListeners();
  }

  void setShouldReloadActivityFeed(bool value) {
    _shouldReloadActivityFeed = value;
    notifyListeners();
  }
}
