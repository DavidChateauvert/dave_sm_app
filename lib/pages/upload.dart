// ignore_for_file: prefer_const_constructors
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_size_getter/file_input.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_size_getter/image_size_getter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sm_app/api/firebase_api.dart';
import 'package:sm_app/models/groups.dart';
import 'package:sm_app/pages/groups.dart';
import 'package:sm_app/pages/home.dart';
import 'package:sm_app/widgets/playVideo.dart';
import 'package:sm_app/widgets/progress.dart';
import 'package:status_alert/status_alert.dart';
import 'package:uuid/uuid.dart';
import 'package:sm_app/models/user.dart';
import 'package:flutter_mentions/flutter_mentions.dart';
import 'package:image/image.dart' as Im;
import 'package:video_player/video_player.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
  bool mediaIsLoading = false;
  String postId = Uuid().v4();
  GlobalKey<FlutterMentionsState> _mentionsKey =
      GlobalKey<FlutterMentionsState>();
  Size size = Size(9, 12);
  FocusNode captionFocusNode = FocusNode();
  List<Map<String, String>> mentionsDataInit = [];
  List<Map<String, String>> mentionsData = [];
  List<Map<String, String>> mentionsDataAdded = [];
  late String otherUserToken;
  String type = "text";
  late VideoPlayerController _controller;
  Group? group;

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
  }

  void showGroupsPage(BuildContext context) async {
    Group selectedGroup = await Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration:
            Duration(milliseconds: 500), // Adjust duration as needed
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
    setState(() {
      this.group = selectedGroup;
    });
  }

  handleTakePhoto() async {
    Navigator.pop(context);
    final ImagePicker _imagePicker = ImagePicker();
    XFile? xfile = (await _imagePicker.pickImage(
      source: ImageSource.camera,
      maxHeight: 960.0,
      maxWidth: 675.0,
    ));
    if (xfile != null) {
      setState(() {
        mediaIsLoading = true;
      });
      File compressImageFile = await compressImage(File(xfile.path));
      setState(() {
        type = "photo";
        file = compressImageFile;
        mediaIsLoading = false;
      });
    }
  }

  handleTakeVideoFunctions() async {
    await handleTakeVideo();
  }

  handleTakeVideo() async {
    Navigator.pop(context);
    XFile? xfile;
    String croppedPath = "";
    final ImagePicker _imagePicker = ImagePicker();
    xfile = await _imagePicker.pickVideo(
      source: ImageSource.camera,
      maxDuration: Duration(
        seconds: 10,
      ),
    );

    if (xfile != null) {
      setState(() {
        mediaIsLoading = true;
      });
      _controller = VideoPlayerController.file(File(xfile.path));
      await _controller.initialize();

      croppedPath = await cropVideo(File(xfile.path));

      setState(() {
        type = "video";
        file = File(croppedPath);
        mediaIsLoading = false;
      });
    }
  }

  handleChooseFromGalleryFunctions() async {
    await handleChooseFromGallery();
  }

  showModalVideoTooLong(parentContext) {
    return showDialog(
      context: parentContext,
      builder: (context) {
        return SimpleDialog(
          title: Center(
            child: Text(
              AppLocalizations.of(context)!.video_too_long,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primaryContainer,
              ),
            ),
          ),
          children: [
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                AppLocalizations.of(context)!.go_back_upload,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onBackground,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  handleChooseFromGallery() async {
    Navigator.pop(context);
    ImagePicker _imagePicker = ImagePicker();
    setState(() {
      mediaIsLoading = true;
    });
    XFile? xfile = (await _imagePicker.pickMedia(
      maxHeight: 675.0,
      maxWidth: 960,
    ));
    if (xfile != null) {
      String extension = xfile.path.split('.').last.toLowerCase();
      if (extension == 'mp4' || extension == 'mov' || extension == 'MOV') {
        _controller = VideoPlayerController.file(File(xfile.path));
        await _controller.initialize();

        if (_controller.value.duration.inSeconds > 10) {
          showModalVideoTooLong(context);
          setState(() {
            mediaIsLoading = false;
          });
        } else {
          String croppedPath = await cropVideo(File(xfile.path));

          setState(() {
            type = "video";
            file = File(croppedPath);
            mediaIsLoading = false;
          });
        }
      } else {
        File compressImageFile = await compressImage(File(xfile.path));
        setState(() {
          type = "photo";
          file = compressImageFile;
          mediaIsLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  videoPreviewWidget() {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.only(top: 30.0),
          child: PlayVideo(
            videoUrl: "",
            type: "upload",
            file: file,
            height: _controller.value.size.height.round(),
            width: _controller.value.size.width.round(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextButton.icon(
            onPressed: () => clearImage(),
            icon: const Icon(Icons.cancel_outlined,
                color: Color.fromARGB(255, 89, 36, 99)),
            label: const Text(
              "Remove Video",
              style: TextStyle(
                color: Color.fromARGB(255, 89, 36, 99),
                fontSize: 20.0,
              ),
            ),
          ),
        ),
      ],
    );
  }

  photoPreviewWidget() {
    return Column(
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(top: 30.0),
          child: Container(
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
    );
  }

  compressImage(File file) async {
    final tempDir = await getTemporaryDirectory();
    final path = tempDir.path;
    Im.Image? imageFile = Im.decodeImage(file.readAsBytesSync());
    final compressedImageFile = File('$path/img_${file.hashCode}.jpg')
      ..writeAsBytesSync(Im.encodeJpg(imageFile!, quality: 85));
    return compressedImageFile;
  }

  String getOutputPath(String filePath) {
    final fileName = filePath.split('/').last;
    final fileNameWithoutExtension = fileName.split('.').first;
    final fileExtension = fileName.split('.').last;

    final newFileName = '$fileNameWithoutExtension-cropped.$fileExtension';
    final directoryPath = filePath.substring(0, filePath.lastIndexOf('/'));

    return '$directoryPath/$newFileName';
  }

  Future<String> cropVideo(File file) async {
    String outputPath = getOutputPath(file.path);

    final int maxHeight = 1440;

    try {
      final int originalWidth = _controller.value.size.width.round();
      final int originalHeight = _controller.value.size.height.round();

      final int cropHeight =
          originalHeight > maxHeight ? maxHeight : originalHeight;
      final int topPadding = (originalHeight - cropHeight) ~/ 2;

      final String command =
          '-i ${file.path} -vf crop=$originalWidth:$cropHeight:0:$topPadding -c:a copy $outputPath';

      await FFmpegKit.execute(command);
      return outputPath;
    } catch (e) {
      print("Cropped video failed : $e");
      return "";
    }
  }

  selectImage(parentContext) {
    const width = 150.0;
    const height = 100.0;
    return showDialog(
      context: parentContext,
      builder: (context) {
        return SimpleDialog(
          title: Center(
            child: Text(
              AppLocalizations.of(context)!.add_media_to_post,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onBackground,
              ),
            ),
          ),
          children: <Widget>[
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Flexible(
                      child: TextButton(
                        onPressed: () => handleTakePhotoFunctions(),
                        child: Container(
                          width: width,
                          height: height,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(
                                  CupertinoIcons.photo_camera,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onBackground,
                                  size: 28.0,
                                ),
                                const SizedBox(
                                  height: 8,
                                ),
                                Text(
                                  AppLocalizations.of(context)!
                                      .photo_with_camera,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onBackground,
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
                        onPressed: () => handleTakeVideoFunctions(),
                        child: Container(
                          width: width,
                          height: height,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.videocam_outlined,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onBackground,
                                  size: 28.0,
                                ),
                                const SizedBox(
                                  height: 8,
                                ),
                                Text(
                                  AppLocalizations.of(context)!
                                      .video_with_camera,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onBackground,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 2.0,
                      width: 275.0,
                      color: Theme.of(context).colorScheme.onBackground,
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Flexible(
                      child: TextButton(
                        onPressed: () => handleChooseFromGalleryFunctions(),
                        child: Container(
                          width: 2 * width,
                          height: height,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(
                                CupertinoIcons.photo_on_rectangle,
                                color:
                                    Theme.of(context).colorScheme.onBackground,
                                size: 28.0,
                              ),
                              const SizedBox(
                                height: 8,
                              ),
                              Text(
                                AppLocalizations.of(context)!
                                    .photo_or_video_with_camera,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onBackground,
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
            ),
          ],
        );
      },
    );
  }

  clearImage() {
    setState(() {
      file = null;
      type = "text";
    });
  }

  Map<String, String> getOrderedMentionsMap(
      Map<String, String> mentionsMap, String caption) {
    mentionsMap.removeWhere((key, value) => !caption.contains('@$value'));

    Map<String, String> orderedMentionsMap = {};

    List<String> words = caption.split(' ');

    for (int i = 0; i < words.length; i++) {
      if (words[i].startsWith('@')) {
        String mentionKey;
        if (words[i] != "All" && words[i] != "Tous") {
          mentionKey = words[i].substring(1) + " " + words[i + 1];
        } else {
          mentionKey = words[i].substring(1).trim();
        }

        for (MapEntry<String, String> entry in mentionsMap.entries) {
          if (mentionKey.trim() == entry.value) {
            orderedMentionsMap[entry.key] = entry.value;
            break;
          }
        }
      }
    }

    return orderedMentionsMap;
  }

  createPostInFirestore(
      {required String caption,
      required String type,
      required String mediaUrl}) {
    Map<String, String> mentionsMap =
        mentionsDataAdded.fold({}, (map, mention) {
      map[mention['id']!] = mention['display']!;
      return map;
    });

    Map<String, String> mentionsMapFiltered =
        getOrderedMentionsMap(mentionsMap, caption);

    if (type == "video") {
      int heightVideo = _controller.value.size.height.round() > 1440
          ? 1440
          : _controller.value.size.height.round();

      size = Size(
        _controller.value.size.width.round(),
        heightVideo,
      );
    }

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
      "mentions": mentionsMapFiltered,
      "type": type,
    });

    usersRef.doc(currentUser.id).update({
      "postsCount": FieldValue.increment(1),
    });

    if (mentionsMap.containsKey("all")) {
      Map<String, String> mentionsMapAllFriends =
          mentionsDataInit.fold({}, (map, mention) {
        map[mention['id']!] = mention['display']!;
        return map;
      });
      for (var mention in mentionsMapAllFriends.entries) {
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
            context, mention.key, currentUser.displayName, postId);
      }
    } else {
      for (var mention in mentionsMapFiltered.entries) {
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
            context, mention.key, currentUser.displayName, postId);
      }
    }
  }

  Future<String> uploadImage(File? imageFile) async {
    UploadTask uploadTask = storageRef
        .child("/photo/${DateTime.now()}_$postId.jpg")
        .putFile(imageFile!);
    TaskSnapshot storageSnap = await uploadTask;
    String downloadUrl = await storageSnap.ref.getDownloadURL();
    return downloadUrl;
  }

  Future<String> uploadVideo(File? videoFile) async {
    UploadTask uploadTask = storageRef
        .child("/video/${DateTime.now()}_$postId.mp4")
        .putFile(videoFile!);
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
            caption: _mentionsKey.currentState!.controller!.text,
            type: "text",
            mediaUrl: '');
      } else {
        String mediaUrl;
        if (type == "photo") {
          mediaUrl = await uploadImage(file);
        } else {
          mediaUrl = await uploadVideo(file);
        }
        createPostInFirestore(
            caption: _mentionsKey.currentState!.controller!.text,
            type: type,
            mediaUrl: mediaUrl);
      }

      setState(() {
        file = null;
        isUploading = false;
        postId = Uuid().v4();
        type = "text";
      });

      _mentionsKey.currentState!.controller!.clear();
      mentionsDataAdded.clear();
      StatusAlert.show(
        context,
        duration: Duration(seconds: 2),
        subtitle: AppLocalizations.of(context)!.post_success,
        configuration: IconConfiguration(icon: Icons.done),
        maxWidth: 260,
        backgroundColor: Theme.of(context).colorScheme.secondary,
      );
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

    filteredData.insert(
        0, {'id': 'all', 'display': AppLocalizations.of(context)!.all_friends});

    setState(() {
      mentionsData = filteredData;
    });
  }

  buildGroupTile() {
    return ListTile(
      title: RichText(
        overflow: TextOverflow.ellipsis,
        text: TextSpan(
          style: TextStyle(
            fontSize: 20.0,
            color: Theme.of(context).colorScheme.onBackground,
          ),
          children: [
            TextSpan(
              text: "To : ",
              style: const TextStyle(fontWeight: FontWeight.normal),
            ),
            TextSpan(
              text: '${group?.name}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      trailing: IconButton(
        onPressed: () {
          setState(() {
            group = null;
          });
        },
        icon: Icon(
          Icons.clear,
          color: Theme.of(context).colorScheme.onBackground,
          size: 24,
        ),
      ),
    );
  }

  buildUploadForm() {
    if (file != null && type == "photo") {
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
                size: 32.0,
              ),
              onPressed: () => selectImage(context),
            ),
            title: Text(
              AppLocalizations.of(context)!.make_a_post,
              style: TextStyle(color: Colors.white, fontSize: 30.0),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: Icon(
                  CupertinoIcons.group_solid,
                  color: Colors.white,
                  size: 40.0,
                ),
                onPressed: () => showGroupsPage(context),
              ),
              const SizedBox(
                width: 32,
              ),
              IconButton(
                onPressed: isUploading ? null : () => handleSubmit(),
                icon: Icon(
                  Icons.send_outlined,
                  size: 30.0,
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
              group != null
                  ? Divider(
                      thickness: 0.5,
                      color: Theme.of(context).colorScheme.secondary,
                    )
                  : Container(),
              group != null ? buildGroupTile() : Container(),
              group != null
                  ? Divider(
                      thickness: 0.5,
                      color: Theme.of(context).colorScheme.secondary,
                    )
                  : Container(),
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
                      hintText: AppLocalizations.of(context)!.write_a_post,
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
              mediaIsLoading
                  ? Container(
                      height: 325,
                      child: Center(
                        child: circularProgress(),
                      ),
                    )
                  : (file != null && type == "photo")
                      ? photoPreviewWidget()
                      : (file != null && type == "video")
                          ? videoPreviewWidget()
                          : Text(""),
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
