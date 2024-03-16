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
  final int postsCount;
  final String gender;
  final Timestamp? dateOfBirth;

  User({
    required this.id,
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
    required this.locale,
    required this.postsCount,
    required this.gender,
    required this.dateOfBirth,
  });

  factory User.fromDocument(DocumentSnapshot doc) {
    final String locale =
        doc.data().toString().contains('locale') ? doc["locale"] : "en";
    final int postsCount =
        doc.data().toString().contains('postsCount') ? doc["postsCount"] : 0;
    final String gender =
        doc.data().toString().contains('gender') ? doc["gender"] : "";
    final Timestamp? dateOfBirth = doc.data().toString().contains('dateOfBirth')
        ? doc["dateOfBirth"]
        : null;
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
      postsCount: postsCount,
      gender: gender,
      dateOfBirth: dateOfBirth,
    );
  }
}
