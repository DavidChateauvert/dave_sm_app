// import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sm_app/api/firebase_api.dart';
import 'package:sm_app/pages/home.dart';
import 'package:sm_app/pages/search.dart';
import 'package:sm_app/widgets/message.dart';
import 'package:uuid/uuid.dart';
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
          return circularProgress();
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
    setState(() {
      file = File(xfile!.path);
      isCommentNotEmpty = true;
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
      isCommentNotEmpty = true;
    });
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
    return showDialog(
      context: parentContext,
      builder: (context) {
        return SimpleDialog(
          title: Align(
            alignment: Alignment.center,
            child: Text(
              AppLocalizations.of(context)!.send_image,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onBackground,
              ),
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
            return circularProgress();
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
                isUploading ? linearProgress() : Container(),
                Divider(),
                Column(
                  children: [
                    // Section for displaying selected images
                    file != null
                        ? Container(
                            height: 100,
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: FileImage(file!),
                              ),
                            ),
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
