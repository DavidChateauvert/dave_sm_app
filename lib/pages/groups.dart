import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:sm_app/models/groups.dart';
import 'package:sm_app/models/user.dart';
import 'package:sm_app/pages/home.dart';
import 'package:sm_app/widgets/groupsTile.dart';
import 'package:sm_app/widgets/userForGroup.dart';
import 'package:uuid/uuid.dart';

class Groups extends StatefulWidget {
  const Groups({super.key});

  @override
  State<Groups> createState() => _GroupsState();
}

class _GroupsState extends State<Groups> {
  List<User> userResult = [];
  Map<String, bool> selectedUser = {};
  List<Group> groupResult = [];
  Map<String, bool> selectedGroup = {};

  @override
  void initState() {
    super.initState();
    getGroups();
    getFriends();
  }

  getGroups() async {
    QuerySnapshot groupsSnapshot =
        await groupsRef.doc(currentUser.id).collection('userGroups').get();

    List<Group> groupResultInit = [];

    for (var doc in groupsSnapshot.docs) {
      List<String> usersInGroup = [];
      QuerySnapshot groupsSnapshotInside = await groupsRef
          .doc(currentUser.id)
          .collection('userGroups')
          .doc(doc.id)
          .collection("users")
          .get();
      groupsSnapshotInside.docs.forEach((doc) {
        usersInGroup.add(doc.id);
      });
      groupResultInit.add(
          Group(id: doc.id, name: doc['name'], usersInGroup: usersInGroup));
    }

    setState(() {
      this.groupResult = groupResultInit;
    });
  }

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
        setState(() {
          selectedUser[user.id] = true;
        });
      }
    });

    if (mounted) {
      setState(() {
        this.userResult = userForGroup;
      });
    }
  }

  createGroup() {
    String groupId = Uuid().v4();
    groupsRef
        .doc(currentUser.id)
        .collection('userGroups')
        .doc(groupId)
        .set({"name": "Group ${groupResult.length + 1}"});

    List<String> usersInGroup = [];
    selectedUser.forEach((key, value) async {
      if (value) {
        usersInGroup.add(key);
        await groupsRef
            .doc(currentUser.id)
            .collection('userGroups')
            .doc(groupId)
            .collection("users")
            .doc(key)
            .set({});
      }
    });

    return Group(
        id: groupId,
        name: "Group ${groupResult.length + 1}",
        usersInGroup: usersInGroup);
  }

  handleExit(BuildContext context) {
    // If a group is selected
    if (this.selectedGroup.values.contains(true)) {
      Group? groupSelected;
      this.selectedGroup.forEach((key, value) {
        if (value) {
          groupResult.forEach((doc) {
            if (doc.id == key) {
              groupSelected = doc;
            }
          });
        }
      });
      if (groupSelected != null) {
        Navigator.pop(context, groupSelected);
      }
    } // Ask to create a group
    else if (this.selectedUser.values.contains(false)) {
      showConfirmModal(context);
    } else {
      Navigator.pop(context);
    }
  }

  showConfirmModal(parentContext) {
    return showDialog(
      context: parentContext,
      builder: (context) {
        return SimpleDialog(
          title: Center(
            child: Text(
              AppLocalizations.of(context)!.create_group_question,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primaryContainer,
              ),
            ),
          ),
          children: [
            SimpleDialogOption(
              onPressed: () {
                Group groupReturn = createGroup();
                Navigator.pop(context);
                Navigator.pop(context, groupReturn);
              },
              child: Text(
                AppLocalizations.of(context)!.create_group,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onBackground,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  toggleSelectedUser(String userId, bool isSelected) {
    setState(() {
      this.selectedUser[userId] = !isSelected;
      selectedGroup.forEach((key, value) {
        this.selectedGroup[key] = false;
      });
    });
  }

  toggleSelectedGroup(String groupId, bool isSelected) {
    setState(() {
      this.selectedGroup[groupId] = !isSelected;
      selectedGroup.forEach((key, value) {
        if (key != groupId) {
          this.selectedGroup[key] = false;
        }
      });
    });

    if (!isSelected) {
      this.groupResult.forEach((doc) {
        if (doc.id == groupId) {
          selectedUser.forEach((key, value) {
            if (doc.usersInGroup.contains(key)) {
              this.selectedUser[key] = !isSelected;
            } else {
              this.selectedUser[key] = false;
            }
          });
        }
      });
    } else {
      selectedUser.forEach((key, value) {
        this.selectedUser[key] = true;
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
              Icons.clear,
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
            IconButton(
              icon: Icon(
                Icons.done,
                color: Colors.white,
                size: 32.0,
              ),
              onPressed: () => handleExit(context),
            ),
          ],
        ),
        body: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              ListView.builder(
                reverse: true,
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: groupResult.length,
                itemBuilder: (context, index) {
                  return GroupTile(
                    isSelected:
                        this.selectedGroup[this.groupResult[index].id] ?? false,
                    group: this.groupResult[index],
                    onSelectedStateChanged: (groupId, isSelected) {
                      toggleSelectedGroup(groupId, isSelected);
                    },
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
                    isSelected:
                        this.selectedUser[this.userResult[index].id] ?? false,
                    user: this.userResult[index],
                    onSelectedStateChanged: (userId, isSelected) {
                      toggleSelectedUser(userId, isSelected);
                    },
                  );
                },
              ),
              Divider(),
            ],
          ),
        ));
  }
}
