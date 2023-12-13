// ignore_for_file: prefer_const_constructors

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:sm_app/pages/home.dart';
import 'package:sm_app/pages/profile.dart';
import 'package:sm_app/widgets/progress.dart';
import '../models/user.dart';

class Search extends StatefulWidget {
  @override
  _SearchState createState() => _SearchState();
}

class _SearchState extends State<Search>
    with AutomaticKeepAliveClientMixin<Search> {
  TextEditingController searchController = TextEditingController();
  Future<QuerySnapshot>? searchResultsFuture;

  handleSearch(String query) async {
    String lowercasedQuery = query.toLowerCase();
    QuerySnapshot users = await usersRef
        .orderBy("displayNameLower")
        .startAt([lowercasedQuery]).endAt([lowercasedQuery + '\uf8ff']).get();

    setState(() {
      searchResultsFuture = Future.value(users);
    });
  }

  clearSearch() {
    setState(() {
      searchController.clear();
    });
    handleSearch(searchController.text);
  }

  AppBar buildSearchField() {
    return AppBar(
      backgroundColor: Theme.of(context).primaryColor,
      title: TextFormField(
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
        onChanged: (query) => handleSearch(query),
        onFieldSubmitted: (query) => handleSearch(query),
      ),
    );
  }

  Container buildNoContent() {
    final Orientation orientation = MediaQuery.of(context).orientation;
    return Container(
      child: Center(
        child: ListView(
          shrinkWrap: true,
          children: <Widget>[
            SvgPicture.asset('assets/images/advanced_search.svg',
                height: orientation == Orientation.portrait ? 300.0 : 200.0),
            Text(
              "Find Users",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black,
                fontStyle: FontStyle.normal,
                fontWeight: FontWeight.w600,
                fontSize: 60.0,
              ),
            ),
          ],
        ),
      ),
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
          searchResults.add(UserResult(user));
        });
        return ListView(
          children: searchResults,
        );
      },
    );
  }

  bool get wantKeepAlive => true;

  @override
  Widget build(context) {
    super.build(context);

    return Scaffold(
      backgroundColor: Color.fromARGB(255, 244, 186, 184),
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
      color: Theme.of(context).primaryColor.withOpacity(0.7),
      child: Column(
        children: <Widget>[
          GestureDetector(
            onTap: () => showProfile(context, profileId: user.id),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.grey,
                backgroundImage: CachedNetworkImageProvider(user.photoUrl),
              ),
              title: Row(
                children: [
                  Text(
                    user.username,
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 4.0),
                  user.verified
                      ? Icon(
                          Icons.verified_sharp,
                          color: Theme.of(context).primaryColor,
                          size: 17.0,
                        )
                      : Text(""),
                ],
              ),
              subtitle: Text(
                user.displayName,
                style: TextStyle(color: Colors.white),
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

showProfile(BuildContext context, {required String profileId}) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => Profile(profileId: profileId),
    ),
  );
}
