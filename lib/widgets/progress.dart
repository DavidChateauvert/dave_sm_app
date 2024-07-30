import 'package:flutter/material.dart';

Container circularProgress(context) {
  return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.only(top: 10.0),
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation(
          Theme.of(context).colorScheme.primaryContainer,
        ),
      ));
}

Container linearProgress(context) {
  return Container(
    padding: EdgeInsets.only(bottom: 10.0),
    child: LinearProgressIndicator(
      valueColor: AlwaysStoppedAnimation(
          Theme.of(context).colorScheme.primaryContainer),
    ),
  );
}
