// ignore_for_file: prefer_const_constructors

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_size_getter/image_size_getter.dart';
import 'package:image_size_getter/file_input.dart';
// import 'package:textfield_tags/textfield_tags.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
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
  TextEditingController searchController = TextEditingController();
  Future<QuerySnapshot>? searchResultsFuture;
  List<Map<String, String>> mentionsData = [];
  List<Map<String, String>> mentionsDataAdded = [];

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

  selectImage(parentContext) {
    return showDialog(
        context: parentContext,
        builder: (context) {
          return SimpleDialog(
            title: Text("Create Post"),
            children: <Widget>[
              SimpleDialogOption(
                onPressed: () => handleTakePhoto(),
                child: Text("Photo with camera"),
              ),
              SimpleDialogOption(
                onPressed: () => handleChooseFromGallery(),
                child: Text("Image from Gallery"),
              ),
              SimpleDialogOption(
                child: Text("Cancel"),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          );
        });
  }

  clearImage() {
    setState(() {
      file = null;
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
      "username": widget.currentUser?.username,
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
  }

  Future<String> uploadImage(imageFile) async {
    UploadTask uploadTask =
        storageRef.child("post_$postId.jpg").putFile(imageFile);
    TaskSnapshot storageSnap = await uploadTask;
    String downloadUrl = await storageSnap.ref.getDownloadURL();
    return downloadUrl;
  }

  handleSubmit() async {
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
        await compressImage();
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
    // QuerySnapshot friendsId =
    //     await friendsRef.doc(currentUser.id).collection("userFriends").get();

    // List<String> userIds = [];

    // friendsId.docs.forEach((doc) {
    //   userIds.add(doc.id);
    // });
    // print(userIds);

    String lowercasedQuery = query.toLowerCase();
    QuerySnapshot users = await usersRef
        //.where('id', whereIn: userIds)
        .orderBy("displayNameLower")
        .startAt([lowercasedQuery]).endAt([lowercasedQuery + '\uf8ff']).get();

    List<Map<String, String>> newData = [];

    // Process QuerySnapshot and populate newData with the required data format
    for (QueryDocumentSnapshot user in users.docs) {
      newData.add({
        'id': user.get('id'),
        'display': user.get('displayName'),
      });
    }

    setState(() {
      mentionsData = newData;
    });
  }

  clearSearch() {
    setState(() {
      searchController.clear();
    });
    handleSearch(searchController.text);
  }

  buildSearchField() {
    return TextFormField(
      controller: searchController,
      style: TextStyle(color: Colors.black),
      decoration: InputDecoration(
        prefixIconColor: Colors.purple,
        suffixIconColor: Colors.purple,
        filled: true,
        prefixIcon: Icon(
          Icons.account_box,
          size: 28.0,
        ),
        suffixIcon: IconButton(
          icon: Icon(Icons.clear),
          onPressed: () => clearSearch(),
        ),
        hintStyle: TextStyle(color: Colors.black),
      ),
      onChanged: (query) => handleSearch(query),
      onFieldSubmitted: (query) => handleSearch(query),
    );
  }

  buildUploadForm() {
    if (file != null) {
      final fileImage = FileImage(file!);
      size = ImageSizeGetter.getSize(FileInput(fileImage.file));
    }
    return Portal(
      child: MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            backgroundColor: Theme.of(context).primaryColor,
            leading: IconButton(
              icon: Icon(Icons.add_a_photo_outlined, color: Colors.white),
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
                    fontSize: 20.0,
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
                    key: _mentionsKey,
                    decoration: InputDecoration(
                      hintText: "Write a post...",
                      border: InputBorder.none,
                    ),
                    suggestionListHeight: 200,
                    suggestionListDecoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(7.0),
                    ),
                    mentions: [
                      Mention(
                        trigger: '@',
                        disableMarkup: false,
                        style: TextStyle(
                          color: Colors.purple,
                        ),
                        data: mentionsData,
                        matchAll: false,
                        suggestionBuilder: (data) {
                          return Container(
                            decoration: BoxDecoration(
                                color:
                                    const Color.fromARGB(255, 209, 209, 209)),
                            height: 50.0,
                            width: 100.0,
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: EdgeInsets.only(left: 10.0),
                              child: Text(data['display']!),
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
