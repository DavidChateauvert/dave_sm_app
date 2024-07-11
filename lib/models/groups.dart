import 'package:cloud_firestore/cloud_firestore.dart';

class Group {
  final String id;
  final String name;
  List<String> usersInGroup;
  Group({
    required this.id,
    required this.name,
    required this.usersInGroup,
  });
  factory Group.fromDocument(DocumentSnapshot doc) {
    return Group(
        id: doc['id'], name: doc['name'], usersInGroup: doc['usersInGroup']);
  }
}
