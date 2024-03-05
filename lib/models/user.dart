import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String photoUrl;
  final String displayName;
  final String bio;
  final bool verified;
  final String theme;
  final Timestamp timestamp;
  final String locale;

  User(
      {required this.id,
      required this.username,
      required this.email,
      required this.photoUrl,
      required this.firstName,
      required this.lastName,
      required this.displayName,
      required this.bio,
      required this.verified,
      required this.theme,
      required this.timestamp,
      required this.locale});

  factory User.fromDocument(DocumentSnapshot doc) {
    final String locale =
        doc.data().toString().contains('locale') ? doc["locale"] : "en";
    return User(
      id: doc['id'],
      username: doc['username'],
      email: doc['email'],
      photoUrl: doc['photoUrl'],
      firstName: doc['firstName'],
      lastName: doc['lastName'],
      displayName: doc['displayName'],
      bio: doc['bio'],
      verified: doc['verified'],
      theme: doc['theme'],
      timestamp: doc['timestamp'],
      locale: locale,
    );
  }
}
