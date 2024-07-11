import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sm_app/models/groups.dart';
import 'package:sm_app/pages/home.dart';

// ignore: must_be_immutable
class GroupTile extends StatefulWidget {
  final Group group;
  bool isSelected;
  bool isSelectedForEdit;
  final Function(String userId, bool isSelected, bool isSelectedForEdit)
      onSelectedStateChanged;
  final Function(String usedId, bool isSelected, bool isSelectedForEdit)
      onSelectedEditStateChanged;

  GroupTile({
    Key? key,
    required this.group,
    required this.isSelected,
    required this.isSelectedForEdit,
    required this.onSelectedStateChanged,
    required this.onSelectedEditStateChanged,
  }) : super(key: key);

  @override
  State<GroupTile> createState() => _GroupTileState();
}

class _GroupTileState extends State<GroupTile> {
  bool deleteInstant = false;

  deleteGroup() {
    setState(() {
      deleteInstant = true;
    });
    groupsRef
        .doc(currentUser.id)
        .collection('userGroups')
        .doc(widget.group.id)
        .delete();
  }

  editGroup() async {
    widget.onSelectedEditStateChanged(
        widget.group.id, widget.isSelected, widget.isSelectedForEdit);
  }

  handleClick() async {
    widget.onSelectedStateChanged(
        widget.group.id, widget.isSelected, widget.isSelectedForEdit);
  }

  @override
  Widget build(BuildContext context) {
    return deleteInstant
        ? Container()
        : Container(
            color: widget.isSelectedForEdit
                ? const Color.fromARGB(255, 195, 195, 195)
                : null,
            child: ListTile(
              onTap: () => handleClick(),
              leading: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () =>
                        widget.isSelectedForEdit ? null : deleteGroup(),
                  ),
                  IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () => editGroup(),
                    color: widget.isSelectedForEdit
                        ? Theme.of(context).colorScheme.primaryContainer
                        : null,
                  ),
                ],
              ),
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
            ),
          );
  }
}
