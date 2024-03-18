import 'package:flutter/material.dart';
import 'package:sm_app/pages/authentification/login.dart';
import 'package:sm_app/pages/authentification/sign_up.dart';

class LoginOrRegister extends StatefulWidget {
  const LoginOrRegister({super.key});

  @override
  State<LoginOrRegister> createState() => _LoginOrRegisterState();
}

class _LoginOrRegisterState extends State<LoginOrRegister> {
  bool showLogin = true;

  toggleRegistrationPage() {
    setState(() {
      showLogin = !showLogin;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (showLogin) {
      return Login(onTap: toggleRegistrationPage);
    } else {
      return SignUp(onTap: toggleRegistrationPage);
    }
  }
}
