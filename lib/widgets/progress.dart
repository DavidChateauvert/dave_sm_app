import 'package:flutter/material.dart';

Container circularProgress() {
  return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.only(top: 10.0),
      child: const CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation(Color.fromARGB(255, 89, 36, 99)),
      ));
}

Container linearProgress() {
  return Container(
    padding: EdgeInsets.only(bottom: 10.0),
    child: const LinearProgressIndicator(
        valueColor: AlwaysStoppedAnimation(Color.fromARGB(255, 89, 36, 99))),
  );
}
