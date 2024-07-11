// ignore_for_file: prefer_const_constructors

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:sm_app/pages/home.dart';
import 'package:sm_app/pages/profile.dart';
import 'package:sm_app/providers/theme_provider.dart';
import 'package:sm_app/widgets/progress.dart';
import '../models/user.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class Search extends StatefulWidget {
  @override
  _SearchState createState() => _SearchState();
}

class _SearchState extends State<Search>
    with AutomaticKeepAliveClientMixin<Search> {
  TextEditingController searchController = TextEditingController();
  Future<QuerySnapshot>? searchResultsFuture;
  FocusNode searchFocusNode = FocusNode();

  handleSearch(String query) async {
    // Quand tu seras prêt
    // if (query == "") {
    //   clearSearch();
    // } else {
    String lowercasedQuery = query.toLowerCase();
    QuerySnapshot users = await usersRef
        .orderBy("displayNameLower")
        .startAt([lowercasedQuery]).endAt([lowercasedQuery + '\uf8ff']).get();

    setState(() {
      searchResultsFuture = Future.value(users);
    });
    // }
  }

  clearSearch() {
    searchFocusNode.unfocus();
    setState(() {
      searchController.clear();
      searchResultsFuture = null;
    });
  }

  AppBar buildSearchField() {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.primary,
      title: TextFormField(
        focusNode: searchFocusNode,
        controller: searchController,
        style: TextStyle(color: Colors.white),
        decoration: InputDecoration(
          prefixIconColor: Colors.white,
          suffixIconColor: Colors.white,
          filled: true,
          fillColor: Color.fromARGB(255, 152, 63, 170),
          prefixIcon: Icon(
            Icons.account_box,
            size: 28.0,
          ),
          suffixIcon: IconButton(
            icon: Icon(Icons.clear),
            onPressed: () => clearSearch(),
          ),
          hintStyle: TextStyle(color: Colors.white),
          hintText: AppLocalizations.of(context)!.search_user,
        ),
        onChanged: (query) => handleSearch(query),
        onFieldSubmitted: (query) => handleSearch(query),
      ),
    );
  }

  Container buildNoContent() {
    return Container(
      color: Theme.of(context).colorScheme.background,
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              SvgPicture.asset(
                Provider.of<ThemeProvider>(context).themeData.brightness ==
                        Brightness.light
                    ? 'assets/images/advanced_search.svg'
                    : 'assets/images/advanced_search_white.svg',
                height: 250.0,
              ),
              SizedBox(height: 16.0), // Add spacing if needed
              Text(
                AppLocalizations.of(context)!.find_users,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  fontStyle: FontStyle.normal,
                  fontWeight: FontWeight.w600,
                  fontSize: 40.0,
                ),
              ),
            ],
          ),
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
        var currentUserId = currentUser.id;
        // ignore: avoid_function_literals_in_foreach_calls
        snapshot.data?.docs.forEach((doc) {
          User user = User.fromDocument(doc);
          if (user.id != currentUserId) searchResults.add(UserResult(user));
        });
        return ListView(
          children: searchResults,
        );
      },
    );
  }

  bool get wantKeepAlive => false;

  @override
  Widget build(context) {
    super.build(context);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
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
            onPressed: () => showProfile(context, profileId: user.id),
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
                          color: Theme.of(context).colorScheme.primaryContainer,
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

showProfile(BuildContext context, {required String profileId}) {
  // ignore: unnecessary_null_comparison
  if (currentUser != null && profileId != currentUser.id) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Profile(profileId: profileId),
      ),
    );
  }
}
