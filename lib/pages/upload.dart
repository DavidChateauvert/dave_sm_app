// ignore_for_file: prefer_const_constructors
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_size_getter/image_size_getter.dart';
import 'package:image_size_getter/file_input.dart';
// import 'package:textfield_tags/textfield_tags.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sm_app/api/firebase_api.dart';
import 'package:sm_app/pages/home.dart';
import 'package:sm_app/widgets/progress.dart';
import 'package:uuid/uuid.dart';
import 'package:sm_app/models/user.dart';
import 'package:flutter_mentions/flutter_mentions.dart';
import 'package:image/image.dart' as Im;

class Upload extends StatefulWidget {
  final User? currentUser;

  Upload({this.currentUser});

  @override
  _UploadState createState() => _UploadState();
}

class _UploadState extends State<Upload>
    with AutomaticKeepAliveClientMixin<Upload> {
  File? file;
  bool isUploading = false;
  String postId = Uuid().v4();
  GlobalKey<FlutterMentionsState> _mentionsKey =
      GlobalKey<FlutterMentionsState>();
  Size size = Size(9, 12);
  FocusNode captionFocusNode = FocusNode();
  List<Map<String, String>> mentionsDataInit = [];
  List<Map<String, String>> mentionsData = [];
  List<Map<String, String>> mentionsDataAdded = [];
  late String otherUserToken;

  @override
  void initState() {
    super.initState();
    getFriends();
  }

  getFriends() async {
    QuerySnapshot followingSnapshot =
        await friendsRef.doc(currentUser.id).collection('userFriends').get();

    List<String> userIds = [];

    followingSnapshot.docs.forEach((doc) {
      userIds.add(doc.id);
    });

    QuerySnapshot userSnapshot = await usersRef.get();

    List<Map<String, String>> newData = [];

    userSnapshot.docs.forEach((doc) {
      if (userIds.contains(doc['id'])) {
        newData.add({
          'id': doc['id'],
          'display': doc['displayName'],
        });
      }
    });

    setState(() {
      mentionsDataInit = newData;
    });
  }

  handleTakePhotoFunctions() async {
    await handleTakePhoto();
    await compressImage();
  }

  handleTakePhoto() async {
    Navigator.pop(context);
    final ImagePicker _imagePicker = ImagePicker();
    XFile? xfile = (await _imagePicker.pickImage(
      source: ImageSource.camera,
      maxHeight: 960.0,
      maxWidth: 675.0,
    ));
    setState(() {
      file = File(xfile!.path);
    });
  }

  handleChooseFromGalleryFunctions() async {
    await handleChooseFromGallery();
    await compressImage();
  }

  handleChooseFromGallery() async {
    Navigator.pop(context);
    ImagePicker _imagePicker = ImagePicker();
    XFile? xfile = (await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxHeight: 675.0,
      maxWidth: 960,
    ));
    setState(() {
      file = File(xfile!.path);
    });
  }

  compressImage() async {
    final tempDir = await getTemporaryDirectory();
    final path = tempDir.path;
    Im.Image? imageFile = Im.decodeImage(file!.readAsBytesSync());
    final compressedImageFile = File('$path/img_$postId.jpg')
      ..writeAsBytesSync(Im.encodeJpg(imageFile!, quality: 85));
    setState(() {
      file = compressedImageFile;
    });
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
                    onPressed: () => handleTakePhotoFunctions(),
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
                    onPressed: () => handleChooseFromGalleryFunctions(),
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
          ],
        );
      },
    );
  }

  clearImage() {
    setState(() {
      file = null;
    });
  }

  createPostInFirestore({required String caption, required String mediaUrl}) {
    Map<String, String> mentionsMap =
        mentionsDataAdded.fold({}, (map, mention) {
      map[mention['id']!] = mention['display']!;
      return map;
    });

    postsRef
        .doc(widget.currentUser?.id)
        .collection("userPosts")
        .doc(postId)
        .set({
      "postId": postId,
      "ownerId": widget.currentUser?.id,
      "username": widget.currentUser?.displayName,
      "mediaUrl": mediaUrl,
      "mediaUrlWidth": size.width,
      "mediaUrlHeight": size.height,
      "caption": caption,
      "timestamp": DateTime.now(),
      "likes": {},
      "comments": {},
      "commentCount": 0,
      "mentions": mentionsMap,
    });

    for (var mention in mentionsMap.entries) {
      activityFeedRef.doc(mention.key).collection("feedItems").add({
        "type": "mention",
        "username": currentUser.displayName,
        "userId": currentUser.id,
        "userProfileImg": currentUser.photoUrl,
        "postId": postId,
        "seen": false,
        // "mediaUrl": mediaUrl,
        "timestamp": DateTime.now(),
      });
      FirebaseApi().sendMentionsNotification(
          mention.key, currentUser.displayName, postId);
    }
  }

  Future<String> uploadImage(imageFile) async {
    UploadTask uploadTask =
        storageRef.child("post_$postId.jpg").putFile(imageFile);
    TaskSnapshot storageSnap = await uploadTask;
    String downloadUrl = await storageSnap.ref.getDownloadURL();
    return downloadUrl;
  }

  handleSubmit() async {
    captionFocusNode.unfocus();
    if ((_mentionsKey.currentState!.controller!.text.trim().isEmpty ||
            _mentionsKey.currentState!.controller!.text.trim() == "") &&
        file == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Post Cannot Be Empty")));
    } else if (_mentionsKey.currentState!.controller!.text.length > 400) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Post Is Too Long")));
    } else {
      setState(() {
        isUploading = true;
      });
      if (file == null) {
        createPostInFirestore(
            caption: _mentionsKey.currentState!.controller!.text, mediaUrl: '');
      } else {
        // await compressImage();
        String mediaUrl = await uploadImage(file);
        createPostInFirestore(
            caption: _mentionsKey.currentState!.controller!.text,
            mediaUrl: mediaUrl);
      }

      setState(() {
        file = null;
        isUploading = false;
        postId = Uuid().v4();
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Post Successfully Created")));
      _mentionsKey.currentState!.controller!.clear();
      mentionsDataAdded.clear();
    }
  }

  handleRatio() {
    if ((size.width / size.height) < (9 / 12)) {
      return 9 / 12;
    }
    return size.width / size.height;
  }

  Future<void> handleSearch(String query) async {
    String lowercasedQuery = query.toLowerCase();

    List<Map<String, String>> filteredData = mentionsDataInit
        .where(
            (user) => user['display']!.toLowerCase().contains(lowercasedQuery))
        .toList();

    setState(() {
      mentionsData = filteredData;
    });
  }

  buildUploadForm() {
    if (file != null) {
      final fileImage = FileImage(file!);
      size = ImageSizeGetter.getSize(FileInput(fileImage.file));
    }
    return GestureDetector(
      onTap: () => captionFocusNode.unfocus(),
      child: Portal(
        child: Scaffold(
          backgroundColor: Theme.of(context).colorScheme.background,
          appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.primary,
            leading: IconButton(
              icon: Icon(
                Icons.add_a_photo_outlined,
                color: Colors.white,
                size: 30.0,
              ),
              onPressed: () => selectImage(context),
            ),
            title: Text(
              "Caption Post",
              style: TextStyle(color: Colors.white, fontSize: 30.0),
            ),
            centerTitle: true,
            actions: [
              TextButton(
                onPressed: isUploading ? null : () => handleSubmit(),
                child: Text(
                  "Post",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 22.0,
                  ),
                ),
              ),
            ],
          ),
          body: ListView(
            children: <Widget>[
              isUploading ? linearProgress() : Text(""),
              Padding(
                padding: EdgeInsets.only(top: 10.0),
              ),
              ListTile(
                leading: CircleAvatar(
                  backgroundImage:
                      CachedNetworkImageProvider(widget.currentUser!.photoUrl),
                ),
                title: Container(
                  width: 250.0,
                  child: FlutterMentions(
                    focusNode: captionFocusNode,
                    key: _mentionsKey,
                    style: TextStyle(
                      overflow: TextOverflow.visible,
                      color: Theme.of(context).colorScheme.onBackground,
                      fontWeight: FontWeight.w600,
                      fontSize: 20.0,
                    ),
                    decoration: InputDecoration(
                      hintText: "Write a post...",
                      hintStyle: TextStyle(
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        fontWeight: FontWeight.w600,
                        fontSize: 20.0,
                      ),
                      border: InputBorder.none,
                    ),
                    suggestionListHeight: 206,
                    suggestionListDecoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    cursorColor: Theme.of(context).colorScheme.onBackground,
                    mentions: [
                      Mention(
                        trigger: '@',
                        disableMarkup: true,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        data: mentionsData,
                        matchAll: false,
                        suggestionBuilder: (data) {
                          return Padding(
                            padding: EdgeInsets.only(left: 20.0),
                            child: Column(
                              children: [
                                Container(
                                  height: 50.0,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    data['display']!,
                                    style: TextStyle(
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                                Divider(
                                  height: 2.0,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                    onSearchChanged: (String trigger, String query) async {
                      await handleSearch(query);
                    },
                    onMentionAdd: (data) {
                      mentionsDataAdded.add(
                          {'id': data['id']!, 'display': data['display']!});
                    },
                  ),
                ),
              ),
              (file != null)
                  ? Column(
                      children: <Widget>[
                        Padding(
                          padding: EdgeInsets.only(top: 30.0),
                          child: Container(
                            // height: 500.0,
                            width: MediaQuery.of(context).size.width,
                            child: Center(
                              child: AspectRatio(
                                aspectRatio: handleRatio(),
                                child: Container(
                                  decoration: BoxDecoration(
                                    image: DecorationImage(
                                      fit: BoxFit.cover,
                                      image: FileImage(file!),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: TextButton.icon(
                            onPressed: () => clearImage(),
                            icon: const Icon(Icons.cancel_outlined,
                                color: Color.fromARGB(255, 89, 36, 99)),
                            label: const Text(
                              "Remove Image",
                              style: TextStyle(
                                color: Color.fromARGB(255, 89, 36, 99),
                                fontSize: 20.0,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Text("")
            ],
          ),
        ),
      ),
    );
  }

  bool get wantKeepAlive => true;

  @override
  Widget build(context) {
    super.build(context);

    return buildUploadForm();
  }
}
