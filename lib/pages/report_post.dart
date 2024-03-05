// ignore_for_file: prefer_const_constructors

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sm_app/pages/home.dart';
import 'package:sm_app/widgets/header.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ReportPost extends StatefulWidget {
  final String postId;
  final String reportSubject;

  ReportPost({required this.postId, required this.reportSubject});

  @override
  _ReportPostState createState() => _ReportPostState();
}

class _ReportPostState extends State<ReportPost> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();
  FocusNode reportFocusNode = FocusNode();
  late String reportText;

  submit() {
    final form = _formKey.currentState;

    if (form!.validate()) {
      form.save();
      reportFocusNode.unfocus();
      sendEmailReportPost();
      showThankYouDialog(context);
      reportText = "";
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
                widget.reportSubject == "post"
                    ? AppLocalizations.of(context)!.rewiew_text_post
                    : AppLocalizations.of(context)!.rewiew_text_user,
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
                  AppLocalizations.of(context)!.go_back_timeline,
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
          "subject":
              "Report for the ${widget.reportSubject} ${widget.postId} from ${currentUser.displayName}",
          "html": reportText,
        },
      },
    );
  }

  buildFormReport() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          focusNode: reportFocusNode,
          validator: (val) {
            if (val!.isEmpty) {
              return AppLocalizations.of(context)!.report_text_error;
            } else {
              return null;
            }
          },
          onSaved: (val) => reportText = val!,
          decoration: InputDecoration(
            labelStyle: TextStyle(fontSize: 15.0),
            hintText: widget.reportSubject == "post"
                ? AppLocalizations.of(context)!.report_text_hint_post
                : AppLocalizations.of(context)!.report_text_hint_user,
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
          titleText: widget.reportSubject == "post"
              ? AppLocalizations.of(context)!.report_post_app_bar
              : AppLocalizations.of(context)!.report_user_app_bar,
          removeBackButton: false,
          showMessageButton: false),
      body: ListView(children: <Widget>[
        Container(
          child: Column(
            children: <Widget>[
              Padding(
                padding: EdgeInsets.only(top: 25.0),
                child: Text(
                  textAlign: TextAlign.center,
                  widget.reportSubject == "post"
                      ? AppLocalizations.of(context)!.description_report_post
                      : AppLocalizations.of(context)!.description_report_user,
                  style: TextStyle(fontSize: 25.0),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(16.0),
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
