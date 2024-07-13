import 'package:flutter/material.dart';

class PostCounterProvider with ChangeNotifier {
  int _postCounter = 0;
  List<String> _deletedPostList = [];

  int get postCounter => _postCounter;

  set postCounter(int postCounter) {
    _postCounter = postCounter;
    notifyListeners();
  }

  void seenPost(String postId) {
    if (!_deletedPostList.contains(postId)) {
      _postCounter = --_postCounter;
      notifyListeners();
      _deletedPostList.add(postId);
    }
  }

  bool isSeenPost(String postId) {
    if (_deletedPostList.contains(postId)) {
      return true;
    }
    return false;
  }
}
