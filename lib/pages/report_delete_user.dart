// ignore_for_file: prefer_const_constructors

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sm_app/pages/home.dart';
import 'package:sm_app/widgets/header.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:status_alert/status_alert.dart';

class ReportDeleteUser extends StatefulWidget {
  final String userId;

  ReportDeleteUser({required this.userId});

  @override
  _ReportDeleteUserState createState() => _ReportDeleteUserState();
}

class _ReportDeleteUserState extends State<ReportDeleteUser> {
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
    StatusAlert.show(
      context,
      duration: Duration(seconds: 2),
      title: AppLocalizations.of(context)!.goodbye,
      configuration: IconConfiguration(icon: Icons.waving_hand),
      maxWidth: 260,
      backgroundColor: Theme.of(context).colorScheme.secondary,
    );
    deleteUser();
  }

  deleteUser() async {
    Navigator.pop(context);
    Navigator.pop(context);
    await usersRef.doc(currentUser.id).delete();
    User? userToDelete = FirebaseAuth.instance.currentUser;
    if (userToDelete != null) {
      userToDelete.delete();
    }
  }

  sendEmailReportPost() {
    reportsRef.add(
      {
        "to": ["david.chateauvert25@gmail.com"],
        "message": {
          "subject":
              "Delete user : ${currentUser.displayName} id : ${currentUser.id}",
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
          onSaved: (val) => reportText = val!,
          decoration: InputDecoration(
            labelStyle: TextStyle(fontSize: 15.0),
            hintText: AppLocalizations.of(context)!.why,
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
          titleText: AppLocalizations.of(context)!.delete_user,
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
                  AppLocalizations.of(context)!.reason_delete_user,
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
                      AppLocalizations.of(context)!.delete_user,
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
