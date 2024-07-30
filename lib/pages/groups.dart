import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:sm_app/models/groups.dart';
import 'package:sm_app/models/user.dart';
import 'package:sm_app/pages/home.dart';
import 'package:sm_app/widgets/groupsTile.dart';
import 'package:sm_app/widgets/progress.dart';
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
  Map<String, bool> selectedGroupForEdit = {};
  bool isGroupLoading = true;
  bool isFriendLoading = true;
  bool isChangingAGroup = false;
  late TextEditingController controller;

  @override
  void initState() {
    super.initState();
    getGroups();
    getFriends();
    controller = TextEditingController();
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
      if (doc['name'] != "") {
        groupResultInit.add(
            Group(id: doc.id, name: doc['name'], usersInGroup: usersInGroup));
      }
    }

    setState(() {
      this.groupResult = groupResultInit;
      isGroupLoading = false;
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
        this.isFriendLoading = false;
      });
    }
  }

  updateGroupInFirestore() async {
    Group groupSelected = Group(id: "", name: "", usersInGroup: []);

    this.selectedGroup.forEach((key, value) {
      if (value) {
        groupResult.forEach((doc) {
          if (doc.id == key) {
            groupSelected = doc;
          }
        });
      }
    });

    // Delete group
    await groupsRef
        .doc(currentUser.id)
        .collection('userGroups')
        .doc(groupSelected.id)
        .delete();

    await groupsRef
        .doc(currentUser.id)
        .collection('userGroups')
        .doc(groupSelected.id)
        .set({"name": groupSelected.name, "saveGroup": true});

    // Recreate it
    List<String> usersInGroup = [];
    selectedUser.forEach((key, value) async {
      if (value) {
        usersInGroup.add(key);
        await groupsRef
            .doc(currentUser.id)
            .collection('userGroups')
            .doc(groupSelected.id)
            .collection("users")
            .doc(key)
            .set({});
      }
    });
    groupResult.forEach((doc) {
      if (doc.id == groupSelected.id) {
        doc.usersInGroup = usersInGroup;
      }
    });
  }

  createGroup(bool createWithName) {
    String groupId = Uuid().v4();
    groupsRef.doc(currentUser.id).collection('userGroups').doc(groupId).set({
      "name": createWithName ? controller.text : "",
      "saveGroup": createWithName
    });

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
        name: createWithName ? controller.text : "",
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

  handleCreateGroup(context) {
    Navigator.pop(context);
    Group groupReturn = createGroup(true);
    controller.clear();
    Navigator.pop(context, groupReturn);
  }

  showCreateGroupModal(context) {
    return showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(AppLocalizations.of(context)!.enter_group_name),
              content: TextField(
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.hint_text_group_name,
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primaryContainer,
                    ),
                  ),
                ),
                cursorColor: Theme.of(context).colorScheme.primaryContainer,
                controller: controller,
                onChanged: (_) {
                  setState(() {});
                },
              ),
              actions: [
                TextButton(
                  onPressed: controller.text.isEmpty
                      ? null
                      : () {
                          handleCreateGroup(context);
                        },
                  child: Text(
                    AppLocalizations.of(context)!.confirm,
                    style: TextStyle(
                      color: controller.text.isEmpty
                          ? Colors.grey
                          : Theme.of(context).colorScheme.primaryContainer,
                    ),
                  ),
                )
              ],
            );
          },
        );
      },
    );
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
                Navigator.pop(context);
                showCreateGroupModal(context);
              },
              child: Text(
                AppLocalizations.of(context)!.create_group,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onBackground,
                ),
              ),
            ),
            SimpleDialogOption(
              onPressed: () {
                Group groupReturn = createGroup(false);
                Navigator.pop(context);
                Navigator.pop(context, groupReturn);
              },
              child: Text(
                AppLocalizations.of(context)!.no_create_group,
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
      if (!this.selectedGroupForEdit.values.contains(true)) {
        selectedGroup.forEach((key, value) {
          this.selectedGroup[key] = false;
        });
      }
    });
  }

  resetSelectedUser() {
    setState(() {
      selectedUser.forEach((key, _) {
        selectedUser[key] = false;
      });
    });
  }

  toggleSelectedGroup(String groupId, bool isSelected, bool isSelectedForEdit) {
    setState(() {
      this.selectedGroup[groupId] = !isSelected;
      selectedGroup.forEach((key, value) {
        if (key != groupId) {
          this.selectedGroup[key] = false;
        }
      });
    });
    if (isSelectedForEdit) {
      setState(() {
        this.selectedGroupForEdit[groupId] = !isSelectedForEdit;
      });
      showEditConfirmModal(context);
    }

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

  toggleEditGroup(String groupId, bool isSelected, bool isSelectedForEdit) {
    setState(() {
      this.selectedGroupForEdit[groupId] = !isSelectedForEdit;
      selectedGroupForEdit.forEach((key, value) {
        if (key != groupId) {
          this.selectedGroupForEdit[key] = false;
        }
      });
    });

    if (isSelectedForEdit) {
      showEditConfirmModal(context);
    }

    if (!isSelected) {
      toggleSelectedGroup(groupId, isSelected, isSelectedForEdit);
    }
  }

  Future<bool?> showEditConfirmModal(BuildContext parentContext) {
    return showDialog<bool>(
      context: parentContext,
      builder: (context) {
        return SimpleDialog(
          title: Center(
            child: Text(
              AppLocalizations.of(context)!.sure_change_group,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primaryContainer,
              ),
            ),
          ),
          children: [
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                AppLocalizations.of(context)!.cancel,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.red,
                ),
              ),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context);
                updateGroupInFirestore();
              },
              child: Text(
                AppLocalizations.of(context)!.confirm,
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
      body: (!isGroupLoading && !isFriendLoading)
          ? SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Center(
                            child: Text(
                              AppLocalizations.of(context)!.groups,
                              style: TextStyle(
                                fontSize: 32.0,
                                color:
                                    Theme.of(context).colorScheme.onBackground,
                              ),
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: null,
                          child: Text(
                            AppLocalizations.of(context)!
                                .reset_selected_friends,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.background,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(
                    thickness: 0.5,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  ListView.builder(
                    reverse: true,
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: groupResult.length,
                    itemBuilder: (context, index) {
                      return GroupTile(
                        isSelected:
                            this.selectedGroup[this.groupResult[index].id] ??
                                false,
                        isSelectedForEdit: this.selectedGroupForEdit[
                                this.groupResult[index].id] ??
                            false,
                        group: this.groupResult[index],
                        onSelectedStateChanged:
                            (groupId, isSelected, isSelectedForEdit) {
                          toggleSelectedGroup(
                              groupId, isSelected, isSelectedForEdit);
                        },
                        onSelectedEditStateChanged:
                            (groupId, isSelected, isSelectedForEdit) {
                          toggleEditGroup(
                              groupId, isSelected, isSelectedForEdit);
                        },
                      );
                    },
                  ),
                  Divider(
                    thickness: 0.5,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Center(
                            child: Text(
                              AppLocalizations.of(context)!.friends,
                              style: TextStyle(
                                fontSize: 32.0,
                                color:
                                    Theme.of(context).colorScheme.onBackground,
                              ),
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: resetSelectedUser,
                          child: Text(
                            AppLocalizations.of(context)!
                                .reset_selected_friends,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(
                    thickness: 0.5,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: userResult.length,
                    itemBuilder: (context, index) {
                      return UserForGroup(
                        isSelected:
                            this.selectedUser[this.userResult[index].id] ??
                                false,
                        user: this.userResult[index],
                        onSelectedStateChanged: (userId, isSelected) {
                          toggleSelectedUser(userId, isSelected);
                        },
                      );
                    },
                  ),
                ],
              ),
            )
          : circularProgress(context),
    );
  }
}
