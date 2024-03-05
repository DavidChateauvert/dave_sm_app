// ignore_for_file: prefer_const_constructors

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sm_app/pages/home.dart';
import 'package:sm_app/widgets/header.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ContactUs extends StatefulWidget {
  @override
  _ContactUsState createState() => _ContactUsState();
}

class _ContactUsState extends State<ContactUs> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();
  FocusNode focusNode = FocusNode();
  late String text;

  submit() {
    final form = _formKey.currentState;

    if (form!.validate()) {
      form.save();
      focusNode.unfocus();
      sendEmailReportPost();
      showThankYouDialog(context);
      text = "";
    }
  }

  showThankYouDialog(BuildContext parentContext) {
    return showCupertinoDialog(
      context: parentContext,
      builder: (context) {
        return SimpleDialog(
          title: Text(
            AppLocalizations.of(context)!.thanks_input,
            textAlign: TextAlign.center,
          ),
          children: <Widget>[
            Padding(
              padding: EdgeInsets.only(left: 20.0, right: 20.0),
              child: Text(
                textAlign: TextAlign.center,
                AppLocalizations.of(context)!.please_continue,
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(
                  CupertinoIcons.back,
                  color: Theme.of(context).colorScheme.primary,
                ),
                Text(
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                  AppLocalizations.of(context)!.go_back_settings,
                ),
              ]),
            ),
          ],
        );
      },
    );
  }

  sendEmailReportPost() {
    reportsRef.add(
      {
        "to": ["david.chateauvert25@gmail.com"],
        "message": {
          "subject": "Contacted by ${currentUser.displayName}",
          "html": text,
        },
      },
    );
  }

  buildFormReport() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          focusNode: focusNode,
          validator: (val) {
            if (val!.isEmpty) {
              return AppLocalizations.of(context)!.report_text_error;
            } else {
              return null;
            }
          },
          onSaved: (val) => text = val!,
          decoration: InputDecoration(
            labelStyle: TextStyle(fontSize: 15.0),
            hintText: AppLocalizations.of(context)!.write_us,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: header(context,
          titleText: AppLocalizations.of(context)!.contact_us,
          removeBackButton: false,
          showMessageButton: false),
      body: ListView(children: <Widget>[
        Container(
          child: Column(
            children: <Widget>[
              Padding(
                padding: EdgeInsets.all(25.0),
                child: Text(
                  AppLocalizations.of(context)!.contact_us_text,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16.0),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(
                  right: 16.0,
                  left: 16.0,
                  bottom: 32.0,
                ),
                child: Container(
                  child: Form(
                    key: _formKey,
                    autovalidateMode: AutovalidateMode.always,
                    child: Column(
                      children: [
                        buildFormReport(),
                      ],
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: submit,
                child: Container(
                  height: 50.0,
                  width: 350.0,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(7.0),
                  ),
                  child: Center(
                    child: Text(
                      AppLocalizations.of(context)!.submit_report,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15.0,
                        fontWeight: FontWeight.bold,
                      ),
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
