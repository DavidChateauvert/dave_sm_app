import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as Im;
import 'package:image_picker/image_picker.dart';
import 'package:image_size_getter/file_input.dart';
import 'package:image_size_getter/image_size_getter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sm_app/pages/groups.dart';
import 'package:sm_app/pages/home.dart';
import 'package:sm_app/pages/report_delete_user.dart';
import 'package:sm_app/widgets/checkInternetConnection.dart';
import 'package:sm_app/widgets/errorMessage.dart';
import 'package:sm_app/widgets/profileHeader.dart';
import 'package:sm_app/widgets/progress.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:status_alert/status_alert.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import '../models/user.dart';

class EditProfile extends StatefulWidget {
  final String currentUserId;

  EditProfile({required this.currentUserId});

  @override
  _EditProfileState createState() => _EditProfileState();
}

List<String> genderOptions = ["women", "men", "", "specify"];

class _EditProfileState extends State<EditProfile> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  TextEditingController firstNameController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  TextEditingController bioController = TextEditingController();
  TextEditingController genderController = TextEditingController();
  FocusNode firstNameFocusNode = FocusNode();
  FocusNode lastNameFocusNode = FocusNode();
  FocusNode bioFocusNode = FocusNode();
  FocusNode genderFocusNode = FocusNode();
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
  final Uri url = Uri.parse('https://appdave.com/#/contact-us');
  bool hasChangeProfilPicture = false;
  Size newSize = Size(9, 12);

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
    if (!["women", "men", "other", ""].contains(currentGenderOptions)) {
      currentGenderOptions = "specify";
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

  buildEmail() {
    return Text(
      currentUser.email,
      style: TextStyle(
        fontSize: 14.0,
        fontWeight: FontWeight.normal,
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
          focusNode: firstNameFocusNode,
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
          focusNode: lastNameFocusNode,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(top: 12.0),
          child: Text(
            AppLocalizations.of(context)!.gender,
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
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primaryContainer,
                    ),
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
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primaryContainer,
                    ),
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
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primaryContainer,
                    ),
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
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primaryContainer,
                    ),
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
                focusNode: genderFocusNode,
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
          focusNode: bioFocusNode,
          maxLines: null,
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.update_bio,
            errorText:
                _bioValid ? null : AppLocalizations.of(context)!.bio_too_long,
          ),
        ),
      ],
    );
  }

  Column buildDateOfBirthField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          AppLocalizations.of(context)!.date_of_birth,
          style: TextStyle(
            color: Colors.grey,
            fontSize: 20.0,
          ),
        ),
        Row(
          children: [
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
            Flexible(
              child: CupertinoButton(
                child: Text(
                  newDateOfBirth == null
                      ? AppLocalizations.of(context)!.pick_date_of_birth
                      : AppLocalizations.of(context)!.change_date_of_birth,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    fontSize: 14.0,
                  ),
                  textAlign: TextAlign.center,
                ),
                onPressed: () {
                  showCupertinoModalPopup(
                    context: context,
                    builder: (BuildContext context) => Container(
                      color: Theme.of(context).colorScheme.background,
                      height: 250,
                      child: CupertinoDatePicker(
                        initialDateTime: newDateOfBirth == null
                            ? DateTime.now()
                            : newDateOfBirth,
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
            ),
          ],
        ),
      ],
    );
  }

  updateProfileData() async {
    unfocusAllNodes();
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
      try {
        if (!await checkInternetConnection()) {
          throw Exception(AppLocalizations.of(context)!.error_no_connection);
        }
        usersRef.doc(widget.currentUserId).update({
          "firstName": firstNameController.text,
          "lastName": lastNameController.text,
          "displayName": displayName,
          "displayNameLower": displayName.toLowerCase(),
          "bio": bioController.text,
          "photoUrl": newPhotoUrl,
          "dateOfBirth": newDateOfBirth != null
              ? Timestamp.fromDate(newDateOfBirth!)
              : null,
          "gender": currentGenderOptions == "specify"
              ? genderController.text
              : currentGenderOptions,
        });
        if (hasChangeProfilPicture == true) {
          createPostInFirestore(newPhotoUrl, newSize);
        }
        StatusAlert.show(
          context,
          duration: Duration(seconds: 2),
          subtitle: AppLocalizations.of(context)!.profile_updated,
          configuration: IconConfiguration(icon: Icons.done),
          maxWidth: 260,
          backgroundColor: Theme.of(context).colorScheme.secondary,
        );
        Future.delayed(Duration(seconds: 1), () {
          Navigator.pop(context, user);
        });
      } catch (e) {
        showErrorMessage(context, e);
      }
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

  handlePictureUpload(File file) async {
    setState(() {
      pictureIsLoading = true;
    });
    await compressImage(file);
    String mediaUrl = await uploadImage(file);
    final fileImage = FileImage(file);
    newSize = ImageSizeGetter.getSize(FileInput(fileImage.file));
    setState(() {
      newPhotoUrl = mediaUrl;
      pictureIsLoading = false;
      hasChangeProfilPicture = true;
    });
  }

  createPostInFirestore(String mediaUrl, Size size) {
    String postId = Uuid().v4();
    String currentUserId = currentUser.id;
    postsRef.doc(currentUserId).collection("userPosts").doc(postId).set({
      "postId": postId,
      "ownerId": currentUserId,
      "username": currentUser.displayName,
      "mediaUrl": mediaUrl,
      "mediaUrlWidth": size.width,
      "mediaUrlHeight": size.height,
      "caption": AppLocalizations.of(context)!
          .profile_post_caption(currentUser.firstName),
      "timestamp": DateTime.now(),
      "likes": {},
      "comments": {},
      "commentCount": 0,
      "mentions": {},
      "type": "photo",
      "group": "",
      "autoType": "newProfilePicture"
    });

    usersRef.doc(currentUser.id).update({
      "postsCount": FieldValue.increment(1),
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

  Future<String> uploadImage(File imageFile) async {
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

  showDeleteReason(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (context) {
      return ReportDeleteUser(
        userId: currentUser.id,
      );
    }));
  }

  buildMyGroups() {
    return Padding(
      padding: EdgeInsets.only(
        top: 32.0,
      ),
      child: Center(
        child: IntrinsicWidth(
          child: TextButton(
            onPressed: () => showGroupsPage(),
            child: Row(
              children: [
                Text(
                  AppLocalizations.of(context)!.my_groups,
                  style: TextStyle(
                    fontSize: 20.0,
                    color: Theme.of(context).colorScheme.primaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 4.0),
                Icon(
                  CupertinoIcons.group_solid,
                  color: Theme.of(context).colorScheme.primaryContainer,
                  size: 40.0,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  showGroupsPage() async {
    await Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: Duration(milliseconds: 500),
        pageBuilder: (context, animation, secondaryAnimation) => Groups(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          var begin = Offset(0.0, 1.0);
          var end = Offset.zero;
          var curve = Curves.ease;

          var tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
  }

  buildNeedModify() {
    return Padding(
      padding: EdgeInsets.only(
        top: 32.0,
      ),
      child: Column(
        children: [
          Text(
            AppLocalizations.of(context)!.need_modify_user,
            textAlign: TextAlign.center,
          ),
          const SizedBox(
            height: 4.0,
          ),
          GestureDetector(
            onTap: () => launchUrl(url),
            child: Text(
              "https://appdave.com/#/contact-us",
              style: TextStyle(
                color: Theme.of(context).colorScheme.primaryContainer,
                decoration: TextDecoration.underline,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  handleDeleteUser(BuildContext parentContext) {
    return showDialog(
      context: parentContext,
      builder: (context) {
        return SimpleDialog(
          title: Text(
            AppLocalizations.of(context)!.are_you_sure_delete_user,
            textAlign: TextAlign.center,
          ),
          children: <Widget>[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                AppLocalizations.of(context)!.are_you_sure_delete_user_2,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(
              height: 8.0,
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context);
                showDeleteReason(context);
              },
              child: Text(
                AppLocalizations.of(context)!.delete_user,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red),
              ),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                AppLocalizations.of(context)!.cancel,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        );
      },
    );
  }

  buildDeleteUser() {
    return Padding(
      padding: const EdgeInsets.only(top: 32.0),
      child: IntrinsicWidth(
        child: TextButton(
          onPressed: () => handleDeleteUser(context),
          child: Row(
            children: [
              const Icon(
                CupertinoIcons.delete,
                color: Colors.red,
                size: 24.0,
              ),
              const SizedBox(
                width: 4.0,
              ),
              Text(
                AppLocalizations.of(context)!.delete_user,
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 16.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool checkIfNothingChanges() {
    final conditions = [
      firstNameController.text != user.firstName,
      lastNameController.text != user.lastName,
      bioController.text != user.bio,
      newPhotoUrl != user.photoUrl,
      currentGenderOptions != user.gender,
      newDateOfBirth != user.dateOfBirth?.toDate(),
    ];

    for (var condition in conditions) {
      if (condition) {
        return false;
      }
    }

    return true;
  }

  handleQuitWithoutSaving() async {
    if (checkIfNothingChanges()) {
      unfocusAllNodes();
      Navigator.pop(context);
    } else {
      bool? sureChange = await showModalSureChanges(context);
      if (sureChange != null) {
        unfocusAllNodes();
        if (sureChange == true) {
          Navigator.pop(context);
        } else {
          updateProfileData();
        }
      }
    }
  }

  Future<bool?> showModalSureChanges(BuildContext parentContext) {
    return showDialog<bool>(
      context: parentContext,
      builder: (context) {
        return SimpleDialog(
          title: Text(
            AppLocalizations.of(context)!.post_parameters,
            textAlign: TextAlign.center,
          ),
          children: <Widget>[
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: Text(
                AppLocalizations.of(context)!.quit_without_saving,
                textAlign: TextAlign.center,
              ),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: Text(
                AppLocalizations.of(context)!.save_changes,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.green),
              ),
            ),
          ],
        );
      },
    );
  }

  unfocusAllNodes() {
    firstNameFocusNode.unfocus();
    lastNameFocusNode.unfocus();
    bioFocusNode.unfocus();
    genderFocusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        leading: IconButton(
          icon: Icon(
            Icons.clear,
            color: Colors.white,
            size: 32.0,
          ),
          onPressed: () => handleQuitWithoutSaving(),
        ),
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
          ? circularProgress(context)
          : ListView(
              children: <Widget>[
                Container(
                  child: Column(
                    children: <Widget>[
                      const SizedBox(height: 16.0),
                      Container(
                        height: 80,
                        child: pictureIsLoading
                            ? circularProgress(context)
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
                      CupertinoButton(
                        onPressed: () => handleChangePicture(),
                        child: Text(
                          AppLocalizations.of(context)!.change_profile_picture,
                          style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.primaryContainer,
                            fontSize: 16.0,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          children: <Widget>[
                            buildName(),
                            buildEmail(),
                            buildFirstNameField(),
                            buildLastNameField(),
                            const SizedBox(
                              height: 12.0,
                            ),
                            buildDateOfBirthField(),
                            buildGenderField(),
                            buildBioField(),
                            buildMyGroups(),
                            buildNeedModify(),
                            buildDeleteUser(),
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
