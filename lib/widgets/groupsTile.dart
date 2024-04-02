import 'package:flutter/material.dart';

// ignore: must_be_immutable
class GroupTile extends StatefulWidget {
  final String name;
  bool isSelected;
  GroupTile({super.key, required this.name, required this.isSelected});

  @override
  State<GroupTile> createState() => _GroupTileState();
}

class _GroupTileState extends State<GroupTile> {
  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () => setState(() {
        widget.isSelected = !widget.isSelected;
      }),
      title: Text(
        widget.name,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onBackground,
        ),
      ),
    );
  }
}
