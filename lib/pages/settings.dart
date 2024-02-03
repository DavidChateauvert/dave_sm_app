import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sm_app/pages/aboutUs.dart';
import 'package:sm_app/pages/contactUs.dart';
import 'package:sm_app/pages/home.dart';
import 'package:sm_app/providers/notification_provider.dart';
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

  setThemeInFirestore() async {
    String currentTheme = Provider.of<ThemeProvider>(context, listen: false)
        .getThemeDataFormatString();
    await usersRef.doc(widget.currentUserId).update({
      "theme": currentTheme,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      key: _scaffoldKey,
      child: isLoading
          ? circularProgress()
          : ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                DrawerHeader(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  child: Text(
                    'Settings',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32.0,
                    ),
                  ),
                ),
                Container(
                  child: Column(
                    children: <Widget>[
                      const SizedBox(
                        height: 16.0,
                      ),
                      ListTile(
                          leading: Icon(
                            CupertinoIcons.brightness_solid,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                          title: Text(
                            "Change theme",
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.secondary,
                              fontSize: 20.0,
                            ),
                          ),
                          onTap: () {
                            Provider.of<ThemeProvider>(context, listen: false)
                                .toggleTheme();
                            setThemeInFirestore();
                          }),
                      const SizedBox(
                        height: 16.0,
                      ),
                      ListTile(
                        leading: Icon(CupertinoIcons.bell),
                        title: Text(
                          "Reset Notifications",
                          style: TextStyle(
                            fontSize: 20.0,
                          ),
                        ),
                        onTap: () => Provider.of<NotificationProvider>(context,
                                listen: false)
                            .resetNotificationCount(),
                      ),
                      const SizedBox(
                        height: 16.0,
                      ),
                      ListTile(
                        leading: Icon(CupertinoIcons.info),
                        title: Text(
                          "About us",
                          style: TextStyle(
                            fontSize: 20.0,
                          ),
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AboutUs(),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 16.0,
                      ),
                      ListTile(
                        leading: Icon(CupertinoIcons.envelope),
                        title: Text(
                          "Contact us",
                          style: TextStyle(
                            fontSize: 20.0,
                          ),
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ContactUs(),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 16.0,
                      ),
                      ListTile(
                        leading: Icon(Icons.cancel, color: Colors.red),
                        title: Text(
                          "Log out",
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 20.0,
                          ),
                        ),
                        onTap: () => logout(),
                      ),
                      const SizedBox(
                        height: 16.0,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
