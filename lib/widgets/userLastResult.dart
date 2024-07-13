import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:sm_app/models/user.dart';
import 'package:sm_app/pages/home.dart';
import 'package:sm_app/pages/search.dart';

// ignore: must_be_immutable
class UserLastResult extends StatefulWidget {
  final User user;

  UserLastResult(this.user);

  @override
  _UserLastResultState createState() => _UserLastResultState();
}

class _UserLastResultState extends State<UserLastResult> {
  bool isDeleted = false;
  deleteLastSearch() async {
    setState(() {
      isDeleted = true;
    });
    await lastSearchRef
        .doc(currentUser.id)
        .collection('lastSearchUsers')
        .doc(widget.user.id)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    return isDeleted
        ? Container()
        : Container(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
            child: Column(
              children: <Widget>[
                TextButton(
                  onPressed: () =>
                      showProfile(context, profileId: widget.user.id),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.grey,
                      backgroundImage:
                          CachedNetworkImageProvider(widget.user.photoUrl),
                    ),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.clear,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        setState(() {
                          deleteLastSearch();
                        });
                      },
                    ),
                    title: Row(
                      children: [
                        Text(
                          widget.user.displayName,
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(width: 4.0),
                        widget.user.verified
                            ? Icon(
                                Icons.verified_sharp,
                                color: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer,
                                size: 17.0,
                              )
                            : Text(""),
                      ],
                    ),
                  ),
                ),
                Divider(
                  height: 2.0,
                  color: Colors.white54,
                )
              ],
            ),
          );
  }
}
