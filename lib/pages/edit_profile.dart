import 'dart:io';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as Im;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sm_app/pages/home.dart';
import 'package:sm_app/widgets/progress.dart';

import '../models/user.dart';

class EditProfile extends StatefulWidget {
  final String currentUserId;

  EditProfile({required this.currentUserId});

  @override
  _EditProfileState createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  TextEditingController firstNameController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  TextEditingController bioController = TextEditingController();
  bool isLoading = false;
  bool pictureIsLoading = false;
  late User user;
  bool _firstnameValid = true;
  bool _lastNameValid = true;
  bool _bioValid = true;
  File? file;
  String newPhotoUrl = "";

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
    firstNameController.text = user.firstName;
    lastNameController.text = user.lastName;
    bioController.text = user.bio;
    newPhotoUrl = user.photoUrl;
    setState(() {
      isLoading = false;
    });
  }

  buildName() {
    String displayName =
        "${firstNameController.text} ${lastNameController.text}";
    return Text(
      displayName,
      style: TextStyle(
        fontSize: 20.0,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Column buildFirstNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Padding(
          padding: EdgeInsets.only(top: 12.0),
          child: Text(
            "First Name",
            style: TextStyle(color: Colors.grey),
          ),
        ),
        TextField(
          controller: firstNameController,
          decoration: InputDecoration(
              hintText: "Update your fist Name",
              errorText: _firstnameValid ? null : "First Name Too Short"),
        ),
      ],
    );
  }

  Column buildLastNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Padding(
          padding: EdgeInsets.only(top: 12.0),
          child: Text(
            "Last Name",
            style: TextStyle(color: Colors.grey),
          ),
        ),
        TextField(
          controller: lastNameController,
          decoration: InputDecoration(
              hintText: "Update your last name",
              errorText: _lastNameValid ? null : "Last Name Too Short"),
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
              errorText: _bioValid ? null : "Bio is Too Long"),
        ),
      ],
    );
  }

  updateProfileData() {
    setState(() {
      firstNameController.text.trim().length < 1 ||
              firstNameController.text.isEmpty
          ? _firstnameValid = false
          : _firstnameValid = true;
      lastNameController.text.trim().length < 2 ||
              lastNameController.text.isEmpty
          ? _lastNameValid = false
          : _lastNameValid = true;
      bioController.text.trim().length > 100
          ? _bioValid = false
          : _bioValid = true;
    });

    String displayName =
        "${firstNameController.text} ${lastNameController.text}";

    if (_firstnameValid && _lastNameValid && _bioValid) {
      usersRef.doc(widget.currentUserId).update({
        "firstName": firstNameController.text,
        "lastName": lastNameController.text,
        "displayName": displayName,
        "displayNameLower": displayName.toLowerCase(),
        "bio": bioController.text,
        "photoUrl": newPhotoUrl,
      });
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      final snackBar = SnackBar(content: Text('Profile Updated!'));
      scaffoldMessenger.showSnackBar(snackBar);

      Future.delayed(Duration(seconds: 1), () {
        Navigator.pop(context);
      });
    }
  }

  logout() async {
    await googleSignIn.signOut();
    Navigator.pop(context);
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation1, animation2) => Home(),
        transitionDuration: Duration(seconds: 0),
      ),
    );
    // Navigator.push(context, MaterialPageRoute(builder: (context) => Home()));
  }

  handleTakePhoto() async {
    final ImagePicker _imagePicker = ImagePicker();
    XFile? xfile = (await _imagePicker.pickImage(
      source: ImageSource.camera,
      maxHeight: 960.0,
      maxWidth: 675.0,
    ));
    handlePictureUpload(File(xfile!.path));
  }

  handleChooseFromGallery() async {
    ImagePicker _imagePicker = ImagePicker();
    XFile? xfile = (await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxHeight: 675.0,
      maxWidth: 960,
    ));
    handlePictureUpload(File(xfile!.path));
  }

  handlePictureUpload(file) async {
    setState(() {
      pictureIsLoading = true;
    });
    await compressImage(file);
    String mediaUrl = await uploadImage(file);
    setState(() {
      newPhotoUrl = mediaUrl;
      pictureIsLoading = false;
    });
  }

  compressImage(File file) async {
    final tempDir = await getTemporaryDirectory();
    final path = tempDir.path;
    Im.Image? imageFile = Im.decodeImage(file.readAsBytesSync());
    final compressedImageFile = File('$path/img_${user.id}.jpg')
      ..writeAsBytesSync(Im.encodeJpg(imageFile!, quality: 85));
    setState(() {
      file = compressedImageFile;
    });
  }

  Future<String> uploadImage(imageFile) async {
    UploadTask uploadTask = storageRef
        .child("profilePictures/${user.id}_${user.displayName}.jpg")
        .putFile(imageFile);
    TaskSnapshot storageSnap = await uploadTask;
    String downloadUrl = await storageSnap.ref.getDownloadURL();
    return downloadUrl;
  }

  selectImage(parentContext) {
    return showDialog(
      context: parentContext,
      builder: (context) {
        return SimpleDialog(
          title: Text(
            "Add an image to the post",
            style: TextStyle(
              color: Theme.of(context).colorScheme.onBackground,
            ),
          ),
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Flexible(
                  child: TextButton(
                    onPressed: () {
                      handleTakePhoto();
                      Navigator.pop(context, "takePhoto");
                    },
                    child: Container(
                      height: 100.0,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(
                              CupertinoIcons.photo_camera,
                              color: Theme.of(context).colorScheme.onBackground,
                              size: 28.0,
                            ),
                            const SizedBox(
                              height: 8,
                            ),
                            Text(
                              "Photo with camera",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color:
                                    Theme.of(context).colorScheme.onBackground,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  height: 100.0,
                  width: 2.0,
                  color: Theme.of(context).colorScheme.onBackground,
                ),
                Flexible(
                  child: TextButton(
                    onPressed: () {
                      handleChooseFromGallery();
                      Navigator.pop(context, "chooseFromGallery");
                    },
                    child: Container(
                      height: 100.0,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            CupertinoIcons.photo_on_rectangle,
                            color: Theme.of(context).colorScheme.onBackground,
                            size: 28.0,
                          ),
                          const SizedBox(
                            height: 8,
                          ),
                          Text(
                            "Image from gallery",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onBackground,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // SimpleDialogOption(
            //   child: Text("Cancel"),
            //   onPressed: () => Navigator.pop(context),
            // ),
          ],
        );
      },
    );
  }

  handleChangePicture() async {
    await selectImage(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: const Text(
          "Edit Profile",
          style: const TextStyle(color: Colors.white, fontSize: 30.0),
        ),
        actions: <Widget>[
          IconButton(
            onPressed: () => updateProfileData(),
            icon: Icon(Icons.done),
            iconSize: 30.0,
            color: Colors.green,
          ),
        ],
      ),
      body: isLoading
          ? circularProgress()
          : ListView(
              children: <Widget>[
                Container(
                  child: Column(
                    children: <Widget>[
                      const SizedBox(height: 16.0),
                      Container(
                        height: 80,
                        child: pictureIsLoading
                            ? circularProgress()
                            : CircleAvatar(
                                radius: 40.0,
                                backgroundColor: Colors.grey,
                                backgroundImage: newPhotoUrl.isNotEmpty
                                    ? CachedNetworkImageProvider(newPhotoUrl)
                                    : user.photoUrl.isNotEmpty
                                        ? CachedNetworkImageProvider(
                                            user.photoUrl)
                                        : null,
                              ),
                      ),
                      const SizedBox(height: 8.0),
                      ElevatedButton(
                        onPressed: () => handleChangePicture(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor:
                              Theme.of(context).colorScheme.primary,
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        child: Text(
                          "Change Profile Picture",
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 16.0,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          children: <Widget>[
                            buildName(),
                            buildFirstNameField(),
                            buildLastNameField(),
                            buildBioField(),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
