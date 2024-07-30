// import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_size_getter/file_input.dart';
import 'package:image_size_getter/image_size_getter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sm_app/api/firebase_api.dart';
import 'package:sm_app/pages/home.dart';
import 'package:sm_app/pages/search.dart';
import 'package:sm_app/pages/upload.dart';
import 'package:sm_app/widgets/message.dart';
import 'package:sm_app/widgets/playVideo.dart';
import 'package:uuid/uuid.dart';
import 'package:video_player/video_player.dart';
import '../models/user.dart';
import '../widgets/progress.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
// ignore: depend_on_referenced_packages
import 'package:image/image.dart' as Im;

class MessageScreen extends StatefulWidget {
  late final String otherUserId;
  late final Function(String) updateMessage;

  MessageScreen({
    required this.otherUserId,
    required this.updateMessage,
  });

  @override
  MessageScreeState createState() => MessageScreeState(
        otherUserId: otherUserId,
        updateMessage: updateMessage,
      );
}

class MessageScreeState extends State<MessageScreen> {
  String messageId = Uuid().v4();
  File? file;
  bool isUploading = false;
  TextEditingController messageController = TextEditingController();
  FocusNode messageFocusNode = FocusNode();
  final String currentUserId = currentUser.id;
  late String otherUserToken;
  late User otherUser;
  late final String otherUserId;
  late final Function(String) updateMessage;
  bool isCommentNotEmpty = false;
  bool isFocused = false;
  bool mediaIsLoading = false;
  late VideoPlayerController _controller;
  String type = "text";
  Size size = Size(9, 12);

