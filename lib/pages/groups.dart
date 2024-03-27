import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:sm_app/models/user.dart';
import 'package:sm_app/pages/home.dart';
import 'package:sm_app/widgets/userForGroup.dart';

class Groups extends StatefulWidget {
  const Groups({super.key});

  @override
  State<Groups> createState() => _GroupsState();
}

class _GroupsState extends State<Groups> {
  String chosenGroup = "";
  List<User> userResult = [];

  @override
  void initState() {
    super.initState();
    // getGroups();
    getFriends();
  }

  // getGroups()

  getFriends() async {
    QuerySnapshot friendsSnapshot =
        await friendsRef.doc(currentUser.id).collection('userFriends').get();

    List<String> userIds = [];

    friendsSnapshot.docs.forEach((doc) {
      userIds.add(doc.id);
    });

    QuerySnapshot userSnapshot = await usersRef.get();

    List<User> userForGroup = [];

    userSnapshot.docs.forEach((doc) {
      if (userIds.contains(doc['id'])) {
        User user = User.fromDocument(doc);
        userForGroup.add(user);
      }
    });

    if (mounted) {
      setState(() {
        this.userResult = userForGroup;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          leading: IconButton(
            icon: Icon(
              CupertinoIcons.clear_thick,
              color: Colors.white,
              size: 32.0,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            AppLocalizations.of(context)!.groups,
            style: TextStyle(
              color: Colors.white,
              fontSize: 30.0,
            ),
          ),
          centerTitle: true,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, chosenGroup),
              child: Text(
                AppLocalizations.of(context)!.add_group,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: userResult.length,
                itemBuilder: (context, index) {
                  return UserForGroup(
                    isSelected: false,
                    user: this.userResult[index],
                  );
                },
              ),
              Divider(),
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: userResult.length,
                itemBuilder: (context, index) {
                  return UserForGroup(
                    isSelected: false,
                    user: this.userResult[index],
                  );
                },
              ),
              Divider(),
            ],
          ),
        ));
  }
}
