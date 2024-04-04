import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sm_app/models/groups.dart';

// ignore: must_be_immutable
class GroupTile extends StatefulWidget {
  final Group group;
  bool isSelected;
  final Function(String userId, bool isSelected) onSelectedStateChanged;

  GroupTile({
    Key? key,
    required this.group,
    required this.isSelected,
    required this.onSelectedStateChanged,
  }) : super(key: key);

  @override
  State<GroupTile> createState() => _GroupTileState();
}

class _GroupTileState extends State<GroupTile> {
  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () {
        setState(() {
          widget.onSelectedStateChanged(widget.group.id, widget.isSelected);
        });
      },
      trailing: Icon(
        widget.isSelected
            ? CupertinoIcons.check_mark_circled_solid
            : CupertinoIcons.circle,
        color: Theme.of(context).colorScheme.primaryContainer,
      ),
      title: Text(
        widget.group.name,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onBackground,
        ),
      ),
    );
  }
}
