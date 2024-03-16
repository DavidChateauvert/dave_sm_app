// ignore_for_file: prefer_const_constructors

import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:sm_app/models/user.dart';
import 'package:sm_app/pages/home.dart';
import 'package:sm_app/providers/locale_provider.dart';
import 'package:sm_app/providers/theme_provider.dart';
import 'package:sm_app/widgets/header.dart';
import 'package:image/image.dart' as Im;
import 'package:sm_app/widgets/progress.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class CreateAccount extends StatefulWidget {
  final String userId;

  CreateAccount({required this.userId});

  @override
  _CreateAccountState createState() => _CreateAccountState();
}

class _CreateAccountState extends State<CreateAccount> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();
  bool pictureIsLoading = false;
  late String firstName;
  late String lastName;
  late String username;
  String sexe = "";
  Timestamp? dateOfBirth = null;
  String photoUrl = "";
  late String bio;

  submit() {
    final form = _formKey.currentState;

    if (form!.validate()) {
      form.save();

      User user = User(
        id: widget.userId,
        username: "",
        email: "",
        photoUrl: photoUrl,
        firstName: firstName,
        lastName: lastName,
        displayName: "${firstName} ${lastName}",
        bio: bio,
        verified: false,
        timestamp: Timestamp.now(),
        theme: Provider.of<ThemeProvider>(context, listen: false)
            .getThemeDataFormatString(),
        locale: Provider.of<LocaleProvider>(context, listen: false)
            .getLocaleFormatString(),
        postsCount: 0,
        gender: "",
        dateOfBirth: dateOfBirth,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context)!
                .welcomeMessage(user.displayName))),
      );
      Timer(Duration(seconds: 1), () {
        Navigator.pop(context, user);
      });
    }
  }

  buildFormFirstName() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 12.0),
          child: Text(
            AppLocalizations.of(context)!.first_name,
            style: TextStyle(color: Colors.grey),
          ),
        ),
        TextFormField(
          validator: (val) {
            if (val!.trim().length < 1 || val.isEmpty) {
              return AppLocalizations.of(context)!.first_name_too_short;
            } else if (val.trim().length > 20) {
              return AppLocalizations.of(context)!.first_name_too_long;
            } else {
              return null;
            }
          },
          onSaved: (val) => firstName = val!,
          decoration: InputDecoration(
            labelStyle: TextStyle(fontSize: 15.0),
            hintText: AppLocalizations.of(context)!.at_least_one_caracter,
          ),
        ),
      ],
    );
  }

  buildFormLastName() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 12.0),
          child: Text(
            AppLocalizations.of(context)!.last_name,
            style: TextStyle(color: Colors.grey),
          ),
        ),
        TextFormField(
          validator: (val) {
            if (val!.trim().length < 1 || val.isEmpty) {
              return AppLocalizations.of(context)!.last_name_too_short;
            } else if (val.trim().length > 20) {
              return AppLocalizations.of(context)!.last_name_too_long;
            } else {
              return null;
            }
          },
          onSaved: (val) => lastName = val!,
          decoration: InputDecoration(
            labelStyle: TextStyle(fontSize: 15.0),
            hintText: AppLocalizations.of(context)!.at_least_one_caracter,
          ),
        ),
      ],
    );
  }

  buildFormBio() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 12.0),
          child: Text(
            AppLocalizations.of(context)!.bio,
            style: TextStyle(color: Colors.grey),
          ),
        ),
        TextFormField(
          validator: (val) {
            if (val!.trim().length > 100) {
              return "Bio is too long, it must be below 100 caracters";
            } else {
              return null;
            }
          },
          onSaved: (val) => bio = val!,
          decoration: InputDecoration(
            labelStyle: TextStyle(fontSize: 15.0),
          ),
        ),
      ],
    );
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
      photoUrl = mediaUrl;
      pictureIsLoading = false;
    });
  }

  compressImage(File file) async {
    final tempDir = await getTemporaryDirectory();
    final path = tempDir.path;
    Im.Image? imageFile = Im.decodeImage(file.readAsBytesSync());
    final compressedImageFile = File('$path/img_${widget.userId}}.jpg')
      ..writeAsBytesSync(Im.encodeJpg(imageFile!, quality: 85));
    setState(() {
      file = compressedImageFile;
    });
  }

  Future<String> uploadImage(imageFile) async {
    UploadTask uploadTask = storageRef
        .child("profilePictures/${widget.userId}.jpg")
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
            AppLocalizations.of(context)!.add_image_profile,
            textAlign: TextAlign.center,
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
                              AppLocalizations.of(context)!.photo_with_camera,
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
                            AppLocalizations.of(context)!.image_from_gallery,
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
          ],
        );
      },
    );
  }

  handleChangePicture() async {
    await selectImage(context);
  }

  buildProfilePicture() {
    return Column(
      children: [
        const SizedBox(height: 24.0),
        ElevatedButton(
          onPressed: () => handleChangePicture(),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Theme.of(context).colorScheme.primary,
            textStyle: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          child: Text(
            AppLocalizations.of(context)!.add_image_profile,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 16.0,
              fontWeight: FontWeight.normal,
            ),
          ),
        ),
        const SizedBox(height: 8.0),
        Container(
          height: 80,
          child: pictureIsLoading
              ? circularProgress()
              : photoUrl == ""
                  ? Icon(
                      CupertinoIcons.person_circle,
                      size: 80,
                      color: Theme.of(context).colorScheme.primary,
                    )
                  : CircleAvatar(
                      radius: 40.0,
                      backgroundColor: Colors.grey,
                      backgroundImage: photoUrl.isNotEmpty
                          ? CachedNetworkImageProvider(photoUrl)
                          : null,
                    ),
        ),
        const SizedBox(height: 8.0),
      ],
    );
  }

  @override
  Widget build(context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: header(context,
          titleText: AppLocalizations.of(context)!.set_up_profile,
          removeBackButton: true,
          showMessageButton: false),
      body: ListView(children: <Widget>[
        Container(
          child: Column(
            children: <Widget>[
              Padding(
                padding: EdgeInsets.only(top: 25.0),
                child: Center(
                  child: Text(
                    AppLocalizations.of(context)!.enter_info,
                    style: TextStyle(fontSize: 25.0),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Container(
                  child: Form(
                    key: _formKey,
                    autovalidateMode: AutovalidateMode.always,
                    child: Column(
                      children: [
                        buildFormFirstName(),
                        buildFormLastName(),
                        buildFormBio(),
                        buildProfilePicture(),
                      ],
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: submit,
                child: Container(
                  height: 50.0,
                  width: 350.0,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(7.0),
                  ),
                  child: Center(
                    child: Text(
                      AppLocalizations.of(context)!.finish_configuration,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        )
      ]),
    );
  }
}
