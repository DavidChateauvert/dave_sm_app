import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sm_app/widgets/header.dart';

class AboutUs extends StatefulWidget {
  @override
  _AboutUsState createState() => _AboutUsState();
}

class _AboutUsState extends State<AboutUs> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: header(context,
          titleText: "About Us",
          removeBackButton: false,
          showMessageButton: false),
      body: ListView(children: <Widget>[
        Container(
          child: Column(
            children: <Widget>[
              Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  textAlign: TextAlign.justify,
                  "Dave is a social media app that tries to replicate the instant nature of real life. On other social media app, every post made is set in stone on the internet. On Dave, people can only see your post once and screenshotting it is impossible. Just like in real life, when somebody says something, the thing being said is gone forverer and Dave is replicating this experience online. Dave is only at a beginning stage right now so if there's any bug, please let us know in the 'Contact Us' section on the app. Enjoy Dave !",
                  style: TextStyle(fontSize: 16.0),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  textAlign: TextAlign.center,
                  "People behing this app",
                  style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  textAlign: TextAlign.center,
                  "David Châteauvert",
                  style: TextStyle(
                    fontSize: 16.0,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 32.0),
                child: TextButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    CupertinoIcons.back,
                  ),
                  label: const Text(
                    "Go back to the settings",
                    style: TextStyle(
                      fontSize: 20.0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        )
      ]),
    );
  }
}
