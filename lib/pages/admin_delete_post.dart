// ignore_for_file: prefer_const_constructors
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sm_app/pages/home.dart';
import 'package:sm_app/widgets/header.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:status_alert/status_alert.dart';

class AdminDeletePost extends StatefulWidget {
  AdminDeletePost({super.key});

  @override
  _AdminDeletePostState createState() => _AdminDeletePostState();
}

class _AdminDeletePostState extends State<AdminDeletePost> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();
  FocusNode reportFocusNode = FocusNode();
  late String reportText;
  String? password;
  int nbAttempts = 0;

  @override
  void initState() {
    super.initState();
    getConfirmPassword();
  }

  getConfirmPassword() async {
    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('passwords')
        .doc('HMLtbbsJC2IndOhFQUeB')
        .get();
    if (doc.exists) {
      if (doc.data().toString().contains('deletePassword')) {
        password = doc['deletePassword'];
      }
    }
  }

  submit() {
    final form = _formKey.currentState;

    if (form!.validate()) {
      form.save();
      reportFocusNode.unfocus();
      if (reportText == password && nbAttempts <= 2) {
        StatusAlert.show(
          context,
          duration: Duration(seconds: 2),
          title: "Post Delete",
          configuration: IconConfiguration(icon: Icons.delete_forever),
          maxWidth: 260,
          backgroundColor: Theme.of(context).colorScheme.secondary,
        );
        Future.delayed(Duration(seconds: 1), () {
          Navigator.pop(context, true);
        });
      } else {
        showErrorMessage(++nbAttempts);
      }
      reportText = "";
    }
  }

  showErrorMessage(int nbAttempts) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            "Wrong Password",
            textAlign: TextAlign.center,
          ),
        );
      },
    );
    if (nbAttempts > 3) {
      sendEmailReportPost();
    }
  }

  sendEmailReportPost() {
    reportsRef.add(
      {
        "to": ["david.chateauvert25@gmail.com"],
        "message": {
          "subject":
              "Multiple error from admin app - RECOMMAND DISABLING ADMIN ACCOUNT",
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
          obscureText: true,
          validator: (val) {
            if (val!.isEmpty) {
              return "The password cannot be empty";
            } else {
              return null;
            }
          },
          onSaved: (val) => reportText = val!,
          decoration: InputDecoration(
            labelStyle: TextStyle(fontSize: 15.0),
            hintText: "Confirm Password",
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
          titleText: "Admin Delete Post",
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
                  "Please enter the confirm password to be able to delete this post",
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
