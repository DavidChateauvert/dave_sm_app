import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sm_app/models/user.dart';

// ignore: must_be_immutable
class UserForGroup extends StatefulWidget {
  final User user;
  bool isSelected;

  UserForGroup({super.key, required this.user, required this.isSelected});

  @override
  State<UserForGroup> createState() => _UserForGroupState();
}

class _UserForGroupState extends State<UserForGroup> {
  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () => setState(() {
        widget.isSelected = !widget.isSelected;
      }),
      trailing: Icon(
        widget.isSelected
            ? CupertinoIcons.check_mark_circled_solid
            : CupertinoIcons.circle,
        color: Theme.of(context).colorScheme.primaryContainer,
      ),
      leading: CircleAvatar(
        backgroundColor: Colors.grey,
        backgroundImage: CachedNetworkImageProvider(widget.user.photoUrl),
      ),
      title: Text(
        widget.user.displayName,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onBackground,
        ),
      ),
    );
  }
}
