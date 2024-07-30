// ignore_for_file: prefer_const_constructors
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sm_app/pages/home.dart';
import 'package:sm_app/pages/search.dart';
import 'package:sm_app/widgets/progress.dart';
import '../models/user.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class Friends extends StatefulWidget {
  final String profileId;

  Friends({required this.profileId});

  @override
  _Friends createState() => _Friends();
}

class _Friends extends State<Friends> {
  List<UserResult> userResult = [];

  buildFollowing() {
    // ignore: unnecessary_null_comparison
    if (userResult == null) {
      return circularProgress(context);
    } else if (userResult.isEmpty) {
      return circularProgress(context);
    }
    return ListView(
      children: userResult,
    );
  }

  getFriends() async {
    QuerySnapshot friendsSnapshot =
        await friendsRef.doc(widget.profileId).collection('userFriends').get();

    List<String> userIds = [];

    friendsSnapshot.docs.forEach((doc) {
      userIds.add(doc.id);
    });

    QuerySnapshot userSnapshot = await usersRef.get();

    List<UserResult> userResults = [];

    userSnapshot.docs.forEach((doc) {
      if (userIds.contains(doc['id'])) {
        User user = User.fromDocument(doc);
        userResults.add(UserResult(user, false));
      }
    });

    if (mounted) {
      setState(() {
        this.userResult = userResults;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    getFriends();
  }

  @override
  Widget build(context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: Text(
          AppLocalizations.of(context)!.friends,
          style: const TextStyle(color: Colors.white, fontSize: 30.0),
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 89, 36, 99),
      ),
      body: buildFollowing(),
    );
  }
}
