import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sm_app/pages/authentification/login_or_register.dart';
import 'package:sm_app/pages/home.dart';

class AuthentificationPage extends StatelessWidget {
  const AuthentificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: ((context, snapshot) {
        if (snapshot.hasData) {
          return Home();
        } else {
          return LoginOrRegister();
        }
      }),
    );
  }
}
