import 'package:flutter/material.dart';
// import 'package:sm_app/api/firebase_api.dart';
import 'package:sm_app/pages/home.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await Firebase.initializeApp(
  //   options: FirebaseOptions(
  //     apiKey: "AIzaSyDSBBIJnN5cWAyVZGnTGfiq36wcsnynyz4",
  //     authDomain: "sm-app-4347b.firebaseapp.com",
  //     projectId: "sm-app-4347b",
  //     storageBucket: "sm-app-4347b.appspot.com",
  //     messagingSenderId: "988198906820",
  //     appId: "1:988198906820:web:f789a36eeccf962dbc5291",
  //     measurementId: "G-S2H4HQV6WG",
  // ));
  initializeFirebase();
  
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
      .then((_) {
    runApp(MyApp());
  });
}

void initializeFirebase() async {
  await Firebase.initializeApp();
  // await Firebase.initializeApp(
  //   options: FirebaseOptions(
  //     apiKey: "AIzaSyDSBBIJnN5cWAyVZGnTGfiq36wcsnynyz4",
  //     authDomain: "sm-app-4347b.firebaseapp.com",
  //     projectId: "sm-app-4347b",
  //     storageBucket: "sm-app-4347b.appspot.com",
  //     messagingSenderId: "988198906820",
  //     appId: "1:988198906820:web:f789a36eeccf962dbc5291",
  //     measurementId: "G-S2H4HQV6WG",
  // ));
  // await FirebaseApi().initMessaging();
}


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dave',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Color.fromARGB(255, 89, 36, 99),
      ),
      home: Home()
    ) ;
  }
}