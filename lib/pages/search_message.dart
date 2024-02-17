// ignore_for_file: prefer_const_constructors
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sm_app/pages/home.dart';
import 'package:sm_app/pages/message_screen.dart';
import 'package:sm_app/widgets/progress.dart';
import '../models/user.dart';

class SearchMessage extends StatefulWidget {
  @override
  _SearchMessageState createState() => _SearchMessageState();
}

class _SearchMessageState extends State<SearchMessage>
    with AutomaticKeepAliveClientMixin<SearchMessage> {
  TextEditingController searchController = TextEditingController();
  Future<QuerySnapshot>? searchResultsFuture;
  FocusNode searchFocusNode = FocusNode();
  List<String> allFriends = [];
  int friendBuilderCounter = 0;

  handleSearch(String query) {
    Future<QuerySnapshot> users =
        usersRef.where("displayNameLower", isGreaterThanOrEqualTo: query).get();

    setState(() {
      searchResultsFuture = users;
    });
  }

  handleEmptySearch() {
    Future<QuerySnapshot> users = usersRef.get();

    setState(() {
      searchResultsFuture = users;
    });
  }

  clearSearch() {
    setState(() {
      searchController.clear();
    });
    handleSearch(searchController.text);
    searchFocusNode.unfocus();
  }

  AppBar buildSearchField() {
    return AppBar(
      title: TextFormField(
        focusNode: searchFocusNode,
        controller: searchController,
        style: TextStyle(color: Colors.white),
        decoration: InputDecoration(
          prefixIconColor: Colors.white,
          suffixIconColor: Colors.white,
          filled: true,
          prefixIcon: Icon(
            Icons.account_box,
            size: 28.0,
          ),
          suffixIcon: IconButton(
            icon: Icon(Icons.clear),
            onPressed: () => clearSearch(),
          ),
          hintStyle: TextStyle(color: Colors.white),
        ),
        onChanged: handleSearch,
        onFieldSubmitted: handleSearch,
      ),
    );
  }

  buildNoContent() {
    handleEmptySearch();
    return FutureBuilder(
      future: searchResultsFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }
        List<UserResult> searchResults = [];
        // ignore: avoid_function_literals_in_foreach_calls
        snapshot.data?.docs.forEach((doc) {
          User user = User.fromDocument(doc);
          if (allFriends.contains(user.id)) {
            searchResults.add(UserResult(user));
          }
        });
        return ListView(
          children: searchResults,
        );
      },
    );
  }

  buildSearchResults() {
    return FutureBuilder(
      future: searchResultsFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }
        List<UserResult> searchResults = [];
        // ignore: avoid_function_literals_in_foreach_calls
        snapshot.data?.docs.forEach((doc) {
          User user = User.fromDocument(doc);
          if (allFriends.contains(user.id)) {
            searchResults.add(UserResult(user));
          }
        });
        return ListView(
          children: searchResults,
        );
      },
    );
  }

  bool get wantKeepAlive => true;

  getFriends() async {
    if (friendBuilderCounter < 1) {
      QuerySnapshot snapshot =
          await friendsRef.doc(currentUser.id).collection('userFriends').get();

      snapshot.docs.forEach((doc) {
        allFriends.add(doc.id);
      });
      friendBuilderCounter++;
    }
  }

  @override
  Widget build(context) {
    getFriends();
    super.build(context);

    return Scaffold(
      appBar: buildSearchField(),
      body:
          searchResultsFuture == null ? buildNoContent() : buildSearchResults(),
    );
  }
}

class UserResult extends StatelessWidget {
  final User user;

  UserResult(this.user);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
      child: Column(
        children: <Widget>[
          TextButton(
            onPressed: () => showMessageScreen(context, profileId: user.id),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.grey,
                backgroundImage: CachedNetworkImageProvider(user.photoUrl),
              ),
              title: Row(
                children: [
                  Text(
                    user.displayName,
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 4.0),
                  user.verified
                      ? Icon(
                          Icons.verified_sharp,
                          color: Theme.of(context).colorScheme.primary,
                          size: 17.0,
                        )
                      : Text(""),
                ],
              ),
            ),
          ),
          Divider(
            height: 2.0,
            color: Colors.white54,
          )
        ],
      ),
    );
  }
}

showMessageScreen(BuildContext context, {required String profileId}) {
  Navigator.pop(context);
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => MessageScreen(
        otherUserId: profileId,
        updateMessage: (newMessage) => null,
      ),
    ),
  );
}
