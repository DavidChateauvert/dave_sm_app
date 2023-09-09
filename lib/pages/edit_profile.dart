import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sm_app/pages/home.dart';
import 'package:sm_app/widgets/progress.dart';

import '../models/user.dart';

class EditProfile extends StatefulWidget {
  final String currentUserId;

  EditProfile({ required this.currentUserId });

  @override
  _EditProfileState createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  TextEditingController usernameController = TextEditingController();
  TextEditingController displayNameController = TextEditingController();
  TextEditingController bioController = TextEditingController();
  bool isLoading = false;
  late User user;
  bool _usernameValid = true;
  bool _displayNameValid = true;
  bool _bioValid = true;


  @override
  void initState() {
    super.initState();
    getUser();
  }

  getUser() async {
    setState(() {
      isLoading = true;
    });

    DocumentSnapshot doc = await usersRef.doc(widget.currentUserId).get();
    user = User.fromDocument(doc);
    usernameController.text = user.username;
    displayNameController.text = user.displayName;
    bioController.text = user.bio;
    setState(() {
      isLoading = false;
    });
  }

  Column buildUsernameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Padding(
          padding: EdgeInsets.only(top: 12.0),
          child: Text(
            "Username",
            style: TextStyle(color: Colors.grey),
          ),
        ),
        TextField(
          controller: usernameController,
          decoration: InputDecoration(
            hintText: "Update your username",
            errorText: _usernameValid ? null : "Username Too Short"
          ),
        ),
      ],
    );
  }

  Column buildDisplayNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Padding(
          padding: EdgeInsets.only(top: 12.0),
          child: Text(
            "Display Name",
            style: TextStyle(color: Colors.grey),
          ),
        ),
        TextField(
          controller: displayNameController,
          decoration: InputDecoration(
            hintText: "Update your display name",
            errorText: _displayNameValid ? null : "Display Name Too Short"
          ),
        ),
      ],
    );
  }

  Column buildBioField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Padding(
          padding: EdgeInsets.only(top: 12.0),
          child: Text(
            "Bio",
            style: TextStyle(color: Colors.grey),
          ),
        ),
        TextField(
          controller: bioController,
          decoration: InputDecoration(
            hintText: "Update your bio",
            errorText: _bioValid ? null : "Bio is Too Long"
          ),
        ),
      ],
    );
  }

  updateProfileData() {
    setState(() {
      usernameController.text.trim().length < 3 || 
      usernameController.text.isEmpty ? _usernameValid = false : 
      _usernameValid = true;
      displayNameController.text.trim().length < 3 || 
      displayNameController.text.isEmpty ? _displayNameValid = false : 
      _displayNameValid = true;
      bioController.text.trim().length > 100 ? _bioValid = false :
      _bioValid = true;
    });

    if (_usernameValid && _displayNameValid && _bioValid) {
      usersRef.doc(widget.currentUserId).update({
        "username": usernameController.text,
        "usernameLower": usernameController.text.toLowerCase(),
        "displayName": displayNameController.text,
        "displayNameLower": displayNameController.text.toLowerCase(),
        "bio": bioController.text,
      });
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      final snackBar = SnackBar(content: Text('Profile Updated!'));
      scaffoldMessenger.showSnackBar(snackBar);
    }
  }

  logout() async {
    await googleSignIn.signOut();
    Navigator.push(context, MaterialPageRoute(builder: (context) => 
      Home()
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          "Edit Profile",
          style: TextStyle(
            color: Colors.black,
          ),
        ),
        actions: <Widget>[
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.done),
            iconSize: 30.0,
            color: Colors.green,
          ),
        ],
      ),
      body: isLoading ? 
      circularProgress() : 
      ListView(
        children: <Widget>[
          Container(
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
                  child: CircleAvatar(
                    backgroundImage: CachedNetworkImageProvider(user.photoUrl),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    children: <Widget>[
                      buildUsernameField(),
                      buildDisplayNameField(),
                      buildBioField(),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => updateProfileData(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Theme.of(context).primaryColor,
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: const Text(
                    "Update profile",
                    style: TextStyle(
                      color: Color.fromARGB(255, 89, 36, 99),
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextButton.icon(
                    onPressed: () => logout(),
                    icon: const Icon(Icons.cancel, color: Colors.red),
                    label: const Text(
                      "Logout",
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 20.0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}