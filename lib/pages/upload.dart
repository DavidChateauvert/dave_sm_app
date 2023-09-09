// ignore_for_file: prefer_const_constructors

import 'dart:io';

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
import 'package:image/image.dart' as Im;


class Upload extends StatefulWidget {
  final User? currentUser;

  Upload({ this.currentUser });

  @override
  _UploadState createState() => _UploadState();
}

class _UploadState extends State<Upload> with AutomaticKeepAliveClientMixin<Upload> {
  TextEditingController captionController = TextEditingController();
  FocusNode captionFocusNode = FocusNode();
  File? file;
  bool isUploading = false;
  String postId = Uuid().v4();
  final _postKey = GlobalKey<FormState>();
  Size size = Size(9, 12);


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
      }
    );
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
    });

  }

  Future<String> uploadImage(imageFile) async {
    UploadTask uploadTask = storageRef.child("post_$postId.jpg").putFile(imageFile);
    TaskSnapshot storageSnap = await uploadTask;
    String downloadUrl = await storageSnap.ref.getDownloadURL();
    return downloadUrl;
  }

  handleSubmit() async {
    if (captionController.text.isEmpty && file == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Post Cannot Be Empty"))
      );
    } else if (captionController.text.length > 250) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Post Is Too Long"))
      );
    } else {
      setState(() {
        isUploading = true;
      });
      if (file == null) {
        createPostInFirestore(caption: captionController.text, mediaUrl: '');
      } else {
        await compressImage();
        String mediaUrl = await uploadImage(file);
        createPostInFirestore(caption: captionController.text, mediaUrl: mediaUrl);
      }
      setState(() {
        file = null;
        isUploading = false;
        postId = Uuid().v4();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Post Successfully Created"))
      );
      captionController.clear();
      captionFocusNode.unfocus();
    }
    
  }

  handleRatio() {
    if ((size.width / size.height) < (9 / 12)) {
      return 9 / 12;
    }
    return size.width / size.height;
  }

  List<String> mentionSuggestions = ['allo', 'allo2'];

  // Controller for the @ mentions text field
  TextEditingController mentionController = TextEditingController();

  // Method to detect "@" symbol and show suggestions
  void onMentionTextChanged(String text) {
    if (text.isNotEmpty && text[text.length - 1] == '@') {
      // Show the suggestions (you can use a dropdown or overlay to display the options)
      showMentionSuggestionsOverlay();
    }
  }

  // Method to show the @ mention suggestions overlay
  void showMentionSuggestionsOverlay() {
    // You can use any approach to show the suggestions overlay, such as a dropdown or an overlay.
    // For simplicity, we will use a simple AlertDialog in this example.

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('@ Mention Suggestions'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: mentionSuggestions
                  .map((mention) => ListTile(
                        title: Text(mention),
                        onTap: () {
                          // Add the selected mention to the text field
                          addMention(mention);
                          Navigator.pop(context);
                        },
                      ))
                  .toList(),
            ),
          ),
        );
      },
    );
  }

  // Method to add the selected mention to the text field
  void addMention(String mention) {
    final currentText = mentionController.text;
    final cursorPosition = mentionController.selection.base.offset;
    final newText = currentText.replaceRange(cursorPosition, cursorPosition, '@$mention ');
    mentionController.text = newText;
    mentionController.selection = TextSelection.fromPosition(TextPosition(offset: cursorPosition + mention.length + 2));
  }


  buildUploadForm() {
    if (file != null) {
      final fileImage = FileImage(file!);
      size = ImageSizeGetter.getSize(FileInput(fileImage.file));
    }
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        leading: IconButton(
          icon: Icon(Icons.add_a_photo_outlined, color: Colors.white),
          onPressed: () => selectImage(context),
        ),
        title: GestureDetector(
          onTap: () => captionFocusNode.unfocus(),
          child: Text(
          "Caption Post",
          style: TextStyle(
            color: Colors.white,
            fontSize: 30.0
          ),
          ),
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
          Padding(padding: EdgeInsets.only(top: 10.0),
          ),
           ListTile(
            leading: CircleAvatar(
              backgroundImage: CachedNetworkImageProvider
              (widget.currentUser!.photoUrl),
            ),
            title: Container(
              width: 250.0,
              child: Form(
                key: _postKey,
                child : TextFormField(
                controller: captionController,
                focusNode: captionFocusNode,
                decoration: InputDecoration(
                  hintText: "Write a post...",
                  border: InputBorder.none,
                ),
                maxLines: null,
              ),
              ),
            ),
          ),
          (file != null) ? 
          Column(
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
    );
  }

  bool get wantKeepAlive => true;

  @override
  Widget build(context) {
    super.build(context);

    return buildUploadForm();
  }
}