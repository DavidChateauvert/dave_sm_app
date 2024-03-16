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
import 'package:sm_app/widgets/profileHeader.dart';
import 'package:sm_app/widgets/progress.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../models/user.dart';

class EditProfile extends StatefulWidget {
  final String currentUserId;

  EditProfile({required this.currentUserId});

  @override
  _EditProfileState createState() => _EditProfileState();
}

List<String> genderOptions = ["women", "men", "other", "specify"];

class _EditProfileState extends State<EditProfile> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  TextEditingController firstNameController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  TextEditingController bioController = TextEditingController();
  TextEditingController genderController = TextEditingController();
  bool isLoading = false;
  bool pictureIsLoading = false;
  late User user;
  bool _firstnameValid = true;
  bool _lastNameValid = true;
  bool _bioValid = true;
  File? file;
  String newPhotoUrl = "";
  String currentGenderOptions = "";
  DateTime? newDateOfBirth;

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
    currentGenderOptions = user.gender;
    print("allo");
    print(currentGenderOptions);
    if (!['women', 'men', 'other'].contains(currentGenderOptions)) {
      genderController.text = user.gender;
    }
    newDateOfBirth = user.dateOfBirth?.toDate();

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
        Padding(
          padding: EdgeInsets.only(top: 12.0),
          child: Text(
            AppLocalizations.of(context)!.first_name,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 20.0,
            ),
          ),
        ),
        TextField(
          controller: firstNameController,
          decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.update_first_name,
              errorText: _firstnameValid
                  ? null
                  : AppLocalizations.of(context)!.first_name_too_short),
        ),
      ],
    );
  }

  Column buildLastNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(top: 12.0),
          child: Text(
            AppLocalizations.of(context)!.last_name,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 20.0,
            ),
          ),
        ),
        TextField(
          controller: lastNameController,
          decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.update_last_name,
              errorText: _lastNameValid
                  ? null
                  : AppLocalizations.of(context)!.last_name_too_short),
        ),
      ],
    );
  }

  Column buildGenderField() {
    print(currentGenderOptions);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(top: 12.0),
          child: Text(
            AppLocalizations.of(context)!.bio,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 20.0,
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: () {
                setState(() {
                  currentGenderOptions = genderOptions[0].toString();
                });
              },
              child: Row(
                children: [
                  Text(
                    AppLocalizations.of(context)!.women_gender,
                  ),
                  Radio(
                    value: genderOptions[0],
                    groupValue: currentGenderOptions,
                    onChanged: (value) {
                      setState(() {
                        currentGenderOptions = value.toString();
                      });
                    },
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  currentGenderOptions = genderOptions[1].toString();
                });
              },
              child: Row(
                children: [
                  Text(
                    AppLocalizations.of(context)!.men_gender,
                  ),
                  Radio(
                    value: genderOptions[1],
                    groupValue: currentGenderOptions,
                    onChanged: (value) {
                      setState(() {
                        currentGenderOptions = value.toString();
                      });
                    },
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  currentGenderOptions = genderOptions[2].toString();
                });
              },
              child: Row(
                children: [
                  Text(
                    AppLocalizations.of(context)!.other,
                  ),
                  Radio(
                    value: genderOptions[2],
                    groupValue: currentGenderOptions,
                    onChanged: (value) {
                      setState(() {
                        currentGenderOptions = value.toString();
                      });
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        Row(
          children: [
            TextButton(
              onPressed: () {
                setState(() {
                  currentGenderOptions = genderOptions[3].toString();
                });
              },
              child: Row(
                children: [
                  Text(
                    AppLocalizations.of(context)!.specified_gender,
                  ),
                  Radio(
                    value: genderOptions[3],
                    groupValue: currentGenderOptions,
                    onChanged: (value) {
                      setState(() {
                        currentGenderOptions = value.toString();
                      });
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: TextField(
                controller: genderController,
                decoration: InputDecoration(
                  hintText:
                      AppLocalizations.of(context)!.specified_gender_controller,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Column buildBioField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(top: 12.0),
          child: Text(
            AppLocalizations.of(context)!.bio,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 20.0,
            ),
          ),
        ),
        TextField(
          controller: bioController,
          decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.update_bio,
              errorText: _bioValid
                  ? null
                  : AppLocalizations.of(context)!.bio_too_long),
        ),
      ],
    );
  }

  Row buildDateOfBirthField() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Text(
                AppLocalizations.of(context)!.date_of_birth,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 20.0,
                ),
              ),
            ),
            newDateOfBirth == null
                ? Text(AppLocalizations.of(context)!.no_date_of_birth)
                : Text(
                    formatTimestamp(
                      context,
                      Timestamp.fromDate(newDateOfBirth!),
                    ),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onBackground,
                      fontSize: 16.0,
                    ),
                  ),
          ],
        ),
        CupertinoButton(
          child: Text(
            newDateOfBirth == null
                ? AppLocalizations.of(context)!.pick_date_of_birth
                : AppLocalizations.of(context)!.change_date_of_birth,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primaryContainer,
              fontSize: 14.0,
            ),
          ),
          onPressed: () {
            showCupertinoModalPopup(
              context: context,
              builder: (BuildContext context) => Container(
                color: Theme.of(context).colorScheme.background,
                height: 250,
                child: CupertinoDatePicker(
                  initialDateTime:
                      newDateOfBirth == null ? DateTime.now() : newDateOfBirth,
                  maximumDate: DateTime.now(),
                  mode: CupertinoDatePickerMode.date,
                  onDateTimeChanged: (DateTime newTime) {
                    setState(
                      () {
                        newDateOfBirth = newTime;
                      },
                    );
                  },
                ),
              ),
            );
          },
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
      bioController.text.trim().length > 150
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
        "dateOfBirth": Timestamp.fromDate(newDateOfBirth!),
        "sexe": currentGenderOptions == "specify"
            ? genderController.text
            : currentGenderOptions,
      });
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      final snackBar = SnackBar(
          content: Text(AppLocalizations.of(context)!.profile_updated));
      scaffoldMessenger.showSnackBar(snackBar);

      Future.delayed(Duration(seconds: 1), () {
        Navigator.pop(context, user);
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
            AppLocalizations.of(context)!.change_profile_picture,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: Text(
          AppLocalizations.of(context)!.edit_profile,
          style: const TextStyle(color: Colors.white, fontSize: 20.0),
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
                          AppLocalizations.of(context)!.change_profile_picture,
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
                            buildDateOfBirthField(),
                            buildGenderField(),
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
