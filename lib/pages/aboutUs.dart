import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sm_app/widgets/header.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
          titleText: AppLocalizations.of(context)!.about_us_app_bar,
          removeBackButton: false,
          showMessageButton: false),
      body: ListView(children: <Widget>[
        Container(
          child: Column(
            children: <Widget>[
              Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  AppLocalizations.of(context)!.about_us_text,
                  textAlign: TextAlign.justify,
                  style: TextStyle(fontSize: 16.0),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  textAlign: TextAlign.center,
                  AppLocalizations.of(context)!.about_us_people,
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
                  label: Text(
                    AppLocalizations.of(context)!.go_back_settings,
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
