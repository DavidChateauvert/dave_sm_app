// ignore_for_file: prefer_const_constructors

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sm_app/pages/home.dart';
import 'package:sm_app/widgets/header.dart';

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
            "Thank for your intput !",
            textAlign: TextAlign.center,
          ),
          children: <Widget>[
            Padding(
              padding: EdgeInsets.only(left: 20.0, right: 20.0),
              child: Text(
                textAlign: TextAlign.center,
                "Our team is going to review your report and then decide what to do with the ${widget.reportSubject}",
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
                  'Go back to the timeline',
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
              return "Your report cannot be empty";
            } else {
              return null;
            }
          },
          onSaved: (val) => reportText = val!,
          decoration: InputDecoration(
            labelStyle: TextStyle(fontSize: 15.0),
            hintText: widget.reportSubject == "post"
                ? "Why should this post be reported ?"
                : "Why should this user be reported ?",
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
          titleText:
              widget.reportSubject == "post" ? "Report Post" : "Report User",
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
                      ? "Please tell us why your are reporting this post"
                      : "Please tell us why your are reporting this user",
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
                      "Submit Report",
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
