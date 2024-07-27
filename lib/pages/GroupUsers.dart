// ignore_for_file: prefer_const_constructors
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sm_app/pages/home.dart';
import 'package:sm_app/pages/search.dart';
import '../models/user.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class GroupUsers extends StatefulWidget {
  final String groupId;

  GroupUsers({required this.groupId});

  @override
  _GroupUsers createState() => _GroupUsers();
}

class _GroupUsers extends State<GroupUsers> {
  String? groupName;
  List<UserResult> userResult = [];

  getUsers() async {
    QuerySnapshot usersSnapshot;

    if (widget.groupId == "") {
      usersSnapshot =
          await friendsRef.doc(currentUser.id).collection('userFriends').get();
    } else {
      usersSnapshot = await groupsRef
          .doc(currentUser.id)
          .collection("userGroups")
          .doc(widget.groupId)
          .collection("users")
          .get();

      DocumentSnapshot doc = await groupsRef
          .doc(currentUser.id)
          .collection("userGroups")
          .doc(widget.groupId)
          .get();
      if (doc.exists) {
        if (doc.data().toString().contains('name')) {
          setState(() {
            groupName = doc['name'];
          });
        }
      }
    }

    List<String> userIds = [];

    usersSnapshot.docs.forEach((doc) {
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
    getUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: Text(
          AppLocalizations.of(context)!.group,
          style: const TextStyle(color: Colors.white, fontSize: 30.0),
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 89, 36, 99),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          groupName != null && groupName != ""
              ? Container(
                  color: Theme.of(context).colorScheme.primary,
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          groupName!,
                          style: TextStyle(
                            fontSize: 32.0,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Container(),
          Expanded(
            child: ListView(
              children: userResult,
            ),
          ),
        ],
      ),
    );
  }
}