  @override
  void initState() {
    super.initState();
    messageFocusNode.addListener(() {
      setState(() {
        isFocused = messageFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    messageFocusNode.dispose();
    super.dispose();
  }

  MessageScreeState({
    required this.otherUserId,
    required this.updateMessage,
  });

  buildMessages() {
    return StreamBuilder(
      stream: messagesRef
          .doc(currentUserId)
          .collection('and')
          .doc(widget.otherUserId)
          .collection("message")
          .orderBy("timestamp", descending: true)
          .limit(10)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress(context);
        }
        List<Message> messages = [];
        snapshot.data?.docs.forEach((doc) {
          messages.add(Message.fromDocument(doc));
        });

        return GestureDetector(
          onTap: () => messageFocusNode.unfocus(),
          onVerticalDragDown: (DragDownDetails details) =>
              messageFocusNode.unfocus(),
          child: ListView(
            reverse: true,
            children: messages,
            physics: NeverScrollableScrollPhysics(),
          ),
        );
      },
    );
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
    if (xfile != null) {
      File newFile = File(xfile.path);
      setState(() {
        type = "photo";
        file = newFile;
        size = ImageSizeGetter.getSize(FileInput(newFile));
        isCommentNotEmpty = true;
      });
    }
  }

  handleChooseFromGalleryFunctions() async {
    await handleChooseFromGallery();
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
          String croppedPath = await cropVideo(File(xfile.path), _controller);

          setState(() {
            type = "video";
            file = File(croppedPath);
            mediaIsLoading = false;
          });
        }
      } else {
        File newFile = File(xfile.path);
        setState(() {
          type = "photo";
          file = newFile;
          size = ImageSizeGetter.getSize(FileInput(newFile));
          isCommentNotEmpty = true;
          mediaIsLoading = false;
        });
        await compressImage();
      }
      setState(() {
        isCommentNotEmpty = true;
      });
    } else {
      setState(() {
        mediaIsLoading = false;
      });
    }
  }

  compressImage() async {
    final tempDir = await getTemporaryDirectory();
    final path = tempDir.path;
    Im.Image? imageFile = Im.decodeImage(file!.readAsBytesSync());
    final compressedImageFile = File('$path/img_$messageId.jpg')
      ..writeAsBytesSync(Im.encodeJpg(imageFile!, quality: 85));
    setState(() {
      file = compressedImageFile;
      isCommentNotEmpty = true;
    });
    messageFocusNode.unfocus();
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

      croppedPath = await cropVideo(File(xfile.path), _controller);

      setState(() {
        type = "video";
        file = File(croppedPath);
        mediaIsLoading = false;
        isCommentNotEmpty = true;
      });
    }
  }

  String determineNotificationMessage(String messageTrim, File? file) {
    if (messageTrim.isNotEmpty && file != null) {
      return AppLocalizations.of(context)!.message_with_photo(messageTrim);
    } else if (messageTrim.isEmpty && file != null) {
      return AppLocalizations.of(context)!.message_only_photo;
    } else {
      return messageTrim;
    }
  }

  String determineMessage(String messageTrim, File? file) {
    if (messageTrim.isEmpty && file != null) {
      return "";
    } else {
      return messageTrim;
    }
  }

  addMessageInFirestore() async {
    DateTime timestamp = DateTime.now();

    String messageTrim = messageController.text.trim();

    if (messageTrim.isNotEmpty || file != null) {
      String mediaUrl = "";
      if (file != null) {
        setState(() {
          isUploading = true;
        });
        messageFocusNode.unfocus();
        mediaUrl = await uploadImage(file);
      }
      String actualMessage = determineMessage(messageTrim, file);
      String notificationMessage =
          determineNotificationMessage(messageTrim, file);
      updateMessage(notificationMessage);

      if (type == "video") {
        int heightVideo = _controller.value.size.height.round() > 1440
            ? 1440
            : _controller.value.size.height.round();

        size = Size(
          _controller.value.size.width.round(),
          heightVideo,
        );
      }

      messagesRef
          .doc(currentUserId)
          .collection("and")
          .doc(widget.otherUserId)
          .collection('message')
          .add({
        "username": currentUser.username,
        "message": actualMessage,
        "timestamp": timestamp,
        "avatarUrl": currentUser.photoUrl,
        "userId": currentUser.id,
        "otherUserId": widget.otherUserId,
        "mediaUrl": mediaUrl,
        "type": type,
        "mediaUrlWidth": size.width,
        "mediaUrlHeight": size.height,
      });

      messagesRef
          .doc(widget.otherUserId)
          .collection("and")
          .doc(currentUserId)
          .collection("message")
          .add({
        "username": currentUser.username,
        "message": actualMessage,
        "timestamp": timestamp,
        "avatarUrl": currentUser.photoUrl,
        "userId": currentUser.id,
        "otherUserId": widget.otherUserId,
        "mediaUrl": mediaUrl,
        "type": type,
      });

      await addNotificationMessageFeed();
      FirebaseApi().sendMessageNotification(context, widget.otherUserId,
          notificationMessage, currentUser.displayName);
    }

    messageController.clear();

    clearImage();
    setState(() {
      isUploading = false;
    });
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

  Future<String> uploadImage(imageFile) async {
    UploadTask uploadTask =
        storageRef.child("post_$messageId.jpg").putFile(imageFile);
    TaskSnapshot storageSnap = await uploadTask;
    String downloadUrl = await storageSnap.ref.getDownloadURL();
    return downloadUrl;
  }

  clearImage() {
    setState(() {
      file = null;
      if (messageController.text.trim().isEmpty) {
        isCommentNotEmpty = false;
      }
    });
  }

  addNotificationMessageFeed() async {
    String actualMessage =
        determineNotificationMessage(messageController.text.trim(), file);
    try {
      await messagesRef
          .doc(widget.otherUserId)
          .collection("and")
          .doc(currentUserId)
          .get()
          .then((doc) {
        if (doc.exists) {
          doc.reference.update({
            "lastUserSent": currentUserId,
            "message": actualMessage,
            "seen": false,
            "timestamp": DateTime.now(),
          });
        } else {
          doc.reference.set({
            "message": actualMessage,
            "username": currentUser.firstName,
            "userId": currentUserId,
            "lastUserSent": currentUserId,
            "userProfileImg": currentUser.photoUrl,
            "seen": false,
            "timestamp": DateTime.now(),
          });
        }
      });
      await messagesRef
          .doc(currentUserId)
          .collection("and")
          .doc(widget.otherUserId)
          .get()
          .then((doc) {
        if (doc.exists) {
          doc.reference.update({
            "lastUserSent": currentUserId,
            "message": actualMessage,
            "seen": true,
            "timestamp": DateTime.now(),
          });
        } else {
          doc.reference.set({
            "message": actualMessage,
            "username": otherUser.firstName,
            "userId": widget.otherUserId,
            "lastUserSent": currentUserId,
            "userProfileImg": otherUser.photoUrl,
            "seen": true,
            "timestamp": DateTime.now(),
          });
        }
      });
    } catch (e) {
      print("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: usersRef.doc(widget.otherUserId).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return circularProgress(context);
          }
          otherUser =
              User.fromDocument(snapshot.data as DocumentSnapshot<Object?>);
          return Scaffold(
            appBar: AppBar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              title: GestureDetector(
                onTap: () => showProfile(context, profileId: otherUser.id),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundImage:
                          CachedNetworkImageProvider(otherUser.photoUrl),
                    ),
                    SizedBox(width: 8.0),
                    Text(otherUser.displayName),
                    SizedBox(width: 8.0),
                    otherUser.verified
                        ? Icon(
                            Icons.verified_sharp,
                            color: Colors.white,
                            size: 17.0,
                          )
                        : Text(""),
                  ],
                ),
              ),
              centerTitle: true,
            ),
            body: Column(
              children: <Widget>[
                Expanded(child: buildMessages()),
                isUploading ? linearProgress(context) : Container(),
                Divider(),
                Column(
                  children: [
                    mediaIsLoading == true
                        ? circularProgress(context)
                        : file != null
                            ? type == "video"
                                ? Column(
                                    children: [
                                      Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 8.0,
                                        ),
                                        child: Column(
                                          children: [
                                            PlayVideo(
                                              videoUrl: "",
                                              type: "uploadMessage",
                                              file: file,
                                              height: _controller
                                                  .value.size.height
                                                  .round(),
                                              width: _controller
                                                  .value.size.width
                                                  .round(),
                                            ),
                                          ],
                                        ),
                                      ),
                                      GestureDetector(
                                        child: Icon(
                                          Icons.cancel_outlined,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                        ),
                                        onTap: () => clearImage(),
                                      ),
                                    ],
                                  )
                                : Column(
                                    children: [
                                      Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 8.0,
                                        ),
                                        child: Container(
                                          height: 100,
                                          decoration: BoxDecoration(
                                            image: DecorationImage(
                                              image: FileImage(file!),
                                            ),
                                          ),
                                        ),
                                      ),
                                      GestureDetector(
                                        child: Icon(
                                          Icons.cancel_outlined,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                        ),
                                        onTap: () => clearImage(),
                                      ),
                                    ],
                                  )
                            : Container(),
                    // Text input for the message
                    ListTile(
                      title: TextFormField(
                        controller: messageController,
                        focusNode: messageFocusNode,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!
                              .message_controller_placeholder,
                          border: isFocused
                              ? UnderlineInputBorder()
                              : InputBorder.none,
                        ),
                        maxLines: null,
                        onChanged: (value) {
                          setState(() {
                            isCommentNotEmpty = value.trim().isNotEmpty;
                          });
                        },
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () => selectImage(context),
                            icon: Icon(
                              Icons.camera_alt,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          IconButton(
                            onPressed: () => addMessageInFirestore(),
                            icon: Icon(
                              Icons.send_outlined,
                              color: isCommentNotEmpty
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 16.0,
                    ),
                  ],
                ),
              ],
            ),
          );
        });
  }
}
