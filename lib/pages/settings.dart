import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sm_app/pages/aboutUs.dart';
import 'package:sm_app/pages/contactUs.dart';
import 'package:sm_app/pages/home.dart';
import 'package:sm_app/providers/theme_provider.dart';
import 'package:sm_app/widgets/progress.dart';

class SettingsPage extends StatefulWidget {
  final String currentUserId;

  SettingsPage({required this.currentUserId});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
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
    // Navigator.push(context, MaterialPageRoute(builder: (context) => Home()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: const Text(
          "Settings",
          style: const TextStyle(color: Colors.white, fontSize: 30.0),
        ),
      ),
      body: isLoading
          ? circularProgress()
          : ListView(
              children: <Widget>[
                Container(
                  child: Column(
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(top: 64.0),
                        child: TextButton.icon(
                          onPressed: () =>
                              Provider.of<ThemeProvider>(context, listen: false)
                                  .toggleTheme(),
                          icon: Icon(CupertinoIcons.brightness_solid,
                              color: Theme.of(context).colorScheme.secondary),
                          label: Text(
                            "Change theme",
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.secondary,
                              fontSize: 20.0,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 64.0),
                        child: TextButton.icon(
                          onPressed: () => logout(),
                          icon: const Icon(Icons.cancel, color: Colors.red),
                          label: const Text(
                            "Log out",
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 20.0,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 64.0),
                        child: TextButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AboutUs(),
                            ),
                          ),
                          icon: Icon(
                            CupertinoIcons.info,
                          ),
                          label: Text(
                            "About us",
                            style: TextStyle(
                              fontSize: 20.0,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 64.0),
                        child: TextButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ContactUs(),
                            ),
                          ),
                          icon: const Icon(
                            CupertinoIcons.envelope,
                          ),
                          label: const Text(
                            "Contact us",
                            style: TextStyle(
                              fontSize: 20.0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
