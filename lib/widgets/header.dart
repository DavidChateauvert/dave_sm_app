import 'package:flutter/material.dart';

AppBar header(context, { String? titleText, removeBackButton = false }) {
  return AppBar(
    automaticallyImplyLeading: removeBackButton ? false : true,
    title: Text(
      // ignore: prefer_if_null_operators
      titleText != null ? titleText : "Timeline",
      style: const TextStyle(
        color: Colors.white,
        fontSize: 30.0
      ),
      overflow: TextOverflow.ellipsis,
    ),
    centerTitle: true,
    backgroundColor: const Color.fromARGB(255, 89, 36, 99),
  );
}